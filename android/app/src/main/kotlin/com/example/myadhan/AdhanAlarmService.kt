package com.example.myadhan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class AdhanAlarmService : Service() {
    
    companion object {
        private const val CHANNEL_ID = "adhan_channel"
        private const val NOTIFICATION_ID = 1
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prayerName = intent?.getStringExtra("prayerName") ?: "الصلاة"
        val prayerTime = intent?.getStringExtra("prayerTime") ?: "حان وقت الصلاة"
        
        // Prepare the intent for the full-screen activity
        val adhanIntent = Intent(this, AdhanActivity::class.java).apply {
            putExtra("prayerName", prayerName)
            putExtra("prayerTime", prayerTime)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            adhanIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification with fullScreenIntent
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("حان وقت صلاة $prayerName")
            .setContentText("الوقت: $prayerTime")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_MAX) // MAX for alarms
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(false)
            .setFullScreenIntent(pendingIntent, true) // Critical for alarm behavior
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
        
        // Start foreground immediately
        startForeground(NOTIFICATION_ID, notification)
        
        // Try to start activity directly as well (works on older Android or if permissible)
        try {
            startActivity(adhanIntent)
        } catch (e: Exception) {
            // On Android 10+, this might fail if app is in background, 
            // but setFullScreenIntent will handle it.
            e.printStackTrace()
        }
        
        // Stop the service after a delay to ensure notification logic runs? 
        // Actually, if we stopSelf importunately, the notification might vanish if it's bound to the service.
        // But since we want the Activity to take over, it's fine.
        // However, for Heads-Up notification (screen on), the service needs to keep running until user dims it?
        // Let's keep it running for a moment or let the Activity handle stopping it?
        // The Activity doesn't stop the service.
        // Let's stopSelf() immediately as we handed off to the Activity/Notification.
        stopForeground(STOP_FOREGROUND_DETACH) // Keep notification
        stopSelf()
        
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Adhan Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for prayer times"
                enableVibration(true)
                enableLights(true)
                // IMPORTANCE_HIGH or MAX is needed for heads-up
                importance = NotificationManager.IMPORTANCE_HIGH
                setSound(null, null) // If we play sound via MediaPlayer in Activity?
                // Or let notification play default sound? 
                // Using setSound(null, null) if we want custom sound from Activity
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(prayerName: String, prayerTime: String) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("حان وقت الصلاة")
            .setContentText("$prayerName - $prayerTime")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setOngoing(false)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}