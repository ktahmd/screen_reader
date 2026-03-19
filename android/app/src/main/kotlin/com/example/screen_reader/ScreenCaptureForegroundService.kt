package com.example.screen_reader

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

object ScreenCaptureManager {
    var mediaProjection: MediaProjection? = null
    var virtualDisplay: VirtualDisplay? = null
    var imageReader: ImageReader? = null

    fun captureScreen(result: MethodChannel.Result) {
        val projection = mediaProjection
            if (projection == null) {
                result.error("NEED_PERMISSION", "Permission lost", null)
                return
            }

            // REGISTER CALLBACK to detect if the token dies from the outside
            projection.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    super.onStop()
                    mediaProjection = null // Token is dead, clear it
                }
            }, Handler(Looper.getMainLooper()))

            val metrics = Resources.getSystem().displayMetrics
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val density = metrics.densityDpi

            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            
            try {
                // THIS IS WHERE THE ERROR HAPPENS if another app is capturing
                virtualDisplay = projection.createVirtualDisplay(
                    "ScreenCapture", width, height, density,
                    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    imageReader?.surface, null, null
                )
            } catch (e: SecurityException) {
                // ANOTHER APP TOOK CONTROL
                mediaProjection = null 
                result.error("PROJECTION_REVOKED", "Another app is using screen capture. Please restart the power button.", null)
                return
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
                return
            }

        var captureHandled = false
        val handler = Handler(Looper.getMainLooper())

        handler.postDelayed({
            if (!captureHandled) {
                captureHandled = true
                virtualDisplay?.release()
                result.error("TIMEOUT", "Capture timed out", null)
            }
        }, 2000)

        imageReader?.setOnImageAvailableListener({ reader ->
            if (captureHandled) return@setOnImageAvailableListener
            val image = reader.acquireLatestImage()
            if (image != null) {
                captureHandled = true
                handler.removeCallbacksAndMessages(null)
                try {
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * width
                    val bitmap = Bitmap.createBitmap(width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888)
                    bitmap.copyPixelsFromBuffer(buffer)
                    val croppedBitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height)
                    val stream = ByteArrayOutputStream()
                    croppedBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    result.success(stream.toByteArray())
                    image.close()
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                } finally {
                    virtualDisplay?.release()
                }
            }
        }, handler)
    }

    fun stopProjection() {
        mediaProjection?.stop()
        mediaProjection = null
        virtualDisplay?.release()
        virtualDisplay = null
    }
}

class ScreenCaptureForegroundService : Service() {
    private var flutterEngine: FlutterEngine? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        // 1. Initialize background engine
        flutterEngine = FlutterEngine(this)
        io.flutter.plugins.GeneratedPluginRegistrant.registerWith(flutterEngine!!)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "com.screen_reader/capture").setMethodCallHandler { call, result ->
            when (call.method) {
            "captureScreen" -> ScreenCaptureManager.captureScreen(result)
            "openApp" -> {
                // This code works inside a Service too!
                val intent = Intent(applicationContext, MainActivity::class.java)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                result.success(true)
            }
            else -> result.notImplemented()
        }
        }

        val loader = FlutterInjector.instance().flutterLoader()
        loader.ensureInitializationComplete(this, null)
        val entryPoint = DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "backgroundMain")
        flutterEngine?.dartExecutor?.executeDartEntrypoint(entryPoint)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val channelId = "ScreenCaptureChannel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Screen Capture", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Screen Reader Active")
            .setContentText("Listening for capture requests...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true) // Makes notification un-swipeable
            .build()

        startForeground(1, notification)
        return START_STICKY // CRITICAL: Restarts service if process is killed
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // This is called when the user swipes the app away.
        // We do NOTHING here to keep the service running.
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        flutterEngine?.destroy()
        ScreenCaptureManager.stopProjection()
        super.onDestroy()
    }
}