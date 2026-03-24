// lib/services/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/pref_keys.dart';
import 'tts/tts_service_core.dart';


class LocalStorageService {
  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  // --- Getters ---
  TtsVoiceMode getSentenceMode() {
    final index = _prefs.getInt(PrefKeys.sentenceMode) ?? TtsVoiceMode.auto.index;
    return TtsVoiceMode.values[index];
  }

  TtsVoiceMode getWordMode() {
    final index = _prefs.getInt(PrefKeys.wordMode) ?? TtsVoiceMode.offline.index;
    return TtsVoiceMode.values[index];
  }

  String? getElevenLabsApiKey() => _prefs.getString(PrefKeys.elevenLabsApiKey);
  String getElevenLabsModelId() => _prefs.getString(PrefKeys.elevenLabsModelId) ?? "eleven_flash_v2_5";
  String getElevenLabsVoiceId() => _prefs.getString(PrefKeys.elevenLabsVoiceId) ?? "pNInz6obpgDQGcFmaJgB";
  
  String? getGeminiApiKey() => _prefs.getString(PrefKeys.geminiApiKey);
  String getGeminiModelId() => _prefs.getString(PrefKeys.geminiModelId) ?? "gemini-2.5-flash";
  GeminiVoice getGeminiVoice() {
      final index = _prefs.getInt(PrefKeys.geminiVoice) ?? GeminiVoice.zephyr.index;
      return GeminiVoice.values[index];
  }


  // --- Setters ---
  Future<void> saveSentenceMode(TtsVoiceMode mode) async {
    await _prefs.setInt(PrefKeys.sentenceMode, mode.index);
  }

  Future<void> saveWordMode(TtsVoiceMode mode) async {
    await _prefs.setInt(PrefKeys.wordMode, mode.index);
  }
  
  Future<void> saveElevenLabsConfig(String key, String modelId, String voiceId) async {
    await _prefs.setString(PrefKeys.elevenLabsApiKey, key);
    await _prefs.setString(PrefKeys.elevenLabsModelId, modelId);
    await _prefs.setString(PrefKeys.elevenLabsVoiceId, voiceId);
  }

  Future<void> saveGeminiConfig(String key, String modelId, GeminiVoice voice) async {
    await _prefs.setString(PrefKeys.geminiApiKey, key);
    await _prefs.setString(PrefKeys.geminiModelId, modelId);
    await _prefs.setInt(PrefKeys.geminiVoice, voice.index);
  }
}