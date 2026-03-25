import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'core/constants/overlay_actions.dart';
import 'models/ocr_word_model.dart';
import 'services/ocr_service.dart';
import 'services/platform_channel_service.dart';
import 'services/settings_sync_service.dart';

class BackgroundIsolateHandler {
  static void start() {
    final platformService = PlatformChannelService();

    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is! Map<String, dynamic>) return;
      
      final action = event['action'];
      
      switch (action) {
        case OverlayActions.capture:
          _handleCapture(platformService);
          break;
        case OverlayActions.openAppRequest:
          platformService.openApp();
          break;
        case OverlayActions.updateTtsModes:
          _handleTtsUpdate(event);
          break;
      }
    });
  }

  static Future<void> _handleCapture(PlatformChannelService service) async {
    debugPrint("🤖 BACKGROUND: Capturing screen...");
    try {
      final bytes = await service.captureScreen();
      if (bytes != null) {
        final List<OcrWord> wordData = await OcrService.extractTextDetailed(bytes);
        
        final serializableWords = wordData.map((w) => {
          'text': w.text,
          'x': w.boundingBox.left, 'y': w.boundingBox.top,
          'w': w.boundingBox.width, 'h': w.boundingBox.height,
        }).toList();

        FlutterOverlayWindow.shareData({'action': OverlayActions.result, 'words': serializableWords});
      } else {
        FlutterOverlayWindow.shareData({'action': OverlayActions.error, 'errorCode': 'CAPTURE_FAILED'});
      }
    } catch (e) {
      debugPrint("❌ BACKGROUND ERROR: $e");
      FlutterOverlayWindow.shareData({'action': OverlayActions.error, 'errorCode': e.toString()});
    }
  }

  static void _handleTtsUpdate(Map<String, dynamic> data) {
    SettingsSyncService.updateLocalState(data);
  }
}
