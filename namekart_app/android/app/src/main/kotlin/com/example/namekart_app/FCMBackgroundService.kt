package com.example.namekart_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class FCMBackgroundService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "fcm_background_channel",
                "FCM Background Service",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)

            val notification = NotificationCompat.Builder(this, "fcm_background_channel")
                .setContentTitle("Running in Background")
                .setContentText("FCM service is active.")
                .setSmallIcon(R.mipmap.ic_launcher)
                .build()

            startForeground(1, notification)
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopForeground(true)
        stopSelf()
        super.onDestroy()
    }
}
