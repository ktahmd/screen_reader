import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/audio_utils.dart';
import '../abstract_tts_engine.dart';
import '../tts_service.dart';
import 'google_engine.dart';

class GeminiTtsEngine implements ITtsEngine {
  @override
  Future<void> speak(String text) async {
    if (TtsService.geminiApiKey == null || TtsService.geminiApiKey!.isEmpty) {
      Fluttertoast.showToast(msg: "Gemini API Key missing. Falling back.");
      return GoogleTtsEngine().speak(text);
    }

    TtsService.isUsingAudioPlayer = true;
    final String voiceName = TtsService.currentGeminiVoice.replaceFirst(
        TtsService.currentGeminiVoice[0],
        TtsService.currentGeminiVoice[0].toUpperCase());

    final hash =
        sha256.convert(utf8.encode("${text}gemini_$voiceName")).toString();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$hash.wav');

    if (await file.exists()) {
      await _playFile(file.path);
      return;
    }

    final url = ApiEndpoints.geminiTts(
        TtsService.geminiModelTextToSpeechId, TtsService.geminiApiKey!);

    try {
      final response = await ApiClient.post(url, body: {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": text}
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["audio"],
          "speech_config": {
            "voice_config": {
              "prebuilt_voice_config": {"voice_name": voiceName}
            }
          }
        }
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final base64Audio =
            data['candidates'][0]['content']['parts'][0]['inlineData']['data'];

        Uint8List pcmBytes = base64Decode(base64Audio);
        Uint8List wavBytes = AudioUtils.addWavHeader(pcmBytes);
        await file.writeAsBytes(wavBytes);

        await _playFile(file.path);
      } else {
        Fluttertoast.showToast(msg: "Gemini API failed. Falling back.");
        await GoogleTtsEngine().speak(text);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Gemini API Failed. Falling back.");
      await GoogleTtsEngine().speak(text);
    }
  }

  Future<void> _playFile(String path) async {
    TtsService.stateNotifier.value = AppTtsState.playing;
    await TtsService.audioPlayer.play(DeviceFileSource(path));
  }

  @override
  Future<void> stop() async {
    await TtsService.audioPlayer.stop();
  }
}
