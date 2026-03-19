import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/helpers/colors.dart';
import '../core/services/screen_capture_service.dart';

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

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is Map) {
        final String action = event['action'].toString();
        if (action == 'capture') return;

        if (action == 'result') {
          setState(() {
            words = event['words'] as List<dynamic>;
            showWords = true;
            isProcessing = false;
            errorCode = null;
          });
          // RESIZE TO FULL SCREEN
          // -1 means match_parent in Android
          await FlutterOverlayWindow.resizeOverlay(-1, -1, true);
        } else if (action == 'error') {
          setState(() {
            isProcessing = false;
            errorCode = event['errorCode']?.toString();
            showWords = true; // Show error card
          });
          await FlutterOverlayWindow.resizeOverlay(350, 250, true);
        }
      }
    });
  }

  void _performCapture() {
    setState(() { isProcessing = true; errorCode = null; });
    FlutterOverlayWindow.shareData({'action': 'capture'});
  }

  void _closeOverlay() async {
    setState(() {
      showWords = false;
      words = [];
      errorCode = null;
    });
    // Shrink back to small button
    await FlutterOverlayWindow.resizeOverlay(120, 120, true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: showWords ? _buildFullScreenOverlay() : _buildScannerButton(),
    );
  }

  Widget _buildScannerButton() {
    return Center( // Center within the 120x120 area
      child: GestureDetector(
        onDoubleTap: isProcessing ? null : _performCapture,
        child: Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: isProcessing
              ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Icon(Icons.remove_red_eye, color: Colors.white, size: 35),
        ),
      ),
    );
  }

  Widget _buildFullScreenOverlay() {
    return Stack(
      children: [
        // 1. The positioned words
        ...words.map((w) => Positioned(
              left: (w['x'] as num).toDouble(),
              top: (w['y'] as num).toDouble(),
              child: GestureDetector(
                onTap: () => _showWordDetail(w['text']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  color: Colors.white,
                  child: Text(
                    w['text'],
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14, // You might need to scale this
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            )),

        // 2. Error Message (if any)
        if (errorCode != null) _buildErrorCard(),

        // 3. The Control Bar (Mic and Close)
        if (errorCode == null) Positioned(
          bottom: 50,
          left: 0, right: 0,
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
                    icon: const Icon(Icons.mic, color: Colors.white, size: 30),
                    onPressed: () { /* Placeholder for TTS */ },
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
      ],
    );
  }

  void _showWordDetail(String word) {
    // Logic for translation popup will go here
    debugPrint("Clicked word: $word");
  }

  Widget _buildErrorCard() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorCode == 'NEED_PERMISSION' ? "Permission Lost" : "Error Occurred",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                  FlutterOverlayWindow.shareData({'action': 'open_app_request'});
                  _closeOverlay(); 
              },
              child: const Text("Tap to Restore Access"),
            ),
            ElevatedButton(onPressed: _closeOverlay, child: const Text("Close"))
          ],
        ),
      ),
    );
  }
}