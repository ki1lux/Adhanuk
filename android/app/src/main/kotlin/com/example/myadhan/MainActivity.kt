package com.example.myadhan

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.app.AlarmManager
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity(){

    private val CHANNEL = "com.myadhan/notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "showFullScreenAdhan" -> {
                    val prayerName = call.argument<String>("prayerName") ?: "صلاة"
                    val prayerTime = call.argument<String>("prayerTime") ?: "حان وقت الصلاة"

                    val intent = Intent(this, AdhanActivity::class.java).apply {
                        putExtra("prayerName" , prayerName)
                        putExtra("prayerTime", prayerTime)

                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    }

                    startActivity(intent)
                    result.success("Adhan shown")
                }
                "startAdhanService" -> {
                    val prayerName = call.argument<String>("prayerName") ?: "صلاة"
                    val prayerTime = call.argument<String>("prayerTime") ?: "حان وقت الصلاة"

                    val serviceIntent = Intent(this, AdhanAlarmService::class.java).apply {
                        putExtra("prayerName", prayerName)
                        putExtra("prayerTime", prayerTime)
                    }

                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    
                    result.success("Adhan service started")
                }
                "requestExactAlarmPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        if (!alarmManager.canScheduleExactAlarms()) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "checkExactAlarmPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        result.success(alarmManager.canScheduleExactAlarms())
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
