package com.example.screen_reader

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // 1. Create the single, global Flutter Engine
        val flutterEngine = FlutterEngine(this)

        // 2. Start running the Dart code immediately in the background
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // 3. Cache it so MainActivity can find it when opened
        FlutterEngineCache.getInstance().put("main_engine_cache", flutterEngine)
    }
}