package com.example.myadhan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground Service that shows a persistent notification with countdown
 * to the next prayer time. Updates every 60 seconds.
 *
 * Reads prayer times from SharedPreferences (set by Flutter or WorkManager):
 * - flutter.prayer_{id}_name → Arabic prayer name
 * - flutter.prayer_{id}_trigger_millis → epoch millis for alarm trigger
 */
class PrayerCountdownService : Service() {

    companion object {
        private const val TAG = "PrayerCountdownService"
        private const val CHANNEL_ID = "prayer_countdown_channel"
        private const val NOTIFICATION_ID = 2001
        private const val UPDATE_INTERVAL_MS = 60_000L // Update every 60 seconds
        private const val PREFS_NAME = "FlutterSharedPreferences"
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences

    private val updateRunnable = object : Runnable {
        override fun run() {
            updateNotification()
            handler.postDelayed(this, UPDATE_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        createNotificationChannel()
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")

        // Show initial notification immediately
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground: ${e.message}")
            stopSelf()
            return START_NOT_STICKY
        }

        // Start periodic updates
        handler.removeCallbacks(updateRunnable)
        handler.post(updateRunnable)

        return START_STICKY // Restart if killed
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        handler.removeCallbacks(updateRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Find next prayer and update the notification with countdown.
     */
    private fun updateNotification() {
        val notification = buildNotification()
        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        mgr.notify(NOTIFICATION_ID, notification)
    }

    private fun buildNotification(): android.app.Notification {
        val now = System.currentTimeMillis()
        val nextPrayer = findNextPrayer(now)

        val title: String
        val text: String

        if (nextPrayer != null) {
            val remainingMs = nextPrayer.triggerMillis - now
            val totalMinutes = remainingMs / 60_000
            val hours = totalMinutes / 60
            val minutes = totalMinutes % 60

            title = "صلاة ${nextPrayer.name}"
            text = if (hours > 0) {
                "بعد $hours ساعة و $minutes دقيقة"
            } else {
                "بعد $minutes دقيقة"
            }
        } else {
            title = "أوقات الصلاة"
            text = "لا توجد صلاة قادمة"
        }

        // Tap → open app
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val tapPending = PendingIntent.getActivity(
            this, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true) // Cannot be swiped away
            .setShowWhen(false) // Don't show timestamp
            .setContentIntent(tapPending)
            .setSilent(true) // No sound/vibration on updates
            .build()
    }

    /**
     * Find the next upcoming prayer from SharedPreferences.
     */
    private fun findNextPrayer(now: Long): NextPrayer? {
        var closest: NextPrayer? = null

        for (prayerId in 1..5) {
            val name = prefs.getString("flutter.prayer_${prayerId}_name", null) ?: continue
            val triggerMillis = prefs.getLong("flutter.prayer_${prayerId}_trigger_millis", 0L)

            // Check if adhan is enabled
            val isEnabled = prefs.getBoolean("flutter.adhan_enabled_$name", true)
            if (!isEnabled) continue

            if (triggerMillis <= now) continue // Already passed

            if (closest == null || triggerMillis < closest.triggerMillis) {
                closest = NextPrayer(prayerId, name, triggerMillis)
            }
        }

        return closest
    }

    private data class NextPrayer(
        val id: Int,
        val name: String,
        val triggerMillis: Long
    )

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "عداد الصلاة",
                NotificationManager.IMPORTANCE_LOW // Silent — no sound/vibration
            ).apply {
                description = "يعرض الوقت المتبقي للصلاة القادمة"
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            mgr.createNotificationChannel(channel)
        }
    }
}
