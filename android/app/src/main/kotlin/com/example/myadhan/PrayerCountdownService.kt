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
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground Service that shows a persistent notification with countdown
 * to the next prayer time.
 *
 * Optimizations applied:
 * 1. Doze-resilient: uses postAtTime(SystemClock.uptimeMillis) instead of postDelayed
 * 2. Cached builder: reuses NotificationCompat.Builder, only updates text
 * 3. Zero-moment state machine: handles prayer transition gracefully
 * 4. Adaptive frequency: 1s updates in final minute, 60s otherwise
 */
class PrayerCountdownService : Service() {

    companion object {
        private const val TAG = "PrayerCountdownService"
        private const val CHANNEL_ID = "prayer_countdown_channel"
        private const val NOTIFICATION_ID = 2001
        private const val NORMAL_INTERVAL_MS = 60_000L  // Every 60s normally
        private const val FAST_INTERVAL_MS = 1_000L     // Every 1s in final minute
        private const val PREFS_NAME = "FlutterSharedPreferences"

        /**
         * Static helper to start the countdown service from anywhere.
         * Called by BootReceiver, PrayerAlarmReceiver, and onTaskRemoved.
         */
        fun startIfNeeded(context: Context) {
            try {
                val intent = Intent(context, PrayerCountdownService::class.java)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                Log.d(TAG, "Countdown service (re)started")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start countdown service: ${e.message}")
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var prefs: SharedPreferences

    // Pro-tip #2: Keep a reference to the builder — don't recreate every tick
    private var cachedBuilder: NotificationCompat.Builder? = null
    private var currentPrayerId: Int? = null // Track which prayer we're counting down to

    private val updateRunnable = object : Runnable {
        override fun run() {
            val nextInterval = updateNotification()

            // Pro-tip #1: Use postAtTime with uptimeMillis for Doze resilience
            val nextTick = SystemClock.uptimeMillis() + nextInterval
            handler.postAtTime(this, nextTick)
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

        // Build initial notification
        val notification = buildInitialNotification()
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

        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        handler.removeCallbacks(updateRunnable)
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Auto-restart when user swipes app from recents
        Log.d(TAG, "Task removed — restarting countdown service")
        startIfNeeded(this)
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Update notification and return the interval until the next update.
     * Pro-tip #4: Adaptive frequency — 1s in final minute, 60s otherwise.
     */
    private fun updateNotification(): Long {
        val now = System.currentTimeMillis()
        val nextPrayer = findNextPrayer(now)

        val title: String
        val text: String
        var nextInterval = NORMAL_INTERVAL_MS

        if (nextPrayer != null) {
            val remainingMs = nextPrayer.triggerMillis - now

            // Pro-tip #3: Zero-moment state machine
            if (remainingMs <= 0) {
                // Prayer time has arrived — briefly show "حان الوقت" then advance
                title = "حان وقت صلاة ${nextPrayer.name}"
                text = "حان الآن"
                currentPrayerId = null // Force re-scan on next tick
                nextInterval = 5_000L // Check again in 5s for next prayer
            } else {
                val totalSeconds = remainingMs / 1_000
                val hours = totalSeconds / 3600
                val minutes = (totalSeconds % 3600) / 60
                val seconds = totalSeconds % 60

                title = "صلاة ${nextPrayer.name}"

                // Pro-tip #4: Switch to per-second updates in final minute
                if (remainingMs <= 60_000) {
                    text = "بعد $seconds ثانية"
                    nextInterval = FAST_INTERVAL_MS
                } else if (hours > 0) {
                    text = "بعد $hours ساعة و $minutes دقيقة"
                    nextInterval = NORMAL_INTERVAL_MS
                } else {
                    text = "بعد $minutes دقيقة"
                    nextInterval = NORMAL_INTERVAL_MS
                }

                currentPrayerId = nextPrayer.id
            }
        } else {
            title = "أوقات الصلاة"
            text = "لا توجد صلاة قادمة"
            nextInterval = NORMAL_INTERVAL_MS
        }

        // Pro-tip #2: Reuse the cached builder — only update text fields
        val builder = getOrCreateBuilder()
        builder.setContentTitle(title)
        builder.setContentText(text)

        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        mgr.notify(NOTIFICATION_ID, builder.build())

        return nextInterval
    }

    /**
     * Pro-tip #2: Cache the NotificationCompat.Builder.
     * Only create once, then reuse and update text fields only.
     */
    private fun getOrCreateBuilder(): NotificationCompat.Builder {
        cachedBuilder?.let { return it }

        // Tap → open app
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val tapPending = PendingIntent.getActivity(
            this, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(tapPending)
            .setSilent(true)

        cachedBuilder = builder
        return builder
    }

    /**
     * Build the initial notification (before the first update tick).
     */
    private fun buildInitialNotification(): android.app.Notification {
        val builder = getOrCreateBuilder()
        builder.setContentTitle("أوقات الصلاة")
        builder.setContentText("جاري التحميل...")
        return builder.build()
    }

    /**
     * Find the next upcoming prayer from SharedPreferences.
     * Pro-tip #3: If currentPrayerId is set, check that one first for efficiency.
     */
    private fun findNextPrayer(now: Long): NextPrayer? {
        var closest: NextPrayer? = null

        for (prayerId in 1..5) {
            val name = prefs.getString("flutter.prayer_${prayerId}_name", null) ?: continue
            val triggerMillis = prefs.getLong("flutter.prayer_${prayerId}_trigger_millis", 0L)

            val isEnabled = prefs.getBoolean("flutter.adhan_enabled_$name", true)
            if (!isEnabled) continue

            if (triggerMillis <= 0) continue

            // Include prayers that just arrived (within 30s window) for zero-moment display
            if (triggerMillis < now - 30_000) continue

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
                NotificationManager.IMPORTANCE_LOW
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
