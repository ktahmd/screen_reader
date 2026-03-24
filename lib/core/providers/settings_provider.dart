import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class SettingsProvider extends ChangeNotifier {
  TtsVoiceMode _sentenceMode = TtsVoiceMode.auto;
  TtsVoiceMode _wordMode = TtsVoiceMode.offline;

  String? _elevenLabsApiKey;
  String _elevenLabsModelId = "eleven_flash_v2_5";
  String _elevenLabsVoiceId = "pNInz6obpgDQGcFmaJgB"; 

  String? _geminiApiKey;
  String _geminiModelId = "gemini-2.5-flash";
  GeminiVoice _geminiVoice = GeminiVoice.zephyr;

  TtsVoiceMode get sentenceMode => _sentenceMode;
  TtsVoiceMode get wordMode => _wordMode;
  
  String? get elevenLabsApiKey => _elevenLabsApiKey;
  String get elevenLabsModelId => _elevenLabsModelId;
  String get elevenLabsVoiceId => _elevenLabsVoiceId; 
  
  String? get geminiApiKey => _geminiApiKey;
  String get geminiModelId => _geminiModelId;
  GeminiVoice get geminiVoice => _geminiVoice;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sentenceMode = TtsVoiceMode.values[prefs.getInt('sentence_mode') ?? 0];
    _wordMode = TtsVoiceMode.values[prefs.getInt('word_mode') ?? 1];
    
    _elevenLabsApiKey = prefs.getString('elevenlabs_api_key');
    _elevenLabsModelId = prefs.getString('elevenlabs_model_id') ?? "eleven_flash_v2_5";
    _elevenLabsVoiceId = prefs.getString('elevenlabs_voice_id') ?? "pNInz6obpgDQGcFmaJgB";

    _geminiApiKey = prefs.getString('gemini_api_key');
    _geminiModelId = prefs.getString('gemini_model_id') ?? "gemini-2.5-flash";
    _geminiVoice = GeminiVoice.values[prefs.getInt('gemini_voice') ?? 5];

    _syncToService();
    notifyListeners();
  }

  void _syncToService() {
    TtsService.sentenceMode = _sentenceMode;
    TtsService.wordMode = _wordMode;
    
    TtsService.elevenLabsApiKey = _elevenLabsApiKey;
    TtsService.elevenLabsModelId = _elevenLabsModelId;
    TtsService.currentElevenLabsVoiceId = _elevenLabsVoiceId; 

    TtsService.geminiApiKey = _geminiApiKey;
    TtsService.geminiModelId = _geminiModelId;
    TtsService.currentGeminiVoice = _geminiVoice;
  }

  Future<bool> updateMode(TtsVoiceMode mode, bool isWordSetting) async {
    if (mode == TtsVoiceMode.elevenlabs && (_elevenLabsApiKey == null || _elevenLabsApiKey!.isEmpty)) return false;
    if (mode == TtsVoiceMode.gemini && (_geminiApiKey == null || _geminiApiKey!.isEmpty)) return false;

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
      return false;
    }
  }

  Future<void> updateElevenLabsConfig(String key, String modelId, String voiceId) async {
    _elevenLabsApiKey = key;
    _elevenLabsModelId = modelId;
    _elevenLabsVoiceId = voiceId;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elevenlabs_api_key', key);
    await prefs.setString('elevenlabs_model_id', modelId);
    await prefs.setString('elevenlabs_voice_id', voiceId);
    
    _syncToService();
    _pingOverlay();
  }

  Future<void> updateGeminiConfig(String key, String modelId, GeminiVoice voice) async {
    _geminiApiKey = key;
    _geminiModelId = modelId;
    _geminiVoice = voice;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    await prefs.setString('gemini_model_id', modelId);
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
      'el_model_id': _elevenLabsModelId,
      'el_voice_id': _elevenLabsVoiceId, 
      
      'gemini_api_key': _geminiApiKey ?? "",
      'gemini_model_id': _geminiModelId,
      'gemini_voice_index': _geminiVoice.index,
    });
    notifyListeners();
  }
}