import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/pref_keys.dart';
import '../core/constants/default_settings.dart';
import '../models/tts_config_model.dart';
import 'tts/tts_service.dart';

class LocalStorageService {
  final SharedPreferences _prefs;
  LocalStorageService(this._prefs);

  Future<void> reloadCache() async => await _prefs.reload();

  // ================= GETTERS =================
  TtsSettingsModel getAllSettings() {
    return TtsSettingsModel(
      sentenceMode: getSentenceMode(),
      wordMode: getWordMode(),
      elevenLabsApiKey: getElevenLabsApiKey(),
      elevenLabsModelId: getElevenLabsModelId(),
      elevenLabsVoiceId: getElevenLabsVoiceId(),
      geminiApiKey: getGeminiApiKey(),
      geminiModelTextToSpeechId: getGeminiModelTextToSpeechId(),
      geminiVoice: getGeminiVoice(),
    );
  }
  // --- TTS Engine Modes ---
  TtsVoiceMode getSentenceMode() {
    final index =
        _prefs.getInt(PrefKeys.sentenceMode) ?? TtsVoiceMode.auto.index;
    return TtsVoiceMode.values[index];
  }

  TtsVoiceMode getWordMode() {
    final index =
        _prefs.getInt(PrefKeys.wordMode) ?? TtsVoiceMode.offline.index;
    return TtsVoiceMode.values[index];
  }

  // --- ElevenLabs Config ---
  String? getElevenLabsApiKey() => _prefs.getString(PrefKeys.elevenLabsApiKey);

  String getElevenLabsModelId() =>
      _prefs.getString(PrefKeys.elevenLabsModelId) ??
      DefaultSettings.elevenLabsModelId;

  String getElevenLabsVoiceId() =>
      _prefs.getString(PrefKeys.elevenLabsVoiceId) ??
      DefaultSettings.elevenLabsVoiceId;

  // --- Gemini Config ---
  String? getGeminiApiKey() => _prefs.getString(PrefKeys.geminiApiKey);

  // UPDATED: Using the new naming convention
  String getGeminiModelTextToSpeechId() =>
      _prefs.getString(PrefKeys.geminiModelTextToSpeechId) ??
      DefaultSettings.geminiModelTextToSpeechId;

  // REFACTORED: Now returns a String (voice name) instead of an enum index
  String getGeminiVoice() {
    debugPrint("${ _prefs.getString(PrefKeys.geminiVoice)}");
    return _prefs.getString(PrefKeys.geminiVoice) ??
        DefaultSettings.geminiDefaultVoice;
  }

  // ================= SETTERS =================

  Future<void> saveSentenceMode(TtsVoiceMode mode) async {
    await _prefs.setInt(PrefKeys.sentenceMode, mode.index);
  }

  Future<void> saveWordMode(TtsVoiceMode mode) async {
    await _prefs.setInt(PrefKeys.wordMode, mode.index);
  }

  Future<void> saveElevenLabsConfig(
      String key, String modelId, String voiceId) async {
    await _prefs.setString(PrefKeys.elevenLabsApiKey, key);
    await _prefs.setString(PrefKeys.elevenLabsModelId, modelId);
    await _prefs.setString(PrefKeys.elevenLabsVoiceId, voiceId);
  }

  // UPDATED: Parameters now use String for modelId and voice
  Future<void> saveGeminiConfig(
      String key, String modelId, String voice) async {
    await _prefs.setString(PrefKeys.geminiApiKey, key);
    await _prefs.setString(PrefKeys.geminiModelTextToSpeechId, modelId);
    await _prefs.setString(PrefKeys.geminiVoice, voice);
  }
}
