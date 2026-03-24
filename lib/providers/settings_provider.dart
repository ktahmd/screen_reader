import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/constants/overlay_actions.dart';
import '../models/tts_config_model.dart';
import '../services/local_storage_service.dart';
import '../services/tts/tts_service.dart'; 

class SettingsProvider extends ChangeNotifier {
  final LocalStorageService _storageService;

  late TtsVoiceMode _sentenceMode;
  late TtsVoiceMode _wordMode;
  String? _elevenLabsApiKey;
  late String _elevenLabsModelId;
  late String _elevenLabsVoiceId;
  String? _geminiApiKey;
  late String _geminiModelTextToSpeechId;
  late String _geminiVoice; 

  TtsVoiceMode get sentenceMode => _sentenceMode;
  TtsVoiceMode get wordMode => _wordMode;
  String? get elevenLabsApiKey => _elevenLabsApiKey;
  String get elevenLabsModelId => _elevenLabsModelId;
  String get elevenLabsVoiceId => _elevenLabsVoiceId;
  String? get geminiApiKey => _geminiApiKey;
  String get geminiModelTextToSpeechId => _geminiModelTextToSpeechId;
  String get geminiVoice => _geminiVoice;

  SettingsProvider(this._storageService) {
    _loadSettings();
  }

  void _loadSettings() {
    _sentenceMode = _storageService.getSentenceMode();
    _wordMode = _storageService.getWordMode();
    
    _elevenLabsApiKey = _storageService.getElevenLabsApiKey();
    _elevenLabsModelId = _storageService.getElevenLabsModelId();
    _elevenLabsVoiceId = _storageService.getElevenLabsVoiceId();

    _geminiApiKey = _storageService.getGeminiApiKey();
    _geminiModelTextToSpeechId = _storageService.getGeminiModelTextToSpeechId();
    _geminiVoice = _storageService.getGeminiVoice();

    _syncToStaticTtsService();
    notifyListeners();
  }
  
  void _syncToStaticTtsService() {
    TtsService.sentenceMode = _sentenceMode;
    TtsService.wordMode = _wordMode;
    TtsService.elevenLabsApiKey = _elevenLabsApiKey;
    TtsService.elevenLabsModelId = _elevenLabsModelId;
    TtsService.currentElevenLabsVoiceId = _elevenLabsVoiceId;
    TtsService.geminiApiKey = _geminiApiKey;
    TtsService.geminiModelTextToSpeechId = _geminiModelTextToSpeechId;
    TtsService.currentGeminiVoice = _geminiVoice;
  }

  Future<bool> updateMode(TtsVoiceMode mode, bool isWordSetting) async {
    if (mode == TtsVoiceMode.elevenlabs && (_elevenLabsApiKey == null || _elevenLabsApiKey!.isEmpty)) return false;
    if (mode == TtsVoiceMode.gemini && (_geminiApiKey == null || _geminiApiKey!.isEmpty)) return false;

    if (isWordSetting) {
      _wordMode = mode;
      await _storageService.saveWordMode(mode);
    } else {
      _sentenceMode = mode;
      await _storageService.saveSentenceMode(mode);
    }

    _syncToStaticTtsService();
    _pingOverlay();
    notifyListeners();
    return true;
  }
  
  Future<void> updateElevenLabsConfig(String key, String modelId, String voiceId) async {
    _elevenLabsApiKey = key;
    _elevenLabsModelId = modelId;
    _elevenLabsVoiceId = voiceId;

    await _storageService.saveElevenLabsConfig(key, modelId, voiceId);
    
    _syncToStaticTtsService();
    _pingOverlay();
    notifyListeners();
  }
  
  Future<void> updateGeminiConfig(String key, String modelId, String voice) async {
    _geminiApiKey = key;
    _geminiModelTextToSpeechId = modelId;
    _geminiVoice = voice;

    await _storageService.saveGeminiConfig(key, modelId, voice);
    
    _syncToStaticTtsService();
    _pingOverlay();
    notifyListeners();
  }

  Future<void> _pingOverlay() async {
    final settingsModel = TtsSettingsModel(
      sentenceMode: _sentenceMode,
      wordMode: _wordMode,
      elevenLabsApiKey: _elevenLabsApiKey,
      elevenLabsModelId: _elevenLabsModelId,
      elevenLabsVoiceId: _elevenLabsVoiceId,
      geminiApiKey: _geminiApiKey,
      geminiModelTextToSpeechId: _geminiModelTextToSpeechId,
      geminiVoice: _geminiVoice,
    );
    
    await FlutterOverlayWindow.shareData({
      'action': OverlayActions.updateTtsModes,
      ...settingsModel.toMap(),
    });
  }
}