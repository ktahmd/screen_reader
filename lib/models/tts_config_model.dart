import '../services/tts/tts_service_core.dart';

class TtsSettingsModel {
  final TtsVoiceMode sentenceMode;
  final TtsVoiceMode wordMode;
  
  final String? elevenLabsApiKey;
  final String elevenLabsModelId;
  final String elevenLabsVoiceId;

  final String? geminiApiKey;
  final String geminiModelId;
  final GeminiVoice geminiVoice;

  TtsSettingsModel({
    required this.sentenceMode,
    required this.wordMode,
    this.elevenLabsApiKey,
    required this.elevenLabsModelId,
    required this.elevenLabsVoiceId,
    this.geminiApiKey,
    required this.geminiModelId,
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
      'gemini_model_id': geminiModelId,
      'gemini_voice_index': geminiVoice.index,
    };
  }

  factory TtsSettingsModel.fromMap(Map<String, dynamic> map) {
    return TtsSettingsModel(
      sentenceMode: TtsVoiceMode.values[map['sentence_index'] as int],
      wordMode: TtsVoiceMode.values[map['word_index'] as int],
      elevenLabsApiKey: (map['api_key'] as String).isEmpty ? null : map['api_key'],
      elevenLabsModelId: map['el_model_id'] as String,
      elevenLabsVoiceId: map['el_voice_id'] as String,
      geminiApiKey: (map['gemini_api_key'] as String).isEmpty ? null : map['gemini_api_key'],
      geminiModelId: map['gemini_model_id'] as String,
      geminiVoice: GeminiVoice.values[map['gemini_voice_index'] as int],
    );
  }
}