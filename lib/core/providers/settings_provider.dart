import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  TtsVoiceMode _sentenceMode = TtsVoiceMode.auto;
  TtsVoiceMode _wordMode = TtsVoiceMode.offline;

  String? _elevenLabsApiKey;
  ElevenLabsVoice _elevenLabsVoice = ElevenLabsVoice.elisabeth;

  // New Gemini Variables
  String? _geminiApiKey;
  GeminiVoice _geminiVoice = GeminiVoice.zephyr;

  TtsVoiceMode get sentenceMode => _sentenceMode;
  TtsVoiceMode get wordMode => _wordMode;
  String? get elevenLabsApiKey => _elevenLabsApiKey;
  ElevenLabsVoice get elevenLabsVoice => _elevenLabsVoice;
  
  String? get geminiApiKey => _geminiApiKey;
  GeminiVoice get geminiVoice => _geminiVoice;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sentenceMode = TtsVoiceMode.values[prefs.getInt('sentence_mode') ?? 0];
    _wordMode = TtsVoiceMode.values[prefs.getInt('word_mode') ?? 1];
    
    _elevenLabsApiKey = prefs.getString('elevenlabs_api_key');
    _elevenLabsVoice = ElevenLabsVoice.values[prefs.getInt('elevenlabs_voice') ?? 2];

    // Load Gemini Settings
    _geminiApiKey = prefs.getString('gemini_api_key');
    _geminiVoice = GeminiVoice.values[prefs.getInt('gemini_voice') ?? 5]; // Default to zephyr

    _syncToService();
    notifyListeners();
  }

  void _syncToService() {
    TtsService.sentenceMode = _sentenceMode;
    TtsService.wordMode = _wordMode;
    
    TtsService.elevenLabsApiKey = _elevenLabsApiKey;
    TtsService.currentElevenLabsVoice = _elevenLabsVoice;

    TtsService.geminiApiKey = _geminiApiKey;
    TtsService.currentGeminiVoice = _geminiVoice;
  }

  Future<bool> updateMode(TtsVoiceMode mode, bool isWordSetting) async {
    if (mode == TtsVoiceMode.elevenlabs && (_elevenLabsApiKey == null || _elevenLabsApiKey!.isEmpty)) {
      return false;
    }
    // PREVENT selecting Gemini if no API key is present
    if (mode == TtsVoiceMode.gemini && (_geminiApiKey == null || _geminiApiKey!.isEmpty)) {
      return false;
    }

    try {
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
    } catch (e) {
      debugPrint("❌ Failed to send TTS mode update: $e");
      return false;
    }
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

  // New Gemini Config Updater
  Future<void> updateGeminiConfig(String key, GeminiVoice voice) async {
    _geminiApiKey = key;
    _geminiVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    await prefs.setInt('gemini_voice', voice.index);
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
      // Pass Gemini data to the overlay
      'gemini_api_key': _geminiApiKey ?? "",
      'gemini_voice_index': _geminiVoice.index,
    });
    notifyListeners();
  }
}