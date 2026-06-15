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

            // 1. Read all 5 prayers, populate text, and find the NEXT prayer
            for (i in 1..5) {
                val name = prefs.getString("flutter.prayer_${i}_name", null)
                val time = prefs.getString("flutter.prayer_${i}_time", "--:--")
                val triggerMillis = prefs.getLong("flutter.prayer_${i}_trigger_millis", 0L)

                // Populate text
                val nameResId = context.resources.getIdentifier("text_name_$i", "id", context.packageName)
                val timeResId = context.resources.getIdentifier("text_time_$i", "id", context.packageName)
                
                if (name != null && nameResId != 0 && timeResId != 0) {
                    views.setTextViewText(nameResId, name)
                    views.setTextViewText(timeResId, time)
                }

                // Determine if this is the upcoming prayer
                if (triggerMillis > now && triggerMillis < minTriggerMillis) {
                    minTriggerMillis = triggerMillis
                    nextPrayerId = i
                    if (name != null) nextPrayerName = name
                }
            }

            // 2. Apply styling based on whether it is passed, next, or upcoming
            for (i in 1..5) {
                val rowResId = context.resources.getIdentifier("row_prayer_$i", "id", context.packageName)
                val nameResId = context.resources.getIdentifier("text_name_$i", "id", context.packageName)
                val timeResId = context.resources.getIdentifier("text_time_$i", "id", context.packageName)
                val triggerMillis = prefs.getLong("flutter.prayer_${i}_trigger_millis", 0L)
                
                if (rowResId == 0) continue

                // Reset backgrounds first
                views.setInt(rowResId, "setBackgroundResource", 0)

                when {
                    i == nextPrayerId -> {
                        // Highlight the next prayer
                        views.setInt(rowResId, "setBackgroundResource", R.drawable.widget_row_next)
                        views.setTextColor(nameResId, android.graphics.Color.parseColor("#F0F8FF"))
                        views.setTextColor(timeResId, android.graphics.Color.parseColor("#4DB3E5"))
                    }
                    triggerMillis < now -> {
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
                views.setTextViewText(R.id.widget_next_prayer_name, "Until $nextPrayerName")
                
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
