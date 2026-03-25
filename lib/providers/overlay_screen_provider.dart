// lib/overlay_ui/overlay/overlay_screen_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/overlay_actions.dart';
import '../../models/ocr_word_model.dart';
import '../../services/local_storage_service.dart';
import '../models/tts_config_model.dart';
import '../services/translator_service.dart';
import '../services/tts/tts_service.dart';

class OverlayScreenProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();

  // --- UI State ---
  bool isProcessing = false;
  bool showWords = false;
  String? errorCode;
  bool isExpanded = false;

  // --- Word & Selection State ---
  List<OcrWord> words = [];
  Set<int> selectedWordIndices = {};
  Set<int> dragSelectedIndices = {};
  Offset? dragStart;
  Offset? dragCurrent;

  // --- Translation State ---
  String currentOriginalText = "";
  String currentTranslatedText = "";
  bool isTranslating = false;

  OverlayScreenProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await _initOverlaySettings();
    await TtsService.init();
    _listenToMainApp();
  }

  Future<void> _initOverlaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageService(prefs);

    TtsService.sentenceMode = storage.getSentenceMode();
    TtsService.wordMode = storage.getWordMode();
    TtsService.elevenLabsApiKey = storage.getElevenLabsApiKey();
    TtsService.elevenLabsModelId = storage.getElevenLabsModelId();
    TtsService.currentElevenLabsVoiceId = storage.getElevenLabsVoiceId();
    TtsService.geminiApiKey = storage.getGeminiApiKey();
    TtsService.geminiModelTextToSpeechId = storage.getGeminiModelTextToSpeechId();
    TtsService.currentGeminiVoice = storage.getGeminiVoice();
    
    notifyListeners();
  }

  void _listenToMainApp() {
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is! Map<String, dynamic>) return;
      final action = event['action'];

      if (action == OverlayActions.updateTtsModes) {
        final settings = TtsSettingsModel.fromMap(event);
        TtsService.sentenceMode = settings.sentenceMode;
        TtsService.wordMode = settings.wordMode;
        TtsService.elevenLabsApiKey = settings.elevenLabsApiKey;
        TtsService.elevenLabsModelId = settings.elevenLabsModelId;
        TtsService.currentElevenLabsVoiceId = settings.elevenLabsVoiceId;
        TtsService.geminiApiKey = settings.geminiApiKey;
        TtsService.geminiModelTextToSpeechId = settings.geminiModelTextToSpeechId;
        TtsService.currentGeminiVoice = settings.geminiVoice;
        notifyListeners();
      }

      if (action == OverlayActions.result) {
        await FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 0));
        await FlutterOverlayWindow.resizeOverlay(-1, -1, false);

        final List<dynamic> rawWords = event['words'];
        words = rawWords.map((w) => OcrWord.fromMap(w)).toList();
        
        showWords = true;
        isProcessing = false;
        errorCode = null;
        clearSelection();
      }

      if (action == OverlayActions.error) {
        errorCode = event['errorCode'];
        showWords = true;
        isProcessing = false;
        notifyListeners();
        await FlutterOverlayWindow.resizeOverlay(350, 250, true);
      }
    });
  }

  // --- User Actions ---

  void performCapture() {
    isProcessing = true;
    errorCode = null;
    clearSelection(); 
    FlutterOverlayWindow.shareData({'action': OverlayActions.capture});
  }

  Future<void> closeOverlay() async {
    await TtsService.stop();
    showWords = false;
    words = [];
    errorCode = null;
    clearSelection();
    await FlutterOverlayWindow.resizeOverlay(120, 120, true);
  }

  void toggleWordSelection(int index) {
    if (selectedWordIndices.contains(index)) {
      selectedWordIndices.remove(index);
    } else {
      selectedWordIndices.add(index);
    }
    _processSelection();
  }

  void toggleSelectAll() {
    if (selectedWordIndices.length == words.length) {
      clearSelection();
    } else {
      selectedWordIndices = Set.from(Iterable.generate(words.length));
      _processSelection();
    }
  }

  void toggleExpanded() {
    isExpanded = !isExpanded;
    notifyListeners();
  }

  void clearSelection() {
    TtsService.stop();
    isExpanded = false;
    selectedWordIndices.clear();
    dragSelectedIndices.clear();
    dragStart = null;
    dragCurrent = null;
    currentOriginalText = "";
    currentTranslatedText = "";
    isTranslating = false;
    notifyListeners();
  }

  void handlePanStart(Offset position) {
    clearSelection();
    dragStart = position;
    dragCurrent = position;
    dragSelectedIndices.clear();
    notifyListeners();
  }

  void handlePanUpdate(Offset position, double pixelRatio) {
    dragCurrent = position;

    if (dragStart != null && dragCurrent != null) {
      final selectionRect = Rect.fromPoints(dragStart!, dragCurrent!);
      Set<int> tempDragSelection = {};

      for (int i = 0; i < words.length; i++) {
        final wordRect = words[i].getAdjustedRect(pixelRatio);

        if (selectionRect.overlaps(wordRect)) {
          tempDragSelection.add(i);
        }
      }
      dragSelectedIndices = tempDragSelection;
    }
    notifyListeners();
  }

  void handlePanEnd() {
    selectedWordIndices.addAll(dragSelectedIndices);
    dragStart = null;
    dragCurrent = null;
    dragSelectedIndices.clear();
    _processSelection();
  }

  Future<void> _processSelection() async {
    if (selectedWordIndices.isEmpty) {
      currentOriginalText = "";
      currentTranslatedText = "";
      notifyListeners();
      return;
    }

    final sortedIndices = selectedWordIndices.toList()..sort();
    currentOriginalText = sortedIndices.map((i) => words[i].text).join(" ");
    isTranslating = true;
    notifyListeners();

    final translated = await _translationService.translateText(currentOriginalText, from: 'en', to: 'ar');

    if (selectedWordIndices.isNotEmpty) {
      currentTranslatedText = translated;
      isTranslating = false;
      notifyListeners();
    }
  }

  Future<void> playTts() async {
    bool isSingleWord = selectedWordIndices.length <= 3;
    await TtsService.speak(currentOriginalText, isWord: isSingleWord);
  }
}