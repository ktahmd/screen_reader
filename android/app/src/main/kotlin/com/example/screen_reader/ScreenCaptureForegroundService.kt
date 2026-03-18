package com.example.screen_reader 

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ScreenCaptureForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val channelId = "ScreenCaptureChannel"
        
        // 1. Create the Notification Channel (Required for Android 8+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, 
                "Screen Capture", 
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        // 2. Build the sticky notification
        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Screen Reader Active")
            .setContentText("Ready to extract text from screen.")
            .setSmallIcon(android.R.drawable.ic_menu_camera) // Built-in Android icon
            .build()

        // 3. Start the service as a "MediaProjection" type
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(1, notification)
        }

        return START_NOT_STICKY
    }
}