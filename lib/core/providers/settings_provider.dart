import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  TtsVoiceMode _sentenceMode = TtsVoiceMode.auto;
  TtsVoiceMode _wordMode = TtsVoiceMode.offline;

  TtsVoiceMode get sentenceMode => _sentenceMode;
  TtsVoiceMode get wordMode => _wordMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sentenceMode = TtsVoiceMode.values[prefs.getInt('sentence_mode') ?? 0];
    _wordMode = TtsVoiceMode
        .values[prefs.getInt('word_mode') ?? 1]; // Default word to offline

    // Sync to Service
    TtsService.sentenceMode = _sentenceMode;
    TtsService.wordMode = _wordMode;
    notifyListeners();
  }

  Future<void> updateMode(TtsVoiceMode mode, bool isWordSetting) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isWordSetting) {
        _wordMode = mode;
        TtsService.wordMode = mode;
        await prefs.setInt('word_mode', mode.index);
      } else {
        _sentenceMode = mode;
        TtsService.sentenceMode = mode;
        await prefs.setInt('sentence_mode', mode.index);
      }

      // Ping Overlay
      await FlutterOverlayWindow.shareData({
        'action': 'update_tts_modes',
        'sentence_index': _sentenceMode.index,
        'word_index': _wordMode.index,
      });
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Failed to send TTS mode update to overlay: $e");
    }
  }
}
