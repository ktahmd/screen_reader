package com.example.screen_reader

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.screen_reader/capture"
    
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    
    private val REQUEST_CODE = 100
    private var pendingResult: MethodChannel.Result? = null

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
                "captureScreen" -> {
                    captureScreen(result)
                }
                "stopProjection" -> {
                    stopProjection()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)
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

    private fun stopProjection() {
        mediaProjection?.stop()
        mediaProjection = null
        val serviceIntent = Intent(this, ScreenCaptureForegroundService::class.java)
        stopService(serviceIntent)
    }

    private fun captureScreen(result: MethodChannel.Result) {
        if (mediaProjection == null) {
            result.error("NO_PERMISSION", "MediaProjection not initialized.", null)
            return
        }

        // Safe way to get screen size even when app is in the background
        val metrics = Resources.getSystem().displayMetrics
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )

        var captureHandled = false
        val handler = Handler(Looper.getMainLooper())

        // TIMEOUT FALLBACK: If screen is frozen, force fail after 1.5 seconds so UI doesn't spin forever
        handler.postDelayed({
            if (!captureHandled) {
                captureHandled = true
                imageReader?.setOnImageAvailableListener(null, null)
                virtualDisplay?.release()
                result.error("TIMEOUT", "Capture timed out", null)
            }
        }, 1500)

        // PROPER ASYNC LISTENER: Triggers exactly when frame is ready
        imageReader?.setOnImageAvailableListener({ reader ->
            if (captureHandled) return@setOnImageAvailableListener
            
            val image = reader.acquireLatestImage()
            if (image != null) {
                captureHandled = true
                handler.removeCallbacksAndMessages(null) // Cancel the timeout

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
                    val byteArray = stream.toByteArray()

                    image.close()
                    reader.setOnImageAvailableListener(null, null)
                    virtualDisplay?.release()
                    
                    result.success(byteArray) 
                } catch (e: Exception) {
                    image.close()
                    reader.setOnImageAvailableListener(null, null)
                    virtualDisplay?.release()
                    result.error("ERROR", e.message, null)
                }
            }
        }, handler)
    }
}