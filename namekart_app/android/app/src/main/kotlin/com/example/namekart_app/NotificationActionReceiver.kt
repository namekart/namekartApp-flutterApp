package com.example.namekart_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        when (action) {
            "ACCEPT_ACTION" -> Log.d("FCM", "Accept button clicked")
            "REJECT_ACTION" -> Log.d("FCM", "Reject button clicked")
        }
    }
}