import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/helpers/colors.dart';
import '../core/services/translator_service.dart';

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

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is Map) {
        final action = event['action'];

        if (action == 'result') {
          setState(() {
            words = event['words'] as List<dynamic>;
            showWords = true;
            isProcessing = false;
            errorCode = null;
            _clearSelection(); 
          });
          await FlutterOverlayWindow.moveOverlay(const OverlayPosition(0, 0));
          await FlutterOverlayWindow.resizeOverlay(-1, -1, false);
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

  void _toggleSelectAll() {
    // If everything is already selected, clear it. Otherwise, select everything.
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

    final translated = await TranslationService.translateText(combinedText, from: 'en', to: 'ar');

    if (selectedWordIndices.isNotEmpty) {
      setState(() {
        currentTranslatedText = translated;
        isTranslating = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      selectedWordIndices.clear();
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
      width: 60, height: 60,
      child: Center(
        child: GestureDetector(
          onDoubleTap: isProcessing ? null : _performCapture,
          child: Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: isProcessing
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
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
            child: Container(color: Colors.transparent),
          ),
        ),

        ...words.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> w = entry.value;
          final bool isSelected = selectedWordIndices.contains(index);

          final x = (w['x'] as num).toDouble() / pixelRatio - 8;
          final y = (w['y'] as num).toDouble() / pixelRatio - 15;
          final width = (w['w'] as num).toDouble() / pixelRatio + 6;
          final height = (w['h'] as num).toDouble() / pixelRatio + 6;

          return Positioned(
            left: x, top: y, width: width, height: height,
            child: GestureDetector(
              onTap: () => _toggleWordSelection(index),
              child: Container(
                color: isSelected ? AppColors.primary.withOpacity(0.9) : Colors.white,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    w['text'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        if (selectedWordIndices.isNotEmpty)
          Positioned(
            bottom: 120, left: 20, right: 20,
            child: _buildTranslationPopup(),
          ),

        Positioned(
          bottom: 50, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    // Changed to select_all icon
                    icon: Icon(
                      selectedWordIndices.length == words.length ? Icons.deselect : Icons.select_all, 
                      color: Colors.white, 
                      size: 30
                    ),
                    onPressed: _toggleSelectAll,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: _closeOverlay,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (errorCode != null) _buildErrorCard(),
      ],
    );
  }

  Widget _buildTranslationPopup() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, 
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      currentOriginalText,
                      style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: AppColors.primary, size: 28), // Volume/Mic icon
                    onPressed: () {
                      debugPrint("Reading aloud: $currentOriginalText");
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),
              
              isTranslating
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ))
                  : Text(
                      currentTranslatedText,
                      style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
            ],
          ),
        ),
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
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10)
          ],
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
                  const Text("Error", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
                  FlutterOverlayWindow.shareData({'action': 'open_app_request'});
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