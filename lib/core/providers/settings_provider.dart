import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  TtsVoiceMode _sentenceMode = TtsVoiceMode.auto;
  TtsVoiceMode _wordMode = TtsVoiceMode.offline;
  
  String? _elevenLabsApiKey;
  ElevenLabsVoice _elevenLabsVoice = ElevenLabsVoice.elisabeth;

  TtsVoiceMode get sentenceMode => _sentenceMode;
  TtsVoiceMode get wordMode => _wordMode;
  String? get elevenLabsApiKey => _elevenLabsApiKey;
  ElevenLabsVoice get elevenLabsVoice => _elevenLabsVoice;

  SettingsProvider() { _loadSettings(); }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sentenceMode = TtsVoiceMode.values[prefs.getInt('sentence_mode') ?? 0];
    _wordMode = TtsVoiceMode.values[prefs.getInt('word_mode') ?? 1];
    _elevenLabsApiKey = prefs.getString('elevenlabs_api_key');
    _elevenLabsVoice = ElevenLabsVoice.values[prefs.getInt('elevenlabs_voice') ?? 2]; 

    _syncToService();
    notifyListeners();
  }

  void _syncToService() {
    TtsService.sentenceMode = _sentenceMode;
    TtsService.wordMode = _wordMode;
    TtsService.elevenLabsApiKey = _elevenLabsApiKey;
    TtsService.currentElevenLabsVoice = _elevenLabsVoice;
  }

  Future<bool> updateMode(TtsVoiceMode mode, bool isWordSetting) async {
    // PREVENT selecting ElevenLabs if no API key is present
    if (mode == TtsVoiceMode.elevenlabs && (_elevenLabsApiKey == null || _elevenLabsApiKey!.isEmpty)) {
      return false; 
    }

    final prefs = await SharedPreferences.getInstance();
    if (isWordSetting) {
      _wordMode = mode;
      await prefs.setInt('word_mode', mode.index);
    } else {
      _sentenceMode = mode;
      await prefs.setInt('sentence_mode', mode.index);
    }
    _syncToService();
    _pingOverlay();
    return true;
  }

  Future<void> updateElevenLabsConfig(String key, ElevenLabsVoice voice) async {
    _elevenLabsApiKey = key;
    _elevenLabsVoice = voice;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elevenlabs_api_key', key);
    await prefs.setInt('elevenlabs_voice', voice.index);
    
    _syncToService();
    _pingOverlay();
  }

  Future<void> _pingOverlay() async {
    await FlutterOverlayWindow.shareData({
      'action': 'update_tts_modes',
      'sentence_index': _sentenceMode.index,
      'word_index': _wordMode.index,
      'api_key': _elevenLabsApiKey ?? "",
      'voice_index': _elevenLabsVoice.index,
    });
    notifyListeners();
  }
}