package com.example.myadhan

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

/**
 * Shared helper for scheduling AlarmManager alarms from SharedPreferences.
 * Used by:
 * - MainActivity (when Flutter schedules alarms via MethodChannel)
 * - BootReceiver (re-schedules after device reboot)
 * - WorkManager daily refresh (saves to SharedPrefs, triggers reschedule)
 */
object AlarmSchedulerHelper {
    private const val TAG = "AlarmSchedulerHelper"
    private const val PREFS_NAME = "FlutterSharedPreferences"

    /**
     * Schedule a single prayer alarm using AlarmManager.setAlarmClock().
     * This is the highest priority alarm on Android — survives Doze mode.
     */
    fun scheduleAlarm(context: Context, prayerId: Int, triggerAtMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        Log.d(TAG, "Scheduling alarm: prayerId=$prayerId, triggerAt=$triggerAtMillis")
        Log.d(TAG, "Current time: ${System.currentTimeMillis()}")
        Log.d(TAG, "Alarm in ${(triggerAtMillis - System.currentTimeMillis()) / 1000} seconds")

        // Don't schedule alarms in the past
        if (triggerAtMillis <= System.currentTimeMillis()) {
            Log.w(TAG, "Skipping alarm $prayerId — trigger time is in the past")
            return
        }

        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_ID, prayerId)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            prayerId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                Log.d(TAG, "setAlarmClock scheduled successfully for prayer $prayerId")
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                Log.d(TAG, "setExact scheduled successfully for prayer $prayerId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling alarm $prayerId: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * Cancel all 5 prayer alarms + test alarm.
     */
    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        for (prayerId in 1..5) {
            val intent = Intent(context, PrayerAlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                prayerId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }

        // Also cancel test alarm (ID 999)
        val testIntent = Intent(context, PrayerAlarmReceiver::class.java)
        val testPending = PendingIntent.getBroadcast(
            context, 999, testIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(testPending)

        Log.d(TAG, "All native prayer alarms cancelled")
    }

    /**
     * Re-schedule all prayer alarms from SharedPreferences.
     * Reads the trigger timestamps saved by the Dart side or WorkManager,
     * and schedules AlarmManager alarms for each enabled prayer.
     *
     * SharedPrefs keys (with flutter. prefix):
     * - flutter.prayer_{id}_name → prayer name (String)
     * - flutter.prayer_{id}_time → display time HH:mm (String)
     * - flutter.prayer_{id}_trigger_millis → epoch millis for next alarm (Long)
     * - flutter.adhan_enabled_{name} → whether adhan is enabled (Boolean)
     */
    fun rescheduleAllFromPrefs(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        var scheduledCount = 0

        Log.d(TAG, "Rescheduling all alarms from SharedPreferences...")

        for (prayerId in 1..5) {
            val name = prefs.getString("flutter.prayer_${prayerId}_name", null)
            if (name == null) {
                Log.d(TAG, "Prayer $prayerId: no name found, skipping")
                continue
            }

            // Check if adhan is enabled for this prayer
            val isEnabled = prefs.getBoolean("flutter.adhan_enabled_$name", true)
            if (!isEnabled) {
                Log.d(TAG, "Prayer $prayerId ($name): adhan disabled, skipping")
                continue
            }

            // Read the trigger timestamp
            val triggerMillis = prefs.getLong("flutter.prayer_${prayerId}_trigger_millis", 0L)
            if (triggerMillis == 0L) {
                Log.d(TAG, "Prayer $prayerId ($name): no trigger time found, skipping")
                continue
            }

            // If the trigger time has passed, compute next day's trigger
            var actualTrigger = triggerMillis
            if (actualTrigger <= now) {
                // Add 24 hours to get tomorrow's prayer time
                actualTrigger += 24 * 60 * 60 * 1000L

                // Update SharedPrefs with the new trigger time
                prefs.edit().putLong("flutter.prayer_${prayerId}_trigger_millis", actualTrigger).apply()
                Log.d(TAG, "Prayer $prayerId ($name): trigger was in past, moved to tomorrow")
            }

            scheduleAlarm(context, prayerId, actualTrigger)
            scheduledCount++

            val timeStr = prefs.getString("flutter.prayer_${prayerId}_time", "??:??")
            Log.d(TAG, "Prayer $prayerId ($name) at $timeStr → scheduled for ${actualTrigger}ms")
        }

        Log.d(TAG, "Rescheduled $scheduledCount alarms from SharedPreferences")
    }
}
