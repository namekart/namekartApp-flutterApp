package com.example.namekart_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        var ringtone: Ringtone? = null
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val title = remoteMessage.data["title"] ?: "Notification"
        val body = remoteMessage.data["body"] ?: "You have a message."
        val ringAlarm = remoteMessage.data["ringalarm"] == "true"

        showNotification(title, body, ringAlarm)
    }

    private fun showNotification(title: String, body: String, ringAlarm: Boolean) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channelId = if (ringAlarm) "alarm_channel" else "high_importance_channel"
        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.deleteNotificationChannel(channelId)
            val channel = NotificationChannel(
                channelId,
                if (ringAlarm) "Alarm Notifications" else "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                if (ringAlarm) {
                    setSound(alarmUri, audioAttributes)
                    enableVibration(true)
                    enableLights(true)
                } else {
                    setSound(null, null)
                }
            }
            notificationManager.createNotificationChannel(channel)
        }

        val mainIntent = Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val mainPendingIntent = PendingIntent.getActivity(
            this, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true) // 🔒 Notification is sticky, not dismissible
            .setAutoCancel(false) // 🚫 Don't auto-cancel when tapped
            .setContentIntent(mainPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)


        if (ringAlarm) {
            try {
                ringtone?.stop()
                ringtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
                ringtone?.play()
            } catch (e: Exception) {
                Log.e("FCM", "Error playing ringtone: ${e.message}")
            }

            val stopIntent = Intent(this, NotificationActionReceiver::class.java).apply {
                action = "FORCE_STOP_ALARM"
            }
            val stopPendingIntent = PendingIntent.getBroadcast(
                this, 1, stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(R.mipmap.ic_launcher, "Force Stop", stopPendingIntent)
        }

        notificationManager.notify(System.currentTimeMillis().toInt(), builder.build())
    }
}
