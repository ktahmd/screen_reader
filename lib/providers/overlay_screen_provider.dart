// lib/overlay_ui/overlay/overlay_screen_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/overlay_actions.dart';
import '../../models/ocr_word_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/tts/tts_service.dart';
import '../models/tts_config_model.dart';
import '../services/share_data_service.dart';
import '../services/translator_service.dart';

class OverlayScreenProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();

  // ==================== STATE VARIABLES ====================

  // UI State
  bool isProcessing = false;
  bool showWords = false;
  String? errorCode;
  bool isExpanded = false;

  // Word & Selection State
  List<OcrWord> words = [];
  Set<int> selectedWordIndices = {};
  Set<int> dragSelectedIndices = {};
  Offset? dragStart;
  Offset? dragCurrent;

  // Translation State
  String currentOriginalText = "";
  String currentTranslatedText = "";
  bool isTranslating = false;

  // ==================== INITIALIZATION ====================

  OverlayScreenProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await _syncSettingsFromStorage();
    await TtsService.init();
    _listenToMessages();
  }

  Future<void> _syncSettingsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageService(prefs);
    // This forces the Overlay isolate to read the fresh data
    // from the disk, ignoring its stale memory cache!
    await prefs.reload();
    TtsService.updateConfiguration(storage.getAllSettings());
    notifyListeners();
  }

  // ==================== STREAM LISTENERS ====================

  void _listenToMessages() {
    OverlayShareDataService.messageStream.listen((event) {
      if (event is! Map<String, dynamic>) return;
      final action = event['action'];

      switch (action) {
        case OverlayActions.updateTtsModes:
          TtsService.updateConfiguration(TtsSettingsModel.fromMap(event));
          notifyListeners();
          break;
        case OverlayActions.result:
          _handleOcrResult(event);
          break;
        case OverlayActions.error:
          _handleError(event);
          break;
      }
    });
  }

  void performCapture() {
    isProcessing = true;
    errorCode = null;
    clearSelection();
    OverlayShareDataService.requestCapture();
    notifyListeners();
  }


  Future<void> _handleOcrResult(Map<String, dynamic> data) async {
    await FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 0));
    //TODO: i think i can resize this to the image size so no need for the customs pixelRatio
    //i will think about this
    await FlutterOverlayWindow.resizeOverlay(-1, -1, false);

    final List<dynamic> rawWords = data['words'];
    words = rawWords.map((w) => OcrWord.fromMap(w)).toList();

    showWords = true;
    isProcessing = false;
    errorCode = null;
    clearSelection();
  }

  Future<void> _handleError(Map<String, dynamic> data) async {
    errorCode = data['errorCode'];
    showWords = true;
    isProcessing = false;
    notifyListeners();
    await FlutterOverlayWindow.resizeOverlay(350, 250, true);
  }

  // ==================== USER ACTIONS ====================

  Future<void> closeOverlay() async {
    await TtsService.stop();
    showWords = false;
    words = [];
    errorCode = null;
    clearSelection();
    await FlutterOverlayWindow.resizeOverlay(120, 120, true);
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

  // ==================== SELECTION LOGIC ====================

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

  // ==================== GESTURE LOGIC ====================

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
        // DRY Principle: Math is safely hidden inside the Model
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

  // ==================== BUSINESS LOGIC ====================

  Future<void> _processSelection() async {
    if (selectedWordIndices.isEmpty) {
      currentOriginalText = "";
      currentTranslatedText = "";
      notifyListeners();
      return;
    }

    // 1. Combine selected text
    final sortedIndices = selectedWordIndices.toList()..sort();
    currentOriginalText = sortedIndices.map((i) => words[i].text).join(" ");

    isTranslating = true;
    notifyListeners();

    // 2. Fetch Translation
    final translated = await _translationService
        .translateText(currentOriginalText, from: 'en', to: 'ar');

    // 3. Ensure user hasn't cleared selection while translating
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
