import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:screen_reader/core/services/tts_service.dart';
import 'core/helpers/theme_helper.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/overlay_provider.dart';
import 'core/services/ocr_service.dart';
import 'core/services/screen_capture_service.dart';
import 'features/homeScreen.dart';
import 'overlay/overlay.dart';
import 'dart:async';

/// Entry point for the background isolate used by the overlay window.
/// 
/// This function listens for overlay events and handles actions such as
/// screen capture, OCR processing, and communication with the main app.
/// It is marked with `@pragma("vm:entry-point")` to ensure it can be invoked
/// by the Flutter engine in a background context.
@pragma("vm:entry-point")
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();

  // Store the subscription so it can be cancelled if needed
  StreamSubscription? overlaySubscription;

  overlaySubscription = FlutterOverlayWindow.overlayListener.listen((event) async {
    if (event is Map) {
      final action = event['action'];
      if (action is String) {
        switch (action) {
          case 'capture':
            debugPrint("🤖 BACKGROUND ENGINE: Taking screenshot...");
            try {
              final bytes = await ScreenCaptureService.captureScreen();
              if (bytes != null) {
                final wordData = await OcrService.extractTextDetailed(bytes);
                FlutterOverlayWindow.shareData({'action': 'result', 'words': wordData});
              } else {
                FlutterOverlayWindow.shareData({'action': 'error'});
              }
            } on PlatformException catch (e) {
              FlutterOverlayWindow.shareData({
                'action': 'error',
                'errorCode': e.code,
              });
            } catch (e) {
              debugPrint("❌ BACKGROUND ENGINE ERROR: $e");
              FlutterOverlayWindow.shareData(
                  {'action': 'error', 'errorCode': e.toString()});
            }
            break;
          case 'open_app_request':
            try {
              await ScreenCaptureService.openApp();
            } catch (e) {
              debugPrint("❌ BACKGROUND ENGINE ERROR (openApp): $e");
              FlutterOverlayWindow.shareData(
                  {'action': 'error', 'errorCode': e.toString()});
            }
            break;
          case 'update_tts_modes':
            final sentenceIndex = event['sentence_index'] as int;
            final wordIndex = event['word_index'] as int;
            
            final String apiKey = event['api_key'] as String;
            final String elModelId = event['el_model_id'] as String;
            final voiceIndex = event['voice_index'] as int;
            
            final String geminiKey = event['gemini_api_key'] as String;
            final String gemModelId = event['gemini_model_id'] as String;
            final geminiVoiceIdx = event['gemini_voice_index'] as int;
            
            TtsService.sentenceMode = TtsVoiceMode.values[sentenceIndex];
            TtsService.wordMode = TtsVoiceMode.values[wordIndex];
            
            TtsService.elevenLabsApiKey = apiKey.isEmpty ? null : apiKey;
            TtsService.elevenLabsModelId = elModelId;
            TtsService.currentElevenLabsVoice = ElevenLabsVoice.values[voiceIndex];

            TtsService.geminiApiKey = geminiKey.isEmpty ? null : geminiKey;
            TtsService.geminiModelId = gemModelId;
            TtsService.currentGeminiVoice = GeminiVoice.values[geminiVoiceIdx];
            break;
          case 'dispose_listener':
            // Example: cancel the subscription if a dispose action is received
            await overlaySubscription?.cancel();
            overlaySubscription = null;
            break;
          default:
            // optional: handle unknown actions
        }
      }
    }
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OverlayProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => SettingsProvider(), lazy: false),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            // showPerformanceOverlay: true,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: appTheme(Brightness.light),
            darkTheme: appTheme(Brightness.dark),
            home: const HomeScreen(),
          );
        },
      ),
    ),
  );
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    // showPerformanceOverlay: true,
    debugShowCheckedModeBanner: false,
    home: OverlayContentWidget(),
  ));
}
