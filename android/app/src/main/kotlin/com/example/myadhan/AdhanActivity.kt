//package com.example.myadhan
//
//import android.media.MediaPlayer
//import android.os.Bundle
//import android.view.WindowManager
//import android.widget.Button
//import android.widget.TextView
//import androidx.appcompat.app.AppCompatActivity
//
//class AdhanActivity : AppCompatActivity() {
//
//    private var mediaPlayer: MediaPlayer? = null
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        setContentView(R.layout.activity_adhan)
//
//        // Wake screen and show over lock screen
//        window.addFlags(
//            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
//                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
//                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
//        )
//
//        val prayerName = intent.getStringExtra("prayerName") ?: "صلاة"
//        findViewById<TextView>(R.id.prayerTitle).text = prayerName
//
//        mediaPlayer = MediaPlayer.create(this, R.raw.adhan) // add adhan.mp3 to res/raw
//        mediaPlayer?.start()
//
//        // Auto close when sound finishes
//        mediaPlayer?.setOnCompletionListener {
//            finish()
//        }
//
//        // Cancel button
//        findViewById<Button>(R.id.cancelButton).setOnClickListener {
//            mediaPlayer?.stop()
//            mediaPlayer?.release()
//            finish()
//        }
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        mediaPlayer?.release()
//    }
//}
