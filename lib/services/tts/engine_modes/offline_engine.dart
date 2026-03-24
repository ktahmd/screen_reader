import '../abstract_tts_engine.dart';
import '../tts_service.dart'; 

class OfflineTtsEngine implements ITtsEngine {
  @override
  Future<void> speak(String text) async {
    TtsService.isUsingAudioPlayer = false;
    try {
      await TtsService.flutterTts.stop();
      TtsService.stateNotifier.value = AppTtsState.playing;
      await TtsService.flutterTts.awaitSpeakCompletion(true);
      await TtsService.flutterTts.speak(text);
      TtsService.stateNotifier.value = AppTtsState.idle;
    } catch (e) {
      TtsService.stateNotifier.value = AppTtsState.idle;
    }
  }

  @override
  Future<void> stop() async {
    await TtsService.flutterTts.stop();
  }
}