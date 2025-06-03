package com.example.namekart_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "FORCE_STOP_ALARM" -> {
                try {
                    MyFirebaseMessagingService.ringtone?.stop()
                    MyFirebaseMessagingService.ringtone = null
                    Log.d("FCM", "🛑 Alarm stopped from notification action")
                } catch (e: Exception) {
                    Log.e("FCM", "Error stopping ringtone: ${e.message}")
                }
            }
        }
    }
}
