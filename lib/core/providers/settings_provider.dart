
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  TtsVoiceMode _currentTtsMode = TtsVoiceMode.elisabeth;
  TtsVoiceMode get currentTtsMode => _currentTtsMode;

  SettingsProvider() {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt('tts_mode_index') ?? TtsVoiceMode.elisabeth.index;
    _currentTtsMode = TtsVoiceMode.values[index];
    TtsService.currentMode = _currentTtsMode;
    notifyListeners();
  }

  Future<void> setTtsMode(TtsVoiceMode mode) async {
    _currentTtsMode = mode;
    TtsService.currentMode = mode;
    
    // Save to Disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tts_mode_index', mode.index);

    // Notify Overlay UI
    await FlutterOverlayWindow.shareData({
      'action': 'update_tts_mode',
      'mode_index': mode.index,
    });

    notifyListeners();
  }
}