package com.example.myadhan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
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
                    
                    scheduleNativeAlarm(prayerId, triggerAtMillis)
                    result.success("Alarm scheduled for prayer $prayerId")
                }
                "cancelAllNativeAlarms" -> {
                    cancelAllAlarms()
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
                    scheduleNativeAlarm(999, triggerTime) // ID 999 for test
                    result.success("Test alarm scheduled for 10 seconds from now")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun scheduleNativeAlarm(prayerId: Int, triggerAtMillis: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        Log.d(TAG, "Scheduling alarm: prayerId=$prayerId, triggerAt=$triggerAtMillis")
        Log.d(TAG, "Current time: ${System.currentTimeMillis()}")
        Log.d(TAG, "Alarm in ${(triggerAtMillis - System.currentTimeMillis()) / 1000} seconds")
        
        val intent = Intent(this, PrayerAlarmReceiver::class.java).apply {
            putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_ID, prayerId)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            prayerId, // Use prayer ID as request code for uniqueness
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Use setAlarmClock for highest priority - shows in system UI and wakes device
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                Log.d(TAG, "setAlarmClock scheduled successfully")
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                Log.d(TAG, "setExact scheduled successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling alarm: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun cancelAllAlarms() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        for (prayerId in 1..5) {
            val intent = Intent(this, PrayerAlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                prayerId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
        
        Log.d(TAG, "All native prayer alarms cancelled")
    }
    
    companion object {
        private const val TAG = "MainActivity"
    }
}
