package com.example.myadhan

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity(){

    private val CHANNEL = "com.myadhan/notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "showFullScreenAdhan") {
                val prayerName = call.argument<String>("prayerName") ?: "صلاة"

                val intent = Intent(this, AdhanActivity::class.java).apply {
                    putExtra("prayerName", prayerName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP)
                }

                startActivity(intent)
                result.success("Adhan shown")
            } else {
                result.notImplemented()
            }
        }
    }
}
