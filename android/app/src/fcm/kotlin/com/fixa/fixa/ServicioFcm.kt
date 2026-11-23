package com.fixa.fixa

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class ServicioFcm : FirebaseMessagingService() {
    override fun onMessageReceived(mensaje: RemoteMessage) {
        val aviso = mensaje.notification ?: return
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return

        val gestor = getSystemService(NotificationManager::class.java)
        val alerta = if (Build.VERSION.SDK_INT >= 26) {
            gestor.createNotificationChannel(
                NotificationChannel(CANAL, "Seguimiento de reportes", NotificationManager.IMPORTANCE_DEFAULT)
            )
            Notification.Builder(this, CANAL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val abrirApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        gestor.notify(
            mensaje.messageId?.hashCode() ?: System.currentTimeMillis().toInt(),
            alerta.setSmallIcon(R.drawable.ic_notificacion_fixa)
                .setContentTitle(aviso.title ?: "FIXA")
                .setContentText(aviso.body)
                .setStyle(Notification.BigTextStyle().bigText(aviso.body))
                .setContentIntent(abrirApp)
                .setAutoCancel(true)
                .build()
        )
    }

    private companion object {
        const val CANAL = "seguimiento_fixa"
    }
}
