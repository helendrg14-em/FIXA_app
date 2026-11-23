package com.fixa.fixa

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

internal class ComprobanteAndroid(private val actividad: Activity) {
    private data class Exportacion(val png: ByteArray, val resultado: MethodChannel.Result)

    private var pendiente: Exportacion? = null

    fun atender(llamada: MethodCall, resultado: MethodChannel.Result) {
        when (llamada.method) {
            "guardarImagen" -> {
                val nombre = llamada.argument<String>("nombre")
                val bytes = llamada.argument<ByteArray>("bytes")
                if (nombre == null || bytes == null) {
                    resultado.error("ARGUMENTOS", "Faltan los datos del comprobante.", null)
                } else {
                    guardarImagen(nombre, bytes, resultado)
                }
            }
            "abrirCorreo" -> abrirCorreo(
                llamada.argument<String>("asunto").orEmpty(),
                llamada.argument<String>("texto").orEmpty(),
                resultado
            )
            else -> resultado.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    private fun guardarImagen(nombre: String, bytes: ByteArray, resultado: MethodChannel.Result) {
        if (pendiente != null) {
            resultado.error("OCUPADO", "Ya hay un comprobante por guardar.", null)
            return
        }
        val accion = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/png"
            putExtra(Intent.EXTRA_TITLE, nombre)
        }
        try {
            pendiente = Exportacion(bytes, resultado)
            actividad.startActivityForResult(accion, CODIGO_EXPORTAR)
        } catch (_: ActivityNotFoundException) {
            pendiente = null
            resultado.error("SIN_ARCHIVOS", "No hay un selector de archivos disponible.", null)
        }
    }

    fun recibir(codigo: Int, estado: Int, destino: Uri?) {
        if (codigo != CODIGO_EXPORTAR) return
        val exportacion = pendiente ?: return
        pendiente = null
        if (estado != Activity.RESULT_OK || destino == null) {
            exportacion.resultado.success(false)
            return
        }
        try {
            val archivo = actividad.contentResolver.openOutputStream(destino)
                ?: throw IOException("El proveedor no abrió el archivo")
            archivo.use { it.write(exportacion.png) }
            exportacion.resultado.success(true)
        } catch (_: IOException) {
            exportacion.resultado.error("ERROR_ARCHIVO", "No se pudo guardar el comprobante.", null)
        } catch (_: SecurityException) {
            exportacion.resultado.error("ERROR_PERMISO", "No se pudo escribir en la ubicación elegida.", null)
        }
    }

    private fun abrirCorreo(asunto: String, texto: String, resultado: MethodChannel.Result) {
        val accion = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:")).apply {
            putExtra(Intent.EXTRA_SUBJECT, asunto)
            putExtra(Intent.EXTRA_TEXT, texto)
        }
        try {
            actividad.startActivity(accion)
            resultado.success(null)
        } catch (_: ActivityNotFoundException) {
            resultado.error("SIN_CORREO", "No hay una aplicación de correo disponible.", null)
        }
    }

    private companion object {
        const val CODIGO_EXPORTAR = 610
    }
}
