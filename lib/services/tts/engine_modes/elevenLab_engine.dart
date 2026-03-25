import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../abstract_tts_engine.dart';
import '../tts_service.dart';
import 'google_engine.dart'; 

class ElevenLabsTtsEngine implements ITtsEngine {
  @override
  @override
  Future<void> speak(String text) async {
    if (TtsService.config.elevenLabsApiKey == null || TtsService.config.elevenLabsApiKey!.isEmpty) {
      Fluttertoast.showToast(msg: "API Key missing. Falling back to Google TTS.");
      await GoogleTtsEngine().speak(text);
      return;
    }

    TtsService.isUsingAudioPlayer = true;
    final voiceId = TtsService.config.elevenLabsVoiceId;
    final modelId = TtsService.config.elevenLabsModelId;
    final apiKey = TtsService.config.elevenLabsApiKey!;
    
    final hash = sha256.convert(utf8.encode(text + modelId + voiceId)).toString();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$hash.mp3');

    if (await file.exists()) {
      TtsService.stateNotifier.value = AppTtsState.playing;
      await TtsService.audioPlayer.play(DeviceFileSource(file.path));
      return;
    }

    try {
      final response = await ApiClient.post(
        ApiEndpoints.elevenLabsTts(voiceId),
        headers: {'xi-api-key': apiKey},
        body: {
          "text": text,
          "model_id": modelId,
          "voice_settings": {"stability": 0.4, "similarity_boost": 0.75, "style": 0.1, "speed": 0.9, "use_speaker_boost": true}
        },
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        TtsService.stateNotifier.value = AppTtsState.playing;
        await TtsService.audioPlayer.play(DeviceFileSource(file.path));
      } else {
        Fluttertoast.showToast(msg: "API Quota Exceeded/Invalid Key.");
        await GoogleTtsEngine().speak(text);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "ElevenLabs API Failed.");
      await GoogleTtsEngine().speak(text);
    }
  }
  @override
  Future<void> stop() async {
     await TtsService.audioPlayer.stop();
  }
}
