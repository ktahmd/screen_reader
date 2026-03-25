// lib/services/tts/tts_engine_factory.dart

import 'abstract_tts_engine.dart';
import 'engine_modes/elevenLab_engine.dart';
import 'engine_modes/gemini_engine.dart';
import 'engine_modes/google_engine.dart';
import 'engine_modes/offline_engine.dart';
import 'tts_service.dart';

class TtsEngineFactory {
  static ITtsEngine getEngine(TtsVoiceMode mode, String text) {
    switch (mode) {
      case TtsVoiceMode.gemini:
        return GeminiTtsEngine();
      case TtsVoiceMode.elevenlabs:
        return ElevenLabsTtsEngine();
      case TtsVoiceMode.offline:
        return OfflineTtsEngine();
      case TtsVoiceMode.google:
        return GoogleTtsEngine();
      case TtsVoiceMode.auto:
        return _getAutoEngine(text);
    }
  }

  static ITtsEngine _getAutoEngine(String text) {
    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount <= 20) return GoogleTtsEngine();
    if (TtsService.config.geminiApiKey != null) return GeminiTtsEngine();
    if (TtsService.config.elevenLabsApiKey != null) return ElevenLabsTtsEngine();
    return GoogleTtsEngine();
  }
}