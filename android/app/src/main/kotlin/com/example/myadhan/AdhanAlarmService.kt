package com.example.myadhan

import android.app.NotificationChannel
import android.app.NotificationManager
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
        
        // Show notification
        showNotification(prayerName, prayerTime)
        
        // Start the adhan activity
        val adhanIntent = Intent(this, AdhanActivity::class.java).apply {
            putExtra("prayerName", prayerName)
            putExtra("prayerTime", prayerTime)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(adhanIntent)
        
        // Stop the service after starting the activity
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