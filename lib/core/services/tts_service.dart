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
  static bool _isProcessing = false;

  static List<String> _googleChunks = [];
  static int _currentChunkIndex = 0;
  static bool _isReadingGoogle = false;

  // This is used by the UI to show the correct Icon (Sound/Loading/Pause/Play)
  static ValueNotifier<AppTtsState> stateNotifier = ValueNotifier(AppTtsState.idle);
  
  // Track last text to handle Resume logic correctly
  static String _lastSpokenText = "";

  static const Map<TtsVoiceMode, String> _voiceIds = {
    TtsVoiceMode.adam: "pNInz6obpgDQGcFmaJgB",
    TtsVoiceMode.bella: "hpp4J3VqNfWAUOO0d1Us",
    TtsVoiceMode.elisabeth: "9tDJMfriv2Hg6KGY603n",
  };

  static Future<void> init() async {
    // 1. Handle completion for ElevenLabs, Google, and Cached files
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isReadingGoogle) {
        _currentChunkIndex++;
        if (_currentChunkIndex < _googleChunks.length) {
          _playNextGoogleChunk();
          return; // Keep playing next chunk
        } else {
          _isReadingGoogle = false;
        }
      }
      // If we reach here, all audio (including ElevenLabs/Cache) is done
      stateNotifier.value = AppTtsState.idle;
    });

    // 2. Handle completion for System TTS (Offline mode)
    _flutterTts.setCompletionHandler(() {
      stateNotifier.value = AppTtsState.idle;
    });

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  /// Helper to check if we have internet access
  static Future<bool> isOnline() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  static String _normalize(String text) => text.trim();

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    // Check if we are resuming the same text after a Pause
    if (stateNotifier.value == AppTtsState.paused && _lastSpokenText == text) {
      await resume();
      return;
    }

    if (_isProcessing) return;

    _isProcessing = true;
    _lastSpokenText = text;
    stateNotifier.value = AppTtsState.loading;
    
    // lowercase cuz Google TTS treats "Hello" and "hello" differently, causing cache misses. Normalizing to lowercase improves cache hits and consistency across providers.
    final normalized = _normalize(text.toLowerCase());
    
    try {
      // Ensure everything is stopped before starting new audio
      await _audioPlayer.stop(); 
      await _flutterTts.stop();

      // 1.RULE 1: Check Connectivity First
      bool online = await isOnline();

      // 2. Routing Logic
      if (!online || currentMode == TtsVoiceMode.offline) {
        if (!online && currentMode != TtsVoiceMode.offline) {
          _showToast("Offline: Using system voice");
        }
        await _speakOffline(normalized);
        return;
      }

      // 3. Cache check (Always check cache regardless of online status)
      final hash = sha256.convert(utf8.encode(normalized + currentMode.toString())).toString();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$hash.mp3');

      if (await file.exists()) {
        stateNotifier.value = AppTtsState.playing;
        await _audioPlayer.play(DeviceFileSource(file.path));
        return;
      }

      // 4. Quota Saving: Short phrases (<=3 words) use Google Web
      if (normalized.split(' ').length <= 3 || currentMode == TtsVoiceMode.google) {
        await _speakGoogleWeb(normalized);
      } else {
        await _speakElevenLabs(normalized);
      }

    } catch (e) {
      debugPrint("TTS speak error: $e");
      stateNotifier.value = AppTtsState.idle;
      await _speakOffline(normalized); 
    } finally {
      _isProcessing = false;
    }
  }

  static Future<void> pause() async {
    await _audioPlayer.pause();
    await _flutterTts.pause();
    stateNotifier.value = AppTtsState.paused;
  }

  static Future<void> resume() async {
    await _audioPlayer.resume();
    // System TTS resume support varies by phone, but we trigger it
    stateNotifier.value = AppTtsState.playing;
  }

  // 🔥 ELEVENLABS with Connection Handling
  static Future<void> _speakElevenLabs(String text) async {
    final voiceId = _voiceIds[currentMode] ?? _voiceIds[TtsVoiceMode.bella]!;
    //SHOW TOAST IF THE CURRENT MODE IS CHANGED TO DEFAULT MODE BELLA DUE TO MISSING VOICE ID
    if (!_voiceIds.containsKey(currentMode)) {
      _showToast("Voice ID not found for ${currentMode.toString().split('.').last}, defaulting to Bella");
    }

    final url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceId';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'xi-api-key': elevenLabsApiKey},
        body: json.encode({
          "text": text,
          "model_id": "eleven_flash_v2_5", 
          "voice_settings": {
            "stability": 0.4, 
            "similarity_boost": 0.75,
            "style": 0.1,
            "speed": 0.9,
            "use_speaker_boost": true
          }
        }),
      ).timeout(const Duration(seconds: 10)); 

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final hash = sha256.convert(utf8.encode(_normalize(text).toLowerCase() + currentMode.toString())).toString();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$hash.mp3');
        await file.writeAsBytes(bytes);
        
        stateNotifier.value = AppTtsState.playing; // Ensure icon changes to Pause/Stop
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        _handleApiError(response.statusCode);
        await _speakGoogleWeb(text);
      }
    } catch (e) {
      debugPrint("ElevenLabs Failed: $e");
      await _speakGoogleWeb(text);
    }
  }

  // 🌐 GOOGLE WEB with Error Handling
  static Future<void> _speakGoogleWeb(String text) async {
    try {
      _googleChunks = _splitIntoSentences(text);
      _currentChunkIndex = 0;
      _isReadingGoogle = true;
      stateNotifier.value = AppTtsState.playing;
      await _playNextGoogleChunk();
    } catch (e) {
      await _speakOffline(text);
    }
  }

  static Future<void> _playNextGoogleChunk() async {
    if (!_isReadingGoogle || _currentChunkIndex >= _googleChunks.length) return;
    
    final chunk = _googleChunks[_currentChunkIndex];
    try {
      //tl: Changes the language/accent (e.g., en-US, en-GB, fr-FR)
      
      final url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(chunk)}&total=${_googleChunks.length}&idx=$_currentChunkIndex";
      
      if (await isOnline()) {
        await _audioPlayer.play(UrlSource(url));
      } else {
        throw Exception("Lost connection between chunks");
      }
    } catch (e) {
      debugPrint("Google Play Error: $e");
      await _speakOffline(chunk);
    }
  }

  // 📱 OFFLINE (SYSTEM TTS)
  static Future<void> _speakOffline(String text) async {
    try {
      stateNotifier.value = AppTtsState.playing; 
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("Offline TTS critical failure: $e");
      stateNotifier.value = AppTtsState.idle;
    }
  }

  static Future<void> stop() async {
    _isReadingGoogle = false;
    _lastSpokenText = ""; // Clear memory
    stateNotifier.value = AppTtsState.idle; 
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("Error stopping audio: $e");
    }
  }

  static List<String> _splitIntoSentences(String text) {
    return text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
  }

  static void _handleApiError(int code) {
    if (code == 401) _showToast("Invalid API key");
    else if (code == 429) _showToast("Quota exceeded");
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