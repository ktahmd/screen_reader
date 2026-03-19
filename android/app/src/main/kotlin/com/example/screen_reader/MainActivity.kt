package com.example.screen_reader

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.screen_reader/capture"
    private var mediaProjectionManager: MediaProjectionManager? = null
    private val REQUEST_CODE = 100
    private var pendingResult: MethodChannel.Result? = null

    // This keeps the Flutter Engine from being destroyed when the app is swiped
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    pendingResult = result
                    val serviceIntent = Intent(this, ScreenCaptureForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    startActivityForResult(mediaProjectionManager?.createScreenCaptureIntent(), REQUEST_CODE)
                }
                "stopProjection" -> {
                    ScreenCaptureManager.stopProjection()
                    val serviceIntent = Intent(this, ScreenCaptureForegroundService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // STORE TOKEN IN THE GLOBAL MANAGER
                ScreenCaptureManager.mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)
                pendingResult?.success(true) 
            } else {
                val serviceIntent = Intent(this, ScreenCaptureForegroundService::class.java)
                stopService(serviceIntent)
                pendingResult?.success(false) 
            }
            pendingResult = null
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}