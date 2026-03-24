import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/audio_utils.dart';
import 'tts_service.dart'; 

// ==========================================
// GEMINI ENGINE
// ==========================================
class GeminiTtsEngine {
  static Future<void> speak(String text) async {
    if (TtsService.geminiApiKey == null || TtsService.geminiApiKey!.isEmpty) {
      Fluttertoast.showToast(msg: "Gemini API Key missing. Falling back.");
      await GoogleTtsEngine.speak(text);
      return;
    }

    TtsService.isUsingAudioPlayer = true;
    final String voiceName = TtsService.currentGeminiVoice.replaceFirst(
        TtsService.currentGeminiVoice[0], TtsService.currentGeminiVoice[0].toUpperCase());
        
    final hash = sha256.convert(utf8.encode("${text}gemini_$voiceName")).toString();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$hash.wav');

    if (await file.exists()) {
      await _playFile(file.path);
      return;
    }

    final url = ApiEndpoints.geminiTts(TtsService.geminiModelTextToSpeechId, TtsService.geminiApiKey!);

    try {
      final response = await ApiClient.post(url, body: {
        "contents": [{"role": "user", "parts": [{"text": text}]}],
        "generationConfig": {
          "responseModalities": ["audio"],
          "speech_config": {
            "voice_config": {"prebuilt_voice_config": {"voice_name": voiceName}}
          }
        }
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final base64Audio = data['candidates'][0]['content']['parts'][0]['inlineData']['data'];
        
        Uint8List pcmBytes = base64Decode(base64Audio);
        Uint8List wavBytes = AudioUtils.addWavHeader(pcmBytes);
        await file.writeAsBytes(wavBytes);
        
        await _playFile(file.path);
      } else {
        Fluttertoast.showToast(msg: "Gemini API failed. Falling back.");
        await GoogleTtsEngine.speak(text);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Gemini API Failed. Falling back.");
      await GoogleTtsEngine.speak(text);
    }
  }

  static Future<void> _playFile(String path) async {
    TtsService.stateNotifier.value = AppTtsState.playing;
    await TtsService.audioPlayer.play(DeviceFileSource(path));
  }
}

// ==========================================
// ELEVENLABS ENGINE
// ==========================================
class ElevenLabsTtsEngine {
  static Future<void> speak(String text) async {
    if (TtsService.elevenLabsApiKey == null || TtsService.elevenLabsApiKey!.isEmpty) {
      Fluttertoast.showToast(msg: "API Key missing. Falling back to Google TTS.");
      await GoogleTtsEngine.speak(text);
      return;
    }

    TtsService.isUsingAudioPlayer = true;
    final voiceId = TtsService.currentElevenLabsVoiceId;
    final hash = sha256.convert(utf8.encode(text + TtsService.elevenLabsModelId + voiceId)).toString();
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
        headers: {'xi-api-key': TtsService.elevenLabsApiKey!},
        body: {
          "text": text,
          "model_id": TtsService.elevenLabsModelId,
          "voice_settings": {"stability": 0.4, "similarity_boost": 0.75, "style": 0.1, "speed": 0.9, "use_speaker_boost": true}
        },
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        TtsService.stateNotifier.value = AppTtsState.playing;
        await TtsService.audioPlayer.play(DeviceFileSource(file.path));
      } else {
        Fluttertoast.showToast(msg: "API Quota Exceeded/Invalid Key.");
        await GoogleTtsEngine.speak(text);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "ElevenLabs API Failed.");
      await GoogleTtsEngine.speak(text);
    }
  }
}

// ==========================================
// GOOGLE WEB ENGINE
// ==========================================
class GoogleTtsEngine {
  static Future<void> speak(String text) async {
    TtsService.isUsingAudioPlayer = true;
    TtsService.googleChunks = _splitIntoSentences(text);
    TtsService.currentChunkIndex = 0;
    TtsService.isReadingGoogle = true;
    
    TtsService.stateNotifier.value = AppTtsState.playing;
    await playNextChunk();
  }

  static Future<void> playNextChunk() async {
    if (!TtsService.isReadingGoogle || TtsService.currentChunkIndex >= TtsService.googleChunks.length) return;
    
    final chunk = TtsService.googleChunks[TtsService.currentChunkIndex];
    try {
      final url = ApiEndpoints.googleWebTts(chunk);
      await TtsService.audioPlayer.stop();
      await TtsService.audioPlayer.play(UrlSource(url));
    } catch (e) {
      await OfflineTtsEngine.speak(chunk);
    }
  }

  static List<String> _splitIntoSentences(String text) {
    return text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
  }
}

// ==========================================
// OFFLINE ENGINE
// ==========================================
class OfflineTtsEngine {
  static Future<void> speak(String text) async {
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
}