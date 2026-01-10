package com.example.myadhan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

/**
 * BroadcastReceiver that is triggered by AlarmManager when prayer time arrives.
 * This works even when the app is killed since it's registered in AndroidManifest.xml
 */
class PrayerAlarmReceiver : BroadcastReceiver() {
    
    companion object {
        const val TAG = "PrayerAlarmReceiver"
        const val EXTRA_PRAYER_ID = "prayer_id"
        const val PREFS_NAME = "FlutterSharedPreferences"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive called!")
        
        val prayerId = intent.getIntExtra(EXTRA_PRAYER_ID, 0)
        Log.d(TAG, "Prayer ID: $prayerId")
        
        // Get prayer info from SharedPreferences (Flutter stores with 'flutter.' prefix)
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val prayerName = prefs.getString("flutter.prayer_${prayerId}_name", "الصلاة") ?: "الصلاة"
        val prayerTime = prefs.getString("flutter.prayer_${prayerId}_time", "") ?: ""
        
        Log.d(TAG, "Prayer Name: $prayerName, Time: $prayerTime")
        
        // Start the AdhanAlarmService which will show notification + launch AdhanActivity
        val serviceIntent = Intent(context, AdhanAlarmService::class.java).apply {
            putExtra("prayerName", prayerName)
            putExtra("prayerTime", prayerTime)
        }
        
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                Log.d(TAG, "Starting foreground service...")
                context.startForegroundService(serviceIntent)
            } else {
                Log.d(TAG, "Starting service...")
                context.startService(serviceIntent)
            }
            Log.d(TAG, "Service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting service: ${e.message}")
            e.printStackTrace()
        }
    }
}
