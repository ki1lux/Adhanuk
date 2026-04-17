package com.example.myadhan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class AdhanAlarmService : Service() {

    companion object {
        private const val TAG = "AdhanAlarmService"
        private const val CHANNEL_ID = "adhan_playback_channel"
        private const val NOTIFICATION_ID = 1001
        const val ACTION_STOP_ADHAN = "com.example.myadhan.STOP_ADHAN"
    }

    private var currentPrayerName = "الصلاة"
    private var currentPrayerTime = ""
    private val handler = Handler(Looper.getMainLooper())
    private var isPlaying = false

    // Receiver for the "Stop" button in the notification
    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            Log.d(TAG, "Stop action received")
            stopAdhanAndService()
        }
    }

    // Re-posts notification if swiped away (Android 14+)
    private val notificationWatchdog = object : Runnable {
        override fun run() {
            if (!isPlaying) return
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val active = mgr.activeNotifications.any { it.id == NOTIFICATION_ID }
            if (!active) {
                Log.d(TAG, "Notification swiped — re-posting in drawer")
                val notification = buildNotification(currentPrayerName, currentPrayerTime)
                mgr.notify(NOTIFICATION_ID, notification)
            }
            handler.postDelayed(this, 2000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        // Register stop receiver
        val filter = IntentFilter(ACTION_STOP_ADHAN)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prayerName = intent?.getStringExtra("prayerName") ?: "الصلاة"
        val prayerTime = intent?.getStringExtra("prayerTime") ?: "حان وقت الصلاة"
        val soundName = intent?.getStringExtra("soundName") ?: "adhan1"

        currentPrayerName = prayerName
        currentPrayerTime = prayerTime

        Log.d(TAG, "Starting Adhan: $prayerName at $prayerTime, sound=$soundName")

        // Build notification with stop action FIRST (required before startForeground)
        val notification = buildNotification(prayerName, prayerTime)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground: ${e.message}")
            // Still try to play audio even if foreground fails
        }


        // Play Adhan on ALARM stream with audio focus
        val resId = AdhanPlayer.getSoundResId(this, soundName)
        AdhanPlayer.play(this, resId) {
            // Called when playback completes
            Log.d(TAG, "Adhan completed, stopping service")
            stopAdhanAndService()
        }

        // Start watchdog to re-post notification if swiped
        isPlaying = true
        handler.postDelayed(notificationWatchdog, 2000)

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        isPlaying = false
        handler.removeCallbacks(notificationWatchdog)
        AdhanPlayer.stop()
        try {
            unregisterReceiver(stopReceiver)
        } catch (e: Exception) {
            // Already unregistered
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun stopAdhanAndService() {
        isPlaying = false
        handler.removeCallbacks(notificationWatchdog)
        AdhanPlayer.stop()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification(prayerName: String, prayerTime: String): android.app.Notification {
        // Intent for tapping the notification → open app
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val tapPending = PendingIntent.getActivity(
            this, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent for "Stop" action button
        val stopIntent = Intent(ACTION_STOP_ADHAN).apply {
            setPackage(packageName)
        }
        val stopPending = PendingIntent.getBroadcast(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("حان وقت صلاة $prayerName")
            .setContentText("الوقت: $prayerTime")
            .setSmallIcon(R.drawable.ic_stat_adhan)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true) // Can't be swiped while Adhan is playing
            .setContentIntent(tapPending)
            .setFullScreenIntent(tapPending, true) // Forces it to be the #1 active heads-up alarm
            .setWhen(System.currentTimeMillis())
            .addAction(R.drawable.ic_stat_adhan, "إيقاف الأذان", stopPending)
            .setSound(null) // No notification sound — audio via MediaPlayer
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Adhan Playback",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows when Adhan is playing"
                setSound(null, null) // Silent channel — audio via MediaPlayer on ALARM stream
                enableVibration(true)
                enableLights(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            mgr.createNotificationChannel(channel)
        }
    }
}