package com.zaidjoapps.jajangangs

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var sounds: SoundPool? = null
    private var chime = 0
    private var loaded = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("jajan_announcements", getString(R.string.announcement_channel), NotificationManager.IMPORTANCE_HIGH)
            channel.description = getString(R.string.announcement_channel_description)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        sounds = SoundPool.Builder().setMaxStreams(1).setAudioAttributes(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        ).build().also { pool ->
            pool.setOnLoadCompleteListener { _, _, status -> loaded = status == 0 }
            try {
                assets.openFd("flutter_assets/assets/audio/jajan_chime.wav").use { chime = pool.load(it, 1) }
            } catch (_: Exception) { loaded = false }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "jajangangs/notification_sound")
            .setMethodCallHandler { call, result ->
                if (call.method == "play") {
                    val audio = getSystemService(AUDIO_SERVICE) as AudioManager
                    if (loaded && audio.ringerMode == AudioManager.RINGER_MODE_NORMAL) {
                        sounds?.play(chime, 0.65f, 0.65f, 1, 0, 1f)
                    }
                    result.success(null)
                } else result.notImplemented()
            }
    }
    override fun onDestroy() {
        sounds?.release()
        sounds = null
        loaded = false
        super.onDestroy()
    }
}
