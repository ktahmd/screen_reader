import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../services/translator_service.dart';
import '../../services/tts/tts_service.dart';

class OverlayContentWidget extends StatefulWidget {
  const OverlayContentWidget({super.key});
  @override
  State<OverlayContentWidget> createState() => _OverlayContentWidgetState();
}

class _OverlayContentWidgetState extends State<OverlayContentWidget> {
  bool isProcessing = false;
  bool showWords = false;
  List<dynamic> words = [];
  String? errorCode;
  Set<int> selectedWordIndices = {};
  String currentOriginalText = "";
  String currentTranslatedText = "";
  bool isTranslating = false;
  Offset? dragStart;
  Offset? dragCurrent;
  Set<int> dragSelectedIndices = {};
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initOverlaySettings();
    TtsService.init();
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is Map) {

        final action = event['action'];
        if (action == 'update_tts_modes') {
          final sentenceIndex = event['sentence_index'] as int;
          final wordIndex = event['word_index'] as int;
          
          final String apiKey = event['api_key'] as String;
          final String elModelId = event['el_model_id'] as String;
          final String elVoiceId = event['el_voice_id'] as String;
          
          final String geminiKey = event['gemini_api_key'] as String;
          final String gemModelId = event['gemini_model_id'] as String;
          final geminiVoiceIdx = event['gemini_voice_index'] as int;
          
          setState(() {
            TtsService.sentenceMode = TtsVoiceMode.values[sentenceIndex];
            TtsService.wordMode = TtsVoiceMode.values[wordIndex];
            
            TtsService.elevenLabsApiKey = apiKey.isEmpty ? null : apiKey;
            TtsService.elevenLabsModelId = elModelId;
            TtsService.currentElevenLabsVoiceId = elVoiceId;

            TtsService.geminiApiKey = geminiKey.isEmpty ? null : geminiKey;
            TtsService.geminiModelId = gemModelId;
            TtsService.currentGeminiVoice = GeminiVoice.values[geminiVoiceIdx];
          });
          return;
        }

        if (action == 'result') {
          await FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 0));
          await FlutterOverlayWindow.resizeOverlay(-1, -1, false);

          setState(() {
            words = event['words'] as List<dynamic>;
            showWords = true;
            isProcessing = false;
            errorCode = null;
            _clearSelection();
          });
        }

        if (action == 'error') {
          setState(() {
            errorCode = event['errorCode'];
            showWords = true;
            isProcessing = false;
          });
          await FlutterOverlayWindow.resizeOverlay(350, 250, true);
        }
      }
    });
  }

  void _performCapture() {
    setState(() {
      isProcessing = true;
      errorCode = null;
      _clearSelection();
    });
    FlutterOverlayWindow.shareData({'action': 'capture'});
  }

  void _closeOverlay() async {
    TtsService.stop();
    setState(() {
      showWords = false;
      words = [];
      errorCode = null;
      _clearSelection();
    });
    await FlutterOverlayWindow.resizeOverlay(120, 120, true);
  }

  void _toggleWordSelection(int index) async {
    setState(() {
      if (selectedWordIndices.contains(index)) {
        selectedWordIndices.remove(index);
      } else {
        selectedWordIndices.add(index);
      }
    });
    _processSelection();
  }

  void _onPanStart(DragStartDetails details) {
    _clearSelection();
    setState(() {
      dragStart = details.localPosition;
      dragCurrent = details.localPosition;
      dragSelectedIndices.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      dragCurrent = details.localPosition;
    });

    if (dragStart != null && dragCurrent != null) {
      final selectionRect = Rect.fromPoints(dragStart!, dragCurrent!);
      final pixelRatio = MediaQuery.of(context).devicePixelRatio - 0.09;

      Set<int> tempDragSelection = {};

      for (int i = 0; i < words.length; i++) {
        final w = words[i];
        final x = (w['x'] as num).toDouble() / pixelRatio - 8;
        final y = (w['y'] as num).toDouble() / pixelRatio - 15;
        final width = (w['w'] as num).toDouble() / pixelRatio + 6;
        final height = (w['h'] as num).toDouble() / pixelRatio + 6;

        final wordRect = Rect.fromLTWH(x, y, width, height);

        if (selectionRect.overlaps(wordRect)) {
          tempDragSelection.add(i);
        }
      }

      setState(() {
        dragSelectedIndices = tempDragSelection;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      selectedWordIndices.addAll(dragSelectedIndices);
      dragStart = null;
      dragCurrent = null;
      dragSelectedIndices.clear();
    });
    _processSelection();
  }

  void _toggleSelectAll() {
    if (selectedWordIndices.length == words.length) {
      _clearSelection();
    } else {
      setState(() {
        selectedWordIndices = Set.from(Iterable.generate(words.length));
      });
      _processSelection();
    }
  }

  void _processSelection() async {
    if (selectedWordIndices.isEmpty) {
      setState(() {
        currentOriginalText = "";
        currentTranslatedText = "";
      });
      return;
    }

    final sortedIndices = selectedWordIndices.toList()..sort();
    final combinedText = sortedIndices.map((i) => words[i]['text']).join(" ");

    setState(() {
      currentOriginalText = combinedText;
      isTranslating = true;
    });

    final translated = await TranslationService.translateText(combinedText,
        from: 'en', to: 'ar');

    if (selectedWordIndices.isNotEmpty) {
      setState(() {
        currentTranslatedText = translated;
        isTranslating = false;
      });
    }
  }

Future<void> _initOverlaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    int sentenceIndex = prefs.getInt('sentence_mode') ?? TtsVoiceMode.auto.index;
    int wordIndex = prefs.getInt('word_mode') ?? TtsVoiceMode.offline.index;
    
    TtsService.elevenLabsApiKey = prefs.getString('elevenlabs_api_key');
    TtsService.elevenLabsModelId = prefs.getString('elevenlabs_model_id') ?? "eleven_flash_v2_5";
    TtsService.currentElevenLabsVoiceId = prefs.getString('elevenlabs_voice_id') ?? "pNInz6obpgDQGcFmaJgB";
    
    TtsService.geminiApiKey = prefs.getString('gemini_api_key');
    TtsService.geminiModelId = prefs.getString('gemini_model_id') ?? "gemini-2.5-flash";
    int gemVoiceIdx = prefs.getInt('gemini_voice') ?? GeminiVoice.zephyr.index;

    setState(() {
      TtsService.sentenceMode = TtsVoiceMode.values[sentenceIndex];
      TtsService.wordMode = TtsVoiceMode.values[wordIndex];
      TtsService.currentGeminiVoice = GeminiVoice.values[gemVoiceIdx];
    });
  }

  void _clearSelection() {
    TtsService.stop();
    setState(() {
      isExpanded = false;
      selectedWordIndices.clear();
      dragSelectedIndices.clear();
      dragStart = null;
      dragCurrent = null;
      currentOriginalText = "";
      currentTranslatedText = "";
      isTranslating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: showWords ? _buildFullOverlay() : _buildButton(),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Center(
        child: GestureDetector(
          onDoubleTap: isProcessing ? null : _performCapture,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : const Icon(Icons.remove_red_eye, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFullOverlay() {
    //exemple of my phone resolution is 1440x2960
    //and pixel ratio is 4.3, so we need to divide the coordinates by 4.3
    //to get the correct position on the overlay,
    //but I found that the text is slightly off,
    //so I subtracted a small value from the pixel ratio to adjust it,
    //this is a common practice when dealing with different screen densities and resolutions in Flutter.
    //TODO: In future, we can make this adjustment dynamic by testing on multiple devices and finding the optimal value or formula for it.
    final pixelRatio = MediaQuery.of(context).devicePixelRatio - 0.09;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _clearSelection,
            onDoubleTap: _closeOverlay,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(color: Colors.transparent),
          ),
        ),
        ...words.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> w = entry.value;

          final bool isSelected = selectedWordIndices.contains(index) ||
              dragSelectedIndices.contains(index);

          final x = (w['x'] as num).toDouble() / pixelRatio - 8;
          final y = (w['y'] as num).toDouble() / pixelRatio - 15;
          final width = (w['w'] as num).toDouble() / pixelRatio + 6;
          final height = (w['h'] as num).toDouble() / pixelRatio + 6;

          return Positioned(
            left: x,
            top: y,
            width: width,
            height: height,
            child: GestureDetector(
              onTap: () {
                _clearSelection();
                _toggleWordSelection(index);
              },
              onLongPress: () => _toggleWordSelection(index),
              //NOTE: The text is invisible but the container is tappable,
              // allowing selection without blocking the view of the original text
              child: Container(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white.withOpacity(0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    w['text'],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0)
                          : Colors.black.withOpacity(0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (dragStart != null && dragCurrent != null)
          Positioned.fromRect(
            rect: Rect.fromPoints(dragStart!, dragCurrent!),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        if (selectedWordIndices.isNotEmpty && dragStart == null)
          Positioned(
            bottom: isExpanded ? 150 : 120,
            left: 10,
            right: 10,
            child: _buildTranslationPopup(),
          ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10)
                ],
              ),
              // ADD THIS SingleChildScrollView to prevent transient RenderFlex overflows
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                          selectedWordIndices.length == words.length
                              ? Icons.deselect
                              : Icons.select_all,
                          color: Colors.white),
                      onPressed: _toggleSelectAll,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _closeOverlay,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorCode != null) _buildErrorCard(),
      ],
    );
  }

  Widget _buildTranslationPopup() {
    bool needsExpansion =
        currentOriginalText.length > 45 || currentTranslatedText.length > 45;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // Give the popup a maximum height so it doesn't cover the whole screen
      constraints: BoxConstraints(
        maxHeight: isExpanded ? MediaQuery.of(context).size.height * 0.5 : 100,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align to top so scrolling works well
        children: [
          // 1. EXPAND/COLLAPSE BUTTON (LEFT)
          if (needsExpansion)
            IconButton(
              icon: Icon(isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up),
              onPressed: () => setState(() => isExpanded = !isExpanded),
            )
          else
            const SizedBox(width: 48),

          const SizedBox(width: 5),

          // 2. TEXT SECTION (SCROLLABLE MIDDLE)
          Expanded(
            child: SingleChildScrollView(
              // <--- ENABLE SCROLLING
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentOriginalText,
                    maxLines: isExpanded ? null : 1,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  if (isTranslating)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        currentTranslatedText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: isExpanded ? null : 1,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 3. SOUND CONTROLS (RIGHT)
          ValueListenableBuilder<AppTtsState>(
            valueListenable: TtsService.stateNotifier,
            builder: (context, state, child) {
              if (state == AppTtsState.loading) {
                return const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (state == AppTtsState.playing) {
                return IconButton(
                  icon: const Icon(Icons.pause_circle_filled,
                      color: AppColors.primary, size: 32),
                  onPressed: () => TtsService.pause(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                );
              }

              return IconButton(
                icon: Icon(
                    state == AppTtsState.paused
                        ? Icons.play_circle_filled
                        : Icons.volume_up,
                    color: AppColors.primary,
                    size: 32),
                onPressed:  () {
                    // If only one word is selected, pass isWord: true
                    bool isSingleWord = selectedWordIndices.length <= 3;
                    TtsService.speak(currentOriginalText, isWord: isSingleWord);
                  },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.error, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Error",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _closeOverlay,
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              errorCode == 'NEED_PERMISSION'
                  ? "Permission lost. Tap below to Restore Access."
                  : "An error occurred.",
              textAlign: TextAlign.center,
            ),
            if (errorCode == 'NEED_PERMISSION')
              TextButton(
                onPressed: () {
                  FlutterOverlayWindow.shareData(
                      {'action': 'open_app_request'});
                  _closeOverlay();
                },
                child: const Text("Fix Permission"),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
