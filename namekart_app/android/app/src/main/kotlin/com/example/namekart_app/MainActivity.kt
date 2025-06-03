package com.example.namekart_app

import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.namekart_app/background_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val serviceIntent = Intent(this, FCMBackgroundService::class.java)
                    startService(serviceIntent)
                    result.success(null)
                }
                "stopAlarm" -> {
                    try {
                        MyFirebaseMessagingService.ringtone?.stop()
                        MyFirebaseMessagingService.ringtone = null
                        Log.d("FCM", "🛑 Alarm stopped via MethodChannel")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("FCM", "Error stopping alarm: ${e.message}")
                        result.error("STOP_ALARM_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = android.net.Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }
}
