package com.fixa.fixa

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.plugin.common.MethodChannel

internal class NotificacionesFixa(private val actividad: Activity) {
    private var pendiente: MethodChannel.Result? = null

    val disponibles = true

    fun solicitarToken(resultado: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= 33 &&
            actividad.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            if (pendiente != null) {
                resultado.success(null)
                return
            }
            pendiente = resultado
            actividad.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), SOLICITUD)
            return
        }
        obtenerToken(resultado)
    }

    fun recibirPermiso(codigo: Int, permisos: IntArray) {
        if (codigo != SOLICITUD) return
        val resultado = pendiente ?: return
        pendiente = null
        if (permisos.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            obtenerToken(resultado)
        } else {
            resultado.success(null)
        }
    }

    private fun obtenerToken(resultado: MethodChannel.Result) {
        val gestor = Handler(Looper.getMainLooper())
        var entregado = false
        fun terminar(token: String?) {
            if (entregado) return
            entregado = true
            resultado.success(token)
        }
        val tiempoAgotado = Runnable { terminar(null) }
        gestor.postDelayed(tiempoAgotado, 5_000)
        try {
            FirebaseMessaging.getInstance().apply {
                isAutoInitEnabled = true
                token.addOnCompleteListener { tarea ->
                    gestor.removeCallbacks(tiempoAgotado)
                    terminar(if (tarea.isSuccessful) tarea.result else null)
                }
            }
        } catch (_: IllegalStateException) {
            gestor.removeCallbacks(tiempoAgotado)
            terminar(null)
        }
    }

    private companion object {
        const val SOLICITUD = 611
    }
}

