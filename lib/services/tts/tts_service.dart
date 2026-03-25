import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/default_settings.dart';
import '../../core/network/api_client.dart';
import '../../models/elevenlabs_voice_model.dart';
import '../../services/tts/tts_engines.dart';
import 'engine_modes/google_engine.dart';
import 'engine_modes/offline_engine.dart';

enum AppTtsState { idle, loading, playing, paused } 
enum TtsVoiceMode { auto, offline, google, elevenlabs, gemini } 

class TtsService {
  // --- Core Dependencies ---
  static final AudioPlayer audioPlayer = AudioPlayer();
  static final FlutterTts flutterTts = FlutterTts();
  static final Connectivity _connectivity = Connectivity();
  static final ValueNotifier<AppTtsState> stateNotifier = ValueNotifier(AppTtsState.idle);

  // --- State Variables ---
  static bool isProcessing = false;
  static bool isUsingAudioPlayer = false;
  static String lastSpokenText = "";

  // --- Google Chunking State ---
  static List<String> googleChunks = [];
  static int currentChunkIndex = 0;
  static bool isReadingGoogle = false;

  // --- Global Configurations ---
  static TtsVoiceMode sentenceMode = TtsVoiceMode.auto;
  static TtsVoiceMode wordMode = TtsVoiceMode.offline;

  // ElevenLabs Config
  static String? elevenLabsApiKey;
  static String elevenLabsModelId = DefaultSettings.elevenLabsModelId;
  static String currentElevenLabsVoiceId = DefaultSettings.elevenLabsVoiceId;

  // Gemini Config
  static String? geminiApiKey;
  static String geminiModelTextToSpeechId = DefaultSettings.geminiModelTextToSpeechId;
  static String geminiModelId = DefaultSettings.geminiModelId;
  static String currentGeminiVoice = DefaultSettings.geminiDefaultVoice; //default

  // ================= INIT =================
  static Future<void> init() async {
    audioPlayer.onPlayerComplete.listen((event) => _handleAudioComplete());
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  static Future<bool> isOnline() async {
    var result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ================= FETCH DYNAMIC DATA =================
  static Future<List<Map<String, String>>> fetchElevenLabsModels(String apiKey) async {
    try {
      final res = await ApiClient.get(ApiEndpoints.elevenLabsModels, headers: {'xi-api-key': apiKey});
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.where((m) => m['can_do_text_to_speech'] == true)
            .map<Map<String, String>>((m) => {'id': m['model_id'].toString(), 'name': m['name'].toString()}).toList();
      }
    } catch (e) { debugPrint("Error: $e"); }
    return [];
  }

  static Future<List<ElevenLabsVoiceModel>> fetchElevenLabsVoices(String apiKey) async {
    try {
      final res = await ApiClient.get(ApiEndpoints.elevenLabsVoices, headers: {'xi-api-key': apiKey});
      if (res.statusCode == 200) {
        final List voicesData = json.decode(res.body)['voices'];
        return voicesData
            .map<ElevenLabsVoiceModel>((v) => ElevenLabsVoiceModel.fromMap(v))
            .toList();
      }
    } catch (e) { 
      debugPrint("Error fetching ElevenLabs voices: $e"); 
    }
    return [];
  }

  static Future<List<Map<String, String>>> fetchGeminiModels(String apiKey) async {
    try {
      final res = await ApiClient.get("${ApiEndpoints.geminiBase}?key=$apiKey");
      if (res.statusCode == 200) {
        final List models = json.decode(res.body)['models'];
        return models.where((m) => m['name'].toString().contains('tts') && 
            m['supportedGenerationMethods'] != null && 
            (m['supportedGenerationMethods'] as List).contains('generateContent'))
            .map<Map<String, String>>((m) => {'id': m['name'].toString().replaceFirst('models/', ''), 'name': m['displayName'].toString()}).toList();
      }
    } catch (e) { debugPrint("Error: $e"); }
    return [];
  }

  // ================= MAIN ROUTING =================
  static Future<void> speak(String text, {required bool isWord}) async {
    if (text.trim().isEmpty) return;
    if (stateNotifier.value == AppTtsState.paused) return resume(isWord: isWord);
    if (isProcessing) return;

    isProcessing = true;
    lastSpokenText = text;
    stateNotifier.value = AppTtsState.loading;
    
    try {
      await audioPlayer.stop();
      await flutterTts.stop();

      // 1. Determine the mode
      TtsVoiceMode mode = isWord ? wordMode : sentenceMode;

      // 2. Check online status
      if (!(await isOnline()) && mode != TtsVoiceMode.offline) {
         mode = TtsVoiceMode.offline;
      }

      // 3. GET THE ENGINE FROM FACTORY (Polymorphism)
      final engine = TtsEngineFactory.getEngine(mode, text);

      // 4. JUST CALL SPEAK (The engine knows what to do)
      await engine.speak(text.trim().toLowerCase());

    } catch (e) {
      await OfflineTtsEngine().speak(text);
    } finally {
      isProcessing = false;
    }
  }
  
  // ================= PLAYBACK CONTROLS =================
  static Future<void> pause() async {
    if (isUsingAudioPlayer) {
      await audioPlayer.pause();
    } else {
      await flutterTts.stop();
    }
    stateNotifier.value = AppTtsState.paused;
  }

  static Future<void> resume({required bool isWord}) async {
    if (isUsingAudioPlayer) {
      await audioPlayer.resume();
      stateNotifier.value = AppTtsState.playing;
    } else if (lastSpokenText.isNotEmpty) {
      stateNotifier.value = AppTtsState.loading;
      await speak(lastSpokenText, isWord: isWord);
    }
  }

  static Future<void> stop() async {
    isReadingGoogle = false;
    lastSpokenText = "";
    stateNotifier.value = AppTtsState.idle;
    try {
      await audioPlayer.stop();
      await flutterTts.stop();
    } catch (_) {}
  }

  static void _handleAudioComplete() {
    if (isReadingGoogle) {
      currentChunkIndex++;
      if (currentChunkIndex < googleChunks.length) {
        GoogleTtsEngine().playNextChunk();
        return;
      } else {
        isReadingGoogle = false;
      }
    }
    stateNotifier.value = AppTtsState.idle;
  }
}