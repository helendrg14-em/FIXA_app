package com.fixa.fixa

import android.app.Activity
import android.app.Service
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

@Suppress("UNUSED_PARAMETER")
internal class NotificacionesFixa(actividad: Activity) {
    val disponibles = false

    fun solicitarToken(resultado: MethodChannel.Result) = resultado.success(null)
    fun recibirPermiso(codigo: Int, permisos: IntArray) = Unit
}

class ServicioFcm : Service() {
    override fun onBind(intent: Intent?) = null
}

