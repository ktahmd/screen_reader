import '../../models/voices/gemini_voice_model.dart';

class DefaultSettings {
  // ElevenLabs Defaults
  static const String elevenLabsModelId = "eleven_flash_v2_5";
  static const String elevenLabsVoiceId = "pNInz6obpgDQGcFmaJgB"; 

  // Gemini Defaults
  static const String geminiModelTextToSpeechId = "gemini-2.5-flash-preview-tts";
  static const String geminiModelId = "gemini-3.1-flash-preview";
  static const String geminiDefaultVoice = "zephyr"; 
}
class GeminiVoices {
  static const List<GeminiVoiceModel> all = [
    GeminiVoiceModel(id: "zephyr", name: "Zephyr", description: "Femme-Bright"),
    GeminiVoiceModel(id: "puck", name: "Puck", description: "Homme-Upbeat"),
    GeminiVoiceModel(id: "charon", name: "Charon", description: "Homme-Informative"),
    GeminiVoiceModel(id: "kore", name: "Kore", description: "Femme-Firm"),
    GeminiVoiceModel(id: "fenrir", name: "Fenrir", description: "Homme-Excitable"),
    GeminiVoiceModel(id: "leda", name: "Leda", description: "Femme-Youthful"),
    GeminiVoiceModel(id: "orus", name: "Orus", description: "Homme-Firm"),
    GeminiVoiceModel(id: "callirrhoe", name: "Callirrhoe", description: "Femme-Easy-going"),
    GeminiVoiceModel(id: "autonoe", name: "Autonoe", description: "Femme-Bright"),
    GeminiVoiceModel(id: "enceladus", name: "Enceladus", description: "Homme-Breathy"),
    GeminiVoiceModel(id: "iapetus", name: "Iapetus", description: "Homme-Clear"),
    GeminiVoiceModel(id: "umbriel", name: "Umbriel", description: "Homme-Easy-going"),
    GeminiVoiceModel(id: "algieba", name: "Algieba", description: "Homme-Smooth"),
    GeminiVoiceModel(id: "despina", name: "Despina", description: "Femme-Smooth"),
    GeminiVoiceModel(id: "erinome", name: "Erinome", description: "Femme-Clear"),
  ];

  static GeminiVoiceModel findById(String id) {
    return all.firstWhere((v) => v.id == id, orElse: () => all.first);
  }
}