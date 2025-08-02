package com.example.myadhan// ← Use your actual package name here

import android.media.MediaPlayer
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class AdhanActivity : AppCompatActivity() {

    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_adhan)

        // Show even if phone is locked + turn on screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        val prayerName = intent.getStringExtra("prayerName") ?: "الصلاة"
        val prayerTime = intent.getStringExtra("prayerTime") ?: "حان وقت الصلاة"
        findViewById<TextView>(R.id.prayerTitle).text = prayerName
        findViewById<TextView>(R.id.messageText).text = prayerTime

        val okayButton = findViewById<Button>(R.id.okayButton)
        val cancelButton = findViewById<Button>(R.id.cancelButton)


        AdhanPlayer.play(this)

        okayButton.setOnClickListener {
            // Reschedule alarms for next day when user acknowledges the adhan
            rescheduleNextDayAlarms()
            finish()
        }

        cancelButton.setOnClickListener {
            AdhanPlayer.stop()
            // Still reschedule alarms even if user cancels
            rescheduleNextDayAlarms()
            finish()
        }
    }

    private fun rescheduleNextDayAlarms() {
        // This will be handled by the Flutter side through the alarm callback
        // The alarm callback will automatically reschedule the next day's alarms
        println("Adhan completed, next day alarms will be scheduled by Flutter")
    }
    
//    override fun onDestroy() {
//        super.onDestroy()
//        mediaPlayer?.release()
//        mediaPlayer = null
//    }
}
