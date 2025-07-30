package com.example.myadhan

import android.content.Context
import android.media.MediaPlayer

object AdhanPlayer {
    private var mediaPlayer: MediaPlayer? = null

    fun play(context: Context) {
        if (mediaPlayer == null) {
            mediaPlayer = MediaPlayer.create(context, R.raw.adhan1)
            mediaPlayer?.setOnCompletionListener {
                stop()
            }
            mediaPlayer?.start()
        }
    }

    fun stop() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    fun isPlaying(): Boolean {
        return mediaPlayer?.isPlaying == true
    }
}