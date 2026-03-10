package com.example.myadhan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.content.Context
import android.util.Log
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
                "scheduleNativePrayerAlarm" -> {
                    val prayerId = call.argument<Int>("prayerId") ?: 0
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    
                    AlarmSchedulerHelper.scheduleAlarm(this, prayerId, triggerAtMillis)
                    result.success("Alarm scheduled for prayer $prayerId")
                }
                "cancelAllNativeAlarms" -> {
                    AlarmSchedulerHelper.cancelAll(this)
                    result.success("All alarms cancelled")
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
                "testNativeAlarm" -> {
                    val triggerTime = System.currentTimeMillis() + 10000 // 10 seconds from now
                    AlarmSchedulerHelper.scheduleAlarm(this, 999, triggerTime)
                    result.success("Test alarm scheduled for 10 seconds from now")
                }
                "openBatterySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", "Could not open settings", null)
                        }
                    }
                }
                "rescheduleFromPrefs" -> {
                    AlarmSchedulerHelper.rescheduleAllFromPrefs(this)
                    result.success("Alarms rescheduled from SharedPreferences")
                }
                "registerDailyPrayerWorker" -> {
                    PrayerUpdateWorker.enqueue(this)
                    result.success("Daily prayer worker registered")
                }
                "startCountdownService" -> {
                    try {
                        val serviceIntent = Intent(this, PrayerCountdownService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success("Countdown service started")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting countdown service: ${e.message}")
                        result.error("ERROR", "Failed to start countdown: ${e.message}", null)
                    }
                }
                "stopCountdownService" -> {
                    val serviceIntent = Intent(this, PrayerCountdownService::class.java)
                    stopService(serviceIntent)
                    result.success("Countdown service stopped")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    companion object {
        private const val TAG = "MainActivity"
    }
}
