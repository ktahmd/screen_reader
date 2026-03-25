import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPreviewService {
  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<String?> playingIdNotifier = ValueNotifier<String?>(null);

  AudioPreviewService() {
    _player.onPlayerComplete.listen((_) => playingIdNotifier.value = null);
  }

  Future<void> play(String id, String url) async {
    if (playingIdNotifier.value == id) {
      await _player.stop();
      playingIdNotifier.value = null;
    } else {
      playingIdNotifier.value = id;
      await _player.stop();
      await _player.play(UrlSource(url));
    }
  }

  void dispose() {
    _player.dispose();
    playingIdNotifier.dispose();
  }
}