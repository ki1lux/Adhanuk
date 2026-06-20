package com.example.myadhan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // Update all instances of this widget
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // If data was refreshed, update all widgets
        if (intent.action == "com.example.myadhan.ACTION_PRAYER_UPDATED") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, PrayerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"

        internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Intent to open the app when tapped
            val pendingIntent: PendingIntent = Intent(context, MainActivity::class.java).let { intent ->
                PendingIntent.getActivity(
                    context, 
                    0, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }
            views.setOnClickPendingIntent(R.id.widget_countdown, pendingIntent)

            val now = System.currentTimeMillis()
            var nextPrayerId = -1
            var minTriggerMillis = Long.MAX_VALUE
            var nextPrayerName = "Loading..."
            var nextPrayerTime = ""
            
            val computedTriggers = LongArray(6)

            // 1. Read all 5 prayers, populate text, and find the NEXT prayer
            for (i in 1..5) {
                val name = prefs.getString("flutter.prayer_${i}_name", null)
                val time = prefs.getString("flutter.prayer_${i}_time", "--:--")

                // Parse the time string directly instead of relying on the alarm trigger_millis 
                // because the alarm trigger_millis might not be updated if the user disabled the Adhan for this prayer.
                var actualTriggerMillis = 0L
                if (time != null && time != "--:--") {
                    try {
                        val parts = time.split(":")
                        if (parts.size == 2) {
                            val hour = parts[0].toInt()
                            val minute = parts[1].toInt()
                            val cal = java.util.Calendar.getInstance()
                            cal.set(java.util.Calendar.HOUR_OF_DAY, hour)
                            cal.set(java.util.Calendar.MINUTE, minute)
                            cal.set(java.util.Calendar.SECOND, 0)
                            cal.set(java.util.Calendar.MILLISECOND, 0)
                            
                            actualTriggerMillis = cal.timeInMillis
                            
                            // If this prayer's time today has passed, it will happen tomorrow
                            if (actualTriggerMillis <= now) {
                                actualTriggerMillis += 24 * 60 * 60 * 1000L
                            }
                        }
                    } catch (e: Exception) {}
                }
                
                computedTriggers[i] = actualTriggerMillis

                // Populate text
                val nameResId = context.resources.getIdentifier("text_name_$i", "id", context.packageName)
                val timeResId = context.resources.getIdentifier("text_time_$i", "id", context.packageName)
                
                if (name != null && nameResId != 0 && timeResId != 0) {
                    views.setTextViewText(nameResId, name)
                    views.setTextViewText(timeResId, time)
                }

                // Determine if this is the upcoming prayer
                if (actualTriggerMillis > now && actualTriggerMillis < minTriggerMillis) {
                    minTriggerMillis = actualTriggerMillis
                    nextPrayerId = i
                    if (name != null) {
                        nextPrayerName = name
                        nextPrayerTime = time ?: ""
                    }
                }
            }

            // 2. Apply styling based on whether it is passed, next, or upcoming
            for (i in 1..5) {
                val rowResId = context.resources.getIdentifier("row_prayer_$i", "id", context.packageName)
                val nameResId = context.resources.getIdentifier("text_name_$i", "id", context.packageName)
                val timeResId = context.resources.getIdentifier("text_time_$i", "id", context.packageName)
                val actualTriggerMillis = computedTriggers[i]
                
                if (rowResId == 0 || actualTriggerMillis == 0L) continue

                // Reset backgrounds first
                views.setInt(rowResId, "setBackgroundResource", 0)

                // If a prayer was moved to tomorrow (actualTriggerMillis > now + 12 hours generally, 
                // but more precisely if actualTriggerMillis was incremented by 24 hours), 
                // it means it has passed TODAY. 
                // Wait, if it's tomorrow, it's > now. 
                // To check if it "passed today", we can check if actualTriggerMillis - 24 hours <= now.
                // But a simpler check: if it's NOT the next prayer, and it's scheduled for tomorrow, it's "passed" today.
                // Actually, any prayer that is scheduled for tomorrow (except maybe the next prayer if ALL passed today)
                // is visually "passed" for the current day's cycle.
                
                // Let's use a robust check: if it's tomorrow, its actual time today is actualTriggerMillis - 24h.
                val timeToday = if (actualTriggerMillis > now + 12 * 60 * 60 * 1000L) {
                    // It was likely pushed to tomorrow.
                    actualTriggerMillis - 24 * 60 * 60 * 1000L
                } else {
                    actualTriggerMillis
                }
                
                val hasPassedToday = timeToday <= now

                when {
                    i == nextPrayerId -> {
                        // Highlight the next prayer
                        views.setInt(rowResId, "setBackgroundResource", R.drawable.widget_row_next)
                        views.setTextColor(nameResId, android.graphics.Color.parseColor("#F0F8FF"))
                        views.setTextColor(timeResId, android.graphics.Color.parseColor("#4DB3E5"))
                    }
                    hasPassedToday -> {
                        // Mute passed prayers
                        views.setTextColor(nameResId, android.graphics.Color.parseColor("#66F0F8FF"))
                        views.setTextColor(timeResId, android.graphics.Color.parseColor("#66F0F8FF"))
                    }
                    else -> {
                        // Normal styling for future prayers today
                        views.setTextColor(nameResId, android.graphics.Color.parseColor("#F0F8FF"))
                        views.setTextColor(timeResId, android.graphics.Color.parseColor("#F0F8FF"))
                    }
                }
            }

            // 3. Configure Chronometer
            if (nextPrayerId != -1) {
                views.setTextViewText(R.id.widget_next_prayer_name, "$nextPrayerName $nextPrayerTime".trim())
                
                // Convert epoch millis to SystemClock elapsedRealtime base
                val offset = minTriggerMillis - System.currentTimeMillis()
                val baseTime = SystemClock.elapsedRealtime() + offset
                
                views.setChronometer(R.id.widget_countdown, baseTime, "Next in %s", true)
            } else {
                views.setTextViewText(R.id.widget_next_prayer_name, "Please open the app to sync")
            }

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
