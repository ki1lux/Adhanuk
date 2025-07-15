package com.example.myadhan// ← Use your actual package name here

import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class AdhanActivity : AppCompatActivity() {

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
        findViewById<TextView>(R.id.prayerTitle).text = prayerName

        findViewById<Button>(R.id.cancelButton).setOnClickListener {
            finish()
        }
    }
}
