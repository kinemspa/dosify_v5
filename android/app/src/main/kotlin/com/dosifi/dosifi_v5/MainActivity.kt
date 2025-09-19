package com.dosifi.dosifi_v5

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dosifi/notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "canScheduleExactAlarms" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        result.success(am.canScheduleExactAlarms())
                    } else {
                        // On older versions, exact alarms are permitted without this gated check
                        result.success(true)
                    }
                }
                "getChannelImportance" -> {
                    val channelId = call.argument<String>("channelId")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && channelId != null) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        val channel = nm.getNotificationChannel(channelId)
                        result.success(channel?.importance ?: -1)
                    } else {
                        result.success(-1)
                    }
                }
                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                    val pkg = applicationContext.packageName
                    result.success(pm.isIgnoringBatteryOptimizations(pkg))
                }
                "requestIgnoreBatteryOptimizations" -> {
                    val pkg = applicationContext.packageName
                    try {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = android.net.Uri.parse("package:" + pkg)
                        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("IGNORE_BATTERY", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
