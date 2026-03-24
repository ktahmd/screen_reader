import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/constants/default_settings.dart';

enum AppTtsState { idle, loading, playing, paused }

enum TtsVoiceMode { auto, offline, google, elevenlabs, gemini }
// enum GeminiVoice { puck, charon, kore, fenrir, aoede, zephyr }

class TtsService {
  static String currentGeminiVoice = DefaultSettings.geminiDefaultVoice;
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();
  static final Connectivity _connectivity = Connectivity();

  static ValueNotifier<AppTtsState> stateNotifier =
      ValueNotifier(AppTtsState.idle);

  static bool _isProcessing = false;
  static bool _isUsingAudioPlayer = false;
  static bool _isPlaying = false;

  static List<String> _googleChunks = [];
  static int _currentChunkIndex = 0;
  static bool _isReadingGoogle = false;
  static String _lastSpokenText = "";

  static TtsVoiceMode sentenceMode = TtsVoiceMode.auto;
  static TtsVoiceMode wordMode = TtsVoiceMode.offline;

  // ElevenLabs Config
  static String? elevenLabsApiKey;
  static String elevenLabsModelId = "eleven_flash_v2_5";
  static String currentElevenLabsVoiceId =
      "pNInz6obpgDQGcFmaJgB"; // Default: Adam

  // Gemini Config
  static String? geminiApiKey;
  static String geminiModelTextToSpeechId = "gemini-2.5-flash-tts-preview";
  // static GeminiVoice currentGeminiVoice = GeminiVoice.zephyr;

  // ================= INIT & UTILS =================
  static Future<void> init() async {
    _audioPlayer.onPlayerComplete.listen((event) => _handleAudioComplete());
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  static Future<bool> isOnline() async {
    var result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static String _normalize(String text) => text.trim();

  // ================= FETCH DYNAMIC DATA =================

  static Future<List<Map<String, String>>> fetchElevenLabsModels(
      String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.elevenlabs.io/v1/models'),
        headers: {'xi-api-key': apiKey},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .where((m) => m['can_do_text_to_speech'] == true)
            .map<Map<String, String>>((m) => {
                  'id': m['model_id'].toString(),
                  'name': m['name'].toString(),
                })
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching ElevenLabs models: $e");
    }
    return [];
  }

  // Fetch Dynamic Voices from ElevenLabs
  static Future<List<Map<String, String>>> fetchElevenLabsVoices(
      String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.elevenlabs.io/v1/voices'),
        headers: {'xi-api-key': apiKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List voices = data['voices'];
        return voices
            .map<Map<String, String>>((v) => {
                  'id': v['voice_id'].toString(),
                  'name': v['name'].toString(),
                })
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching ElevenLabs voices: $e");
    }
    return [];
  }

  static Future<List<Map<String, String>>> fetchGeminiModels(
      String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List models = data['models'];
        return models
            .where((m) =>
                m['name'].toString().contains('tts') &&
                m['supportedGenerationMethods'] != null &&
                (m['supportedGenerationMethods'] as List)
                    .contains('generateContent'))
            .map<Map<String, String>>((m) => {
                  'id': m['name'].toString().replaceFirst('models/', ''),
                  'name': m['displayName'].toString(),
                })
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching Gemini models: $e");
    }
    return [];
  }

  // ================= MAIN SPEAK =================
  static Future<void> speak(String text, {required bool isWord}) async {
    if (text.trim().isEmpty) return;
    if (stateNotifier.value == AppTtsState.paused) {
      await resume(isWord: isWord);
      return;
    }
    if (_isProcessing) return;

    _isProcessing = true;
    _lastSpokenText = text;
    stateNotifier.value = AppTtsState.loading;
    final normalized = _normalize(text.toLowerCase());
    TtsVoiceMode activeMode = isWord ? wordMode : sentenceMode;

    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
      bool online = await isOnline();

      if (!online && activeMode != TtsVoiceMode.offline) {
        Fluttertoast.showToast(
            msg: "No Internet Connection. Using Offline mode.");
        await _speakOffline(normalized);
        return;
      }

      if (activeMode == TtsVoiceMode.auto) {
        await _speakAutoMode(normalized);
      } else {
        await _routeSpecificMode(normalized, activeMode);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error occurred. Falling back to Offline.");
      await _speakOffline(normalized);
    } finally {
      _isProcessing = false;
    }
  }

  static Future<void> _speakAutoMode(String text) async {
    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount <= 20) {
      await _speakGoogleWeb(text);
    } else {
      if (geminiApiKey != null && geminiApiKey!.isNotEmpty) {
        await _speakGemini(text);
      } else if (elevenLabsApiKey != null && elevenLabsApiKey!.isNotEmpty) {
        await _speakElevenLabs(text);
      } else {
        await _speakGoogleWeb(text);
      }
    }
  }

  static Future<void> _routeSpecificMode(String text, TtsVoiceMode mode) async {
    if (mode == TtsVoiceMode.offline) {
      await _speakOffline(text);
    } else if (mode == TtsVoiceMode.gemini) {
      await _speakGemini(text);
    } else if (mode == TtsVoiceMode.elevenlabs) {
      await _speakElevenLabs(text);
    } else {
      await _speakGoogleWeb(text);
    }
  }

  // ================= GEMINI TTS =================
  static Future<void> _speakGemini(String text) async {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      Fluttertoast.showToast(msg: "Gemini API Key missing. Falling back.");
      await _speakGoogleWeb(text);
      return;
    }

    _isUsingAudioPlayer = true;
    _isPlaying = true;
    final String voiceName = currentGeminiVoice.replaceFirst(
        currentGeminiVoice[0], currentGeminiVoice[0].toUpperCase());
    final hash =
        sha256.convert(utf8.encode("${text}gemini_$voiceName")).toString();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$hash.wav');

    if (await file.exists()) {
      stateNotifier.value = AppTtsState.playing;
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(file.path));
      return;
    }

    final url ='https://generativelanguage.googleapis.com/v1beta/models/$geminiModelTextToSpeechId:generateContent?key=$geminiApiKey';
    //TODO: geminiModelTextToSpeechId return null for some reason
    debugPrint("XXXXXXXXXXXXXXXXXXXXXXXXXXX= ${geminiModelTextToSpeechId}");
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
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
                "prebuilt_voice_config": {
                  "voice_name": voiceName.replaceFirst(
                      voiceName[0], voiceName[0].toUpperCase())
                }
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final base64Audio =
            data['candidates'][0]['content']['parts'][0]['inlineData']['data'];
        Uint8List pcmBytes = base64Decode(base64Audio);
        Uint8List wavBytes = _addWavHeader(pcmBytes);
        await file.writeAsBytes(wavBytes);

        stateNotifier.value = AppTtsState.playing;
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        debugPrint("Gemini TTS Error: ${response.body}");
        Fluttertoast.showToast(msg: "Gemini API failed. Falling back.");
        await _speakGoogleWeb(text);
      }
    } catch (e) {
      debugPrint("Gemini failed: $e");
      Fluttertoast.showToast(msg: "Gemini API Failed. Falling back.");
      await _speakGoogleWeb(text);
    }
  }

  static Uint8List _addWavHeader(Uint8List pcmData) {
    int channels = 1, sampleRate = 24000, byteRate = sampleRate * channels * 2;
    int totalDataLen = pcmData.length, totalAudioLen = totalDataLen + 36;
    var header = ByteData(44);
    header.setUint8(0, 82);
    header.setUint8(1, 73);
    header.setUint8(2, 70);
    header.setUint8(3, 70);
    header.setUint32(4, totalAudioLen, Endian.little);
    header.setUint8(8, 87);
    header.setUint8(9, 65);
    header.setUint8(10, 86);
    header.setUint8(11, 69);
    header.setUint8(12, 102);
    header.setUint8(13, 109);
    header.setUint8(14, 116);
    header.setUint8(15, 32);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 100);
    header.setUint8(37, 97);
    header.setUint8(38, 116);
    header.setUint8(39, 97);
    header.setUint32(40, totalDataLen, Endian.little);
    var b = BytesBuilder();
    b.add(header.buffer.asUint8List());
    b.add(pcmData);
    return b.toBytes();
  }

  // ================= ELEVENLABS =================
  static Future<void> _speakElevenLabs(String text) async {
    if (elevenLabsApiKey == null || elevenLabsApiKey!.isEmpty) {
      Fluttertoast.showToast(
          msg: "API Key missing. Falling back to Google TTS.");
      await _speakGoogleWeb(text);
      return;
    }
    _isUsingAudioPlayer = true;
    _isPlaying = true;

    final voiceId = currentElevenLabsVoiceId; // Using dynamic ID
    final hash = sha256
        .convert(utf8.encode(text + elevenLabsModelId + voiceId))
        .toString();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$hash.mp3');

    if (await file.exists()) {
      stateNotifier.value = AppTtsState.playing;
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(file.path));
      return;
    }

    final url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceId';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': elevenLabsApiKey!
        },
        body: json.encode({
          "text": text,
          "model_id": elevenLabsModelId,
          "voice_settings": {
            "stability": 0.4,
            "similarity_boost": 0.75,
            "style": 0.1,
            "speed": 0.9,
            "use_speaker_boost": true
          }
        }),
      );
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        stateNotifier.value = AppTtsState.playing;
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        Fluttertoast.showToast(msg: "API Quota Exceeded/Invalid Key.");
        await _speakGoogleWeb(text);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "ElevenLabs API Failed.");
      await _speakGoogleWeb(text);
    }
  }

  // ================= GOOGLE WEB =================
  static Future<void> _speakGoogleWeb(String text) async {
    _isUsingAudioPlayer = true;
    _googleChunks = _splitIntoSentences(text);
    _currentChunkIndex = 0;
    _isReadingGoogle = true;
    _isPlaying = true;
    stateNotifier.value = AppTtsState.playing;
    await _playNextGoogleChunk();
  }

  static Future<void> _playNextGoogleChunk() async {
    if (!_isReadingGoogle || _currentChunkIndex >= _googleChunks.length) return;
    final chunk = _googleChunks[_currentChunkIndex];
    try {
      final url =
          "https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(chunk)}";
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      await _speakOffline(chunk);
    }
  }

  // ================= OFFLINE =================
  static Future<void> _speakOffline(String text) async {
    _isUsingAudioPlayer = false;
    _isPlaying = true;
    try {
      await _flutterTts.stop();
      stateNotifier.value = AppTtsState.playing;
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(text);
      _isPlaying = false;
      stateNotifier.value = AppTtsState.idle;
    } catch (e) {
      _isPlaying = false;
      stateNotifier.value = AppTtsState.idle;
    }
  }

  // ================= PAUSE / RESUME / STOP =================
  static Future<void> pause() async {
    if (_isUsingAudioPlayer) {
      await _audioPlayer.pause();
      stateNotifier.value = AppTtsState.paused;
    } else {
      await _flutterTts.stop();
      stateNotifier.value = AppTtsState.paused;
    }
  }

  static Future<void> resume({required bool isWord}) async {
    if (_isUsingAudioPlayer) {
      await _audioPlayer.resume();
      stateNotifier.value = AppTtsState.playing;
    } else {
      if (_lastSpokenText.isNotEmpty) {
        stateNotifier.value = AppTtsState.loading;
        await speak(_lastSpokenText, isWord: isWord);
      }
    }
  }

  static Future<void> stop() async {
    _isReadingGoogle = false;
    _lastSpokenText = "";
    _isPlaying = false;
    stateNotifier.value = AppTtsState.idle;
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
    } catch (_) {}
  }

  static void _handleAudioComplete() {
    if (_isReadingGoogle) {
      _currentChunkIndex++;
      if (_currentChunkIndex < _googleChunks.length) {
        _playNextGoogleChunk();
        return;
      } else {
        _isReadingGoogle = false;
      }
    }
    _isPlaying = false;
    stateNotifier.value = AppTtsState.idle;
  }

  static List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
