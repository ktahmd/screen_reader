import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/api_endpoints.dart';
import '../abstract_tts_engine.dart';
import '../tts_service.dart';
import 'offline_engine.dart'; 

class GoogleTtsEngine implements ITtsEngine {
  @override
  Future<void> speak(String text) async {
    TtsService.isUsingAudioPlayer = true;
    TtsService.googleChunks = _splitIntoSentences(text);
    TtsService.currentChunkIndex = 0;
    TtsService.isReadingGoogle = true;
    
    TtsService.stateNotifier.value = AppTtsState.playing;
    await playNextChunk();
  }

  Future<void> playNextChunk() async {
    if (!TtsService.isReadingGoogle || TtsService.currentChunkIndex >= TtsService.googleChunks.length) return;
    
    final chunk = TtsService.googleChunks[TtsService.currentChunkIndex];
    try {
      final url = ApiEndpoints.googleWebTts(chunk);
      await TtsService.audioPlayer.stop();
      await TtsService.audioPlayer.play(UrlSource(url));
    } catch (e) {
      await OfflineTtsEngine().speak(chunk);
    }
  }

  List<String> _splitIntoSentences(String text) {
    return text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
  }
  
  
  @override
  Future<void> stop() async {
     await TtsService.audioPlayer.stop();
  }
}
