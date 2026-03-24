// lib/core/constants/default_settings.dart

class DefaultSettings {
  // ElevenLabs Defaults
  static const String elevenLabsModelId = "eleven_flash_v2_5";
  static const String elevenLabsVoiceId = "pNInz6obpgDQGcFmaJgB"; 

  // Gemini Defaults
  static const String geminiModelTextToSpeechId = "gemini-2.5-flash-preview-tts";
  static const String geminiModelId = "gemini-3.1-flash-preview";
  static const String geminiDefaultVoice = GeminiVoices.voice1; 
}

class GeminiVoices {
  static const String voice1 = "zephyr";
  static const String voice2 = "orion";
  static const String voice3 = "aurora";
  static const String voice4 = "nova";
  static const String voice5 = "vega";
  static const String voice6 = "sirius";
  static const String voice7 = "polaris";
  static const String voice8 = "lyra";
  static const String voice9 = "draco";
  static const String voice10 = "pegasus";
  static const String voice11 = "phoenix";
  static const String voice12 = "andromeda";
  static const String voice13 = "centaurus";
  static const String voice14 = "cassiopeia";
  static const String voice15 = "hydra";
  static const String voice16 = "vega2";

  // Helper list for UI Dropdowns
  static const List<String> all = [
    voice1, voice2, voice3, voice4, voice5, voice6, voice7, voice8,
    voice9, voice10, voice11, voice12, voice13, voice14, voice15, voice16
  ];
}