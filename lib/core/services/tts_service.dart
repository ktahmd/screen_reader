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

// Added 'auto' to the modes
enum TtsVoiceMode { auto, offline, google, adam, bella, elisabeth }

class TtsService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();
  static final Connectivity _connectivity = Connectivity();

  static ValueNotifier<AppTtsState> stateNotifier = ValueNotifier(AppTtsState.idle);

  static bool _isProcessing = false;
  static bool _isUsingAudioPlayer = false;
  static bool _isPlaying = false;

  static List<String> _googleChunks = [];
  static int _currentChunkIndex = 0;
  static bool _isReadingGoogle = false;

  static String _lastSpokenText = "";

  // The two independent settings
  static TtsVoiceMode sentenceMode = TtsVoiceMode.auto;
  static TtsVoiceMode wordMode = TtsVoiceMode.offline;

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
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  // ================= CONNECTIVITY =================

  static Future<bool> isOnline() async {
    var result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static String _normalize(String text) => text.trim();

  // ================= MAIN SPEAK (ROUTER) =================

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
    
    // 1. Determine which mode setting to use based on the isWord flag
    TtsVoiceMode activeMode = isWord ? wordMode : sentenceMode;
    
    debugPrint("🔊 TTS Request: isWord=$isWord | Active Mode=$activeMode");

    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();

      bool online = await isOnline();

      // 2. Global Offline Check & Toast
      if (!online && activeMode != TtsVoiceMode.offline) {
        Fluttertoast.showToast(
          msg: "No Internet Connection. Using Offline mode.",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
        );
        await _speakOffline(normalized);
        return;
      }

      // 3. Clean Routing to the correct function
      if (activeMode == TtsVoiceMode.auto) {
        await _speakAutoMode(normalized);
      } else {
        await _routeSpecificMode(normalized, activeMode);
      }

    } catch (e) {
      debugPrint("TTS error: $e");
      Fluttertoast.showToast(msg: "Error occurred. Falling back to Offline.");
      await _speakOffline(normalized);
    } finally {
      _isProcessing = false;
    }
  }

  // ================= ROUTING FUNCTIONS =================

  static Future<void> _speakAutoMode(String text) async {
    final wordCount = text.split(RegExp(r'\s+')).length;
    
    if (wordCount <= 20) {
      // Small texts are fast, use Offline to save time/API credits
      await _speakOffline(text);
    } else {
      // Long paragraphs use premium voice
      await _speakElevenLabs(text, TtsVoiceMode.elisabeth);
    }
  }

  static Future<void> _routeSpecificMode(String text, TtsVoiceMode mode) async {
    if (mode == TtsVoiceMode.offline) {
      await _speakOffline(text);
    } else if (mode == TtsVoiceMode.google) {
      await _speakGoogleWeb(text);
    } else {
      // It's one of the ElevenLabs premium voices
      await _speakElevenLabs(text, mode);
    }
  }

  // ================= ELEVENLABS =================

  static Future<void> _speakElevenLabs(String text, TtsVoiceMode voice) async {
    _isUsingAudioPlayer = true;
    _isPlaying = true;

    final voiceId = _voiceIds[voice] ?? _voiceIds[TtsVoiceMode.bella]!;
    
    // 🔥 UNIQUE HASH (text + voice)
    final hash = sha256.convert(utf8.encode(text + voice.toString())).toString();
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
        await file.writeAsBytes(response.bodyBytes);
        stateNotifier.value = AppTtsState.playing;
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        Fluttertoast.showToast(msg: "API Quota Exceeded. Falling back to Google TTS.");
        await _speakGoogleWeb(text);
      }
    } catch (e) {
      debugPrint("ElevenLabs failed: $e");
      Fluttertoast.showToast(msg: "ElevenLabs API Failed. Falling back to Google TTS.");
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
      final url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(chunk)}";
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("Google chunk error: $e");
      Fluttertoast.showToast(msg: "Google TTS Failed. Falling back to Offline.");
      await _speakOffline(chunk);
    }
  }

  // ================= OFFLINE =================

  static Future<void> _speakOffline(String text) async {
    _isUsingAudioPlayer = false; // Force flag to false
    _isPlaying = true;
    
    try {
      await _flutterTts.stop();
      stateNotifier.value = AppTtsState.playing;
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(text);
      
      _isPlaying = false;
      stateNotifier.value = AppTtsState.idle; 
    } catch (e) {
      debugPrint("Offline TTS error: $e");
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
      stateNotifier.value = AppTtsState.paused; // Fake pause
    }
  }

  static Future<void> resume({required bool isWord}) async {
    if (_isUsingAudioPlayer) {
      await _audioPlayer.resume();
      stateNotifier.value = AppTtsState.playing;
    } else {
      // Since we had to stop FlutterTTS, on resume we MUST restart it
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
    return text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
  }
}