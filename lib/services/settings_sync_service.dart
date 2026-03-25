import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/constants/overlay_actions.dart';
import '../models/tts_config_model.dart';
import 'tts/tts_service.dart';

class SettingsSyncService {
  /// 1. Sends settings from the Main App to the Background/Overlay
  static Future<void> broadcast(TtsSettingsModel settings) async {
    await FlutterOverlayWindow.shareData({
      'action': OverlayActions.updateTtsModes,
      ...settings.toMap(),
    });
  }

  /// 2. Receives settings and updates the local Isolate's TTS Engine
  static void updateLocalState(Map<String, dynamic> data) {
    final settings = TtsSettingsModel.fromMap(data);
    TtsService.updateConfiguration(settings);
  }
}