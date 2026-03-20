import 'dart:io';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../api_keys.dart';

enum TtsVoiceMode { offline, google, adam, bella, elisabeth }

class TtsService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();

  static TtsVoiceMode currentMode = TtsVoiceMode.elisabeth;
  
  // 🔹 Track if we are busy with an API call or internal logic
  static bool _isProcessing = false;

  // 🔹 For Google Web Chunking
  static List<String> _googleChunks = [];
  static int _currentChunkIndex = 0;
  static bool _isReadingGoogle = false;

  static const Map<TtsVoiceMode, String> _voiceIds = {
    TtsVoiceMode.adam: "pNInz6obpgDQGcFmaJgB",
    TtsVoiceMode.bella: "hpp4J3VqNfWAUOO0d1Us",
    TtsVoiceMode.elisabeth: "9tDJMfriv2Hg6KGY603n",
  };

  static Future<void> init() async {
    // 🔹 When a Google Chunk finishes, play the next one
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isReadingGoogle) {
        _currentChunkIndex++;
        if (_currentChunkIndex < _googleChunks.length) {
          _playNextGoogleChunk();
        } else {
          _isReadingGoogle = false;
        }
      }
    });

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
  }

  static String _normalize(String text) => text.trim();

  static Future<String?> _getCachedFilePath(String text, TtsVoiceMode mode) async {
    final normalized = _normalize(text).toLowerCase();
    final hash = sha256.convert(utf8.encode(normalized + mode.toString())).toString();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$hash.mp3';
    if (await File(path).exists()) return path;
    return null;
  }

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (_isProcessing) return;

    _isProcessing = true;
    try {
      await stop();
      final normalized = _normalize(text.toLowerCase());

      // 🔹 RULE 3: Smart quota saving 
      // max 3 words to avoid cases like "Hi, how are you?" being sent to ElevenLabs and consuming quota, while still allowing slightly longer phrases to benefit from better quality. This is a heuristic and can be adjusted based on user feedback.
      if (normalized.split(' ').length <= 3) {
        debugPrint("word or phrase is short: using Google Web");
        await _speakGoogleWeb(normalized);
        return;
      }

      // 🔹 RULE 4: Cache check
      final cached = await _getCachedFilePath(normalized, currentMode);
      if (cached != null) {
        debugPrint("Playing from cache");
        await _audioPlayer.play(DeviceFileSource(cached));
        return;
      }

      // 🔹 Routing
      if (currentMode == TtsVoiceMode.offline) {
        await _speakOffline(normalized);
      } else if (currentMode == TtsVoiceMode.google) {
        await _speakGoogleWeb(normalized);
      } else {
        await _speakElevenLabs(normalized);
      }
    } finally {
      _isProcessing = false;
    }
  }

  // 🔥 ELEVENLABS
  static Future<void> _speakElevenLabs(String text) async {
    final voiceId = _voiceIds[currentMode]!;
    final url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceId';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'xi-api-key': elevenLabsApiKey},
        body: json.encode({
          "text": text,
          "model_id": "eleven_turbo_v2", 
          "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final hash = sha256.convert(utf8.encode(_normalize(text).toLowerCase() + currentMode.toString())).toString();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$hash.mp3');
        await file.writeAsBytes(bytes);
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        _handleApiError(response.statusCode);
        await _speakGoogleWeb(text);
      }
    } catch (e) {
      _showToast("Network error. Switching to Google voice.");
      await _speakGoogleWeb(text);
    }
  }

  // 🌐 GOOGLE (Restored Chunking to fix Error -1005)
  static Future<void> _speakGoogleWeb(String text) async {
    _googleChunks = _splitIntoSentences(text);
    _currentChunkIndex = 0;
    _isReadingGoogle = true;
    await _playNextGoogleChunk();
  }

  static Future<void> _playNextGoogleChunk() async {
    if (!_isReadingGoogle || _currentChunkIndex >= _googleChunks.length) return;
    
    final chunk = _googleChunks[_currentChunkIndex];
    try {
      // Using client=tw-ob is essential for streaming
      final url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(chunk)}";
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("Google Play Error: $e");
      await _speakOffline(chunk);
    }
  }

  // 📱 OFFLINE
  static Future<void> _speakOffline(String text) async {
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    _isReadingGoogle = false;
    await _audioPlayer.stop();
    await _flutterTts.stop();
  }

  // 🔹 Helper to split text into safe chunks for Google API
  static List<String> _splitIntoSentences(String text) {
    // Splits by punctuation (. ! ?) but keeps the punctuation with the sentence
    return text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
  }

  static void _handleApiError(int code) {
    if (code == 401) {
      _showToast("Invalid API key");
    } else if (code == 429) {
      _showToast("Quota exceeded");
    } else {
      _showToast("AI Error: $code. Using Google.");
    }
  }

  static void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }
}