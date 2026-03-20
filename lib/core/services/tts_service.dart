import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();

  /// Initialize TTS settings (Language, Speed, Pitch)
  static Future<void> init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45); 
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// Speak the given text
  static Future<void> speak(String text) async {
    if (text.trim().isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  /// Stop currently playing audio
  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}