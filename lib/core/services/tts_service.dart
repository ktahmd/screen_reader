import 'dart:io';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../api_keys.dart';

enum AppTtsState { idle, loading, playing, paused }

enum TtsVoiceMode { offline, google, adam, bella, elisabeth }

class TtsService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();
  static final Connectivity _connectivity = Connectivity();

  static TtsVoiceMode currentMode = TtsVoiceMode.elisabeth;

  static ValueNotifier<AppTtsState> stateNotifier =
      ValueNotifier(AppTtsState.idle);

  static bool _isProcessing = false;
  static bool _isUsingAudioPlayer = false;
  static bool _isPlaying = false;

  static List<String> _googleChunks = [];
  static int _currentChunkIndex = 0;
  static bool _isReadingGoogle = false;

  static String _lastSpokenText = "";

  static const Map<TtsVoiceMode, String> _voiceIds = {
    TtsVoiceMode.adam: "pNInz6obpgDQGcFmaJgB",
    TtsVoiceMode.bella: "hpp4J3VqNfWAUOO0d1Us",
    TtsVoiceMode.elisabeth: "9tDJMfriv2Hg6KGY603n",
  };

  // ================= INIT =================

  static Future<void> init() async {
    _audioPlayer.onPlayerComplete.listen((event) {
      _handleAudioComplete();
    });

    await _flutterTts.awaitSpeakCompletion(true);

    // _flutterTts.setCompletionHandler(() {
    //   _isPlaying = false;
    //   _isUsingAudioPlayer = false;
    //   stateNotifier.value = AppTtsState.idle;
    // });

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  // ================= CONNECTIVITY =================

  static Future<bool> isOnline() async {
    var result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static String _normalize(String text) => text.trim();

  // ================= MAIN SPEAK =================

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    if (stateNotifier.value == AppTtsState.paused) {
      await resume();
      return;
    }

    if (_isProcessing) return;

    _isProcessing = true;
    _lastSpokenText = text;

    stateNotifier.value = AppTtsState.loading;

    final normalized = _normalize(text.toLowerCase());
    debugPrint("🔊 TTS Request: $currentMode");
    debugPrint("🌐 TTS Mode: $currentMode ");

    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();

      bool online = await isOnline();

      if (!online || currentMode == TtsVoiceMode.offline) {
        await _speakOffline(normalized);
        return;
      }


      // if (normalized.split(' ').length <= 20) {
      //   await _speakOffline(normalized);
      // } else 
      if (currentMode == TtsVoiceMode.google) {
        await _speakGoogleWeb(normalized);
      } else {
        await _speakElevenLabs(normalized);
      }
    } catch (e) {
      debugPrint("TTS error: $e");
      await _speakOffline(normalized);
    } finally {
      _isProcessing = false;
    }
  }

  // ================= PAUSE / RESUME =================

  static Future<void> pause() async {
    if (_isUsingAudioPlayer) {
      await _audioPlayer.pause();
    } else {
      await _flutterTts.stop();
      stateNotifier.value = AppTtsState.idle;
    }

    stateNotifier.value = AppTtsState.paused;
  }

  static Future<void> resume() async {
    if (_isUsingAudioPlayer) {
      await _audioPlayer.resume();
      stateNotifier.value = AppTtsState.playing;
    } else {
      // Offline = restart, not resume
      if (_lastSpokenText.isNotEmpty) {
        await speak(_lastSpokenText);
      }
    }
  }

  // ================= ELEVENLABS =================

  static Future<void> _speakElevenLabs(String text) async {
    _isUsingAudioPlayer = true;
    _isPlaying = true;

    final voiceId = _voiceIds[currentMode] ?? _voiceIds[TtsVoiceMode.bella]!;

    final normalized = _normalize(text).toLowerCase();

    // 🔥 UNIQUE HASH (text + voice)
    final hash = sha256
        .convert(utf8.encode(normalized + currentMode.toString()))
        .toString();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$hash.mp3');

    // ✅ 1. USE CACHE IF EXISTS
    if (await file.exists()) {
      stateNotifier.value = AppTtsState.playing;
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(file.path));
      return;
    }

    // ❌ 2. OTHERWISE CALL API
    final url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceId';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': elevenLabsApiKey
        },
        body: json.encode({
          "text": text,
          "model_id": "eleven_flash_v2_5",
        }),
      );

      if (response.statusCode == 200) {
        // ✅ SAVE TO CACHE
        await file.writeAsBytes(response.bodyBytes);

        stateNotifier.value = AppTtsState.playing;
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        await _speakGoogleWeb(text);
      }
    } catch (e) {
      debugPrint("ElevenLabs failed: $e");
      await _speakGoogleWeb(text);
    }
  }

  // ================= GOOGLE =================

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
      debugPrint("Google chunk error: $e");
      await _speakOffline(chunk);
    }
  }

  // 🔥 SINGLE SOURCE OF TRUTH FOR COMPLETION

  // ================= OFFLINE =================

  static Future<void> _speakOffline(String text) async {
    _isUsingAudioPlayer = false;
    _isPlaying = true;

    stateNotifier.value = AppTtsState.playing;

    try {
      await _flutterTts.stop();
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(text);
      _isPlaying = false;
      stateNotifier.value = AppTtsState.idle;
    } catch (e) {
      debugPrint("Offline TTS error: $e");
      stateNotifier.value = AppTtsState.idle;
    }
  }

  // ================= STOP =================

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

  // ================= UTIL =================
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
