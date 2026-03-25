class ApiEndpoints {
  // ElevenLabs
  static const String elevenLabsBase = "https://api.elevenlabs.io";
  static const String elevenLabsModels = "$elevenLabsBase/v1/models";
  static const String elevenLabsVoices = "$elevenLabsBase/v2/voices?page_size=23";
  static String elevenLabsTts(String voiceId) => "$elevenLabsBase/v1/text-to-speech/$voiceId";

  // Gemini
  static const String geminiBase = "https://generativelanguage.googleapis.com/v1beta/models";
  static String geminiTts(String modelId, String apiKey) => "$geminiBase/$modelId:generateContent?key=$apiKey";

  // Google Web
  static String googleWebTts(String text) => 
      "https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(text)}";
}