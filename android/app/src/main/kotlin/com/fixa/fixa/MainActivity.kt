package com.fixa.fixa

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val comprobante by lazy { ComprobanteAndroid(this) }
    private val notificaciones by lazy { NotificacionesFixa(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val mensajero = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(mensajero, "com.fixa.fixa/comprobante")
            .setMethodCallHandler(comprobante::atender)
        MethodChannel(mensajero, "com.fixa.fixa/notificaciones")
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "disponibles" -> resultado.success(notificaciones.disponibles)
                    "solicitarToken" -> notificaciones.solicitarToken(resultado)
                    else -> resultado.notImplemented()
                }
            }
    }

    @Deprecated("El selector de documentos entrega su resultado a FlutterActivity")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        comprobante.recibir(requestCode, resultCode, data?.data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        notificaciones.recibirPermiso(requestCode, grantResults)
    }
}

