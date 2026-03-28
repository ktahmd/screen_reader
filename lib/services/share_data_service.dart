import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/constants/overlay_actions.dart';
import '../models/ocr_word_model.dart';
import '../models/tts_config_model.dart';

class OverlayShareDataService {
  /// Stream to listen for incoming messages in any isolate
  static Stream<dynamic> get messageStream => FlutterOverlayWindow.overlayListener;

  // --- Outgoing Messages (From Main/Overlay to Background) ---

  static Future<void> requestCapture() async {
    await _send({ 'action': OverlayActions.capture });
  }

  static Future<void> requestOpenApp() async {
    await _send({ 'action': OverlayActions.openAppRequest });
  }

  // --- Outgoing Messages (From Main to Overlay) ---

  static Future<void> broadcastSettings(TtsSettingsModel settings) async {
    await _send({
      'action': OverlayActions.updateTtsModes,
      ...settings.toMap(),
    });
  }

  // --- Outgoing Messages (From Background to Overlay) ---

  static Future<void> sendOcrResults(List<OcrWord> words) async {
    final serializableWords = words.map((w) => {
      'text': w.text,
      'x': w.boundingBox.left, 'y': w.boundingBox.top,
      'w': w.boundingBox.width, 'h': w.boundingBox.height,
    }).toList();

    await _send({
      'action': OverlayActions.result,
      'words': serializableWords,
    });
  }

  static Future<void> sendError(String errorCode) async {
    await _send({
      'action': OverlayActions.error,
      'errorCode': errorCode,
    });
  }

  // --- Private Helper ---
  static Future<void> _send(Map<String, dynamic> data) async {
    try {
      await FlutterOverlayWindow.shareData(data);
    } catch (e) {
      debugPrint("Communication Error: $e");
    }
  }
}