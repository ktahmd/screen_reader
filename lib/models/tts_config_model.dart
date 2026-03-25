import '../core/constants/default_settings.dart';
import '../services/tts/tts_service.dart';

class TtsSettingsModel {
  final TtsVoiceMode sentenceMode;
  final TtsVoiceMode wordMode;

  final String? elevenLabsApiKey;
  final String elevenLabsModelId;
  final String elevenLabsVoiceId;

  final String? geminiApiKey;
  final String geminiModelTextToSpeechId;
  final String geminiVoice;

  TtsSettingsModel({
    required this.sentenceMode,
    required this.wordMode,
    this.elevenLabsApiKey,
    required this.elevenLabsModelId,
    required this.elevenLabsVoiceId,
    this.geminiApiKey,
    required this.geminiModelTextToSpeechId,
    required this.geminiVoice,
  });

  Map<String, dynamic> toMap() {
    return {
      'sentence_index': sentenceMode.index,
      'word_index': wordMode.index,
      'api_key': elevenLabsApiKey ?? "",
      'el_model_id': elevenLabsModelId,
      'el_voice_id': elevenLabsVoiceId,
      'gemini_api_key': geminiApiKey ?? "",
      'gemini_model_tts_id': geminiModelTextToSpeechId,
      'gemini_voice': geminiVoice,
    };
  }

  factory TtsSettingsModel.fromMap(Map<String, dynamic> map) {
    return TtsSettingsModel(
      sentenceMode: TtsVoiceMode.values[map['sentence_index'] as int],
      wordMode: TtsVoiceMode.values[map['word_index'] as int],
      elevenLabsApiKey:
          (map['api_key'] as String).isEmpty ? null : map['api_key'],
      elevenLabsModelId: map['el_model_id'] as String,
      elevenLabsVoiceId: map['el_voice_id'] as String,
      geminiApiKey: (map['gemini_api_key'] as String).isEmpty
          ? null
          : map['gemini_api_key'],
      geminiModelTextToSpeechId: map['gemini_model_tts_id'] as String? ??
          DefaultSettings.geminiModelTextToSpeechId,
      geminiVoice: map['gemini_voice'] ?? DefaultSettings.geminiDefaultVoice,
    );
  }

  void applyToTtsService() {
    TtsService.sentenceMode = sentenceMode;
    TtsService.wordMode = wordMode;
    TtsService.elevenLabsApiKey = elevenLabsApiKey;
    TtsService.elevenLabsModelId = elevenLabsModelId;
    TtsService.currentElevenLabsVoiceId = elevenLabsVoiceId;
    TtsService.geminiApiKey = geminiApiKey;
    TtsService.geminiModelTextToSpeechId = geminiModelTextToSpeechId;
    TtsService.currentGeminiVoice = geminiVoice;
  }
}