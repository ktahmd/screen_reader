import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/constants/overlay_actions.dart';
import '../models/tts_config_model.dart';
import 'tts/tts_service.dart';

class SettingsSyncService {
  /// Broadcasts settings. If the Overlay is dead, this fails silently (which is fine).
  static void broadcast(TtsSettingsModel settings) {
    try {
      FlutterOverlayWindow.shareData({
        'action': OverlayActions.updateTtsModes,
        ...settings.toMap(),
      }).catchError((_) {}); 
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  /// Updates the local memory.
  static void updateLocalState(Map<String, dynamic> data) {
    final settings = TtsSettingsModel.fromMap(data);
    TtsService.updateConfiguration(settings);
  }
}