import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../core/helpers/colors.dart';

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
        final action = event['action'];

        if (action == 'result') {
          setState(() {
            words = event['words'] as List<dynamic>;
            showWords = true;
            isProcessing = false;
            errorCode = null;
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
    });

    FlutterOverlayWindow.shareData({'action': 'capture'});
  }

  void _closeOverlay() async {
    setState(() {
      showWords = false;
      words = [];
      errorCode = null;
    });

    await FlutterOverlayWindow.resizeOverlay(120, 120, true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: showWords ? _buildFullOverlay() : _buildButton(),
    );
  }

  // ---------- BUTTON ----------
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
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                : const Icon(Icons.remove_red_eye, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ---------- FULL OVERLAY ----------
  Widget _buildFullOverlay() {
    // This is the magic ratio between Camera Physical Pixels and Flutter Logical Pixels
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Stack(
      children: [
        // WORDS
        ...words.map((w) {
          final x = (w['x'] as num).toDouble() / pixelRatio;
          final y = (w['y'] as num).toDouble() / pixelRatio;
          final width = (w['w'] as num).toDouble() / pixelRatio;
          final height = (w['h'] as num).toDouble() / pixelRatio;

          return Positioned(
            left: x,
            top: y,
            width: width,   // Constrain the box to the exact width ML Kit found
            height: height, // Constrain the box to the exact height ML Kit found
            child: GestureDetector(
              onTap: () => _showWordDetail(w['text']),
              child: Container(
                color: Colors.white, // Solid white background
                child: FittedBox(
                  fit: BoxFit.contain, // Stretches/shrinks text to fill the exact box size!
                  child: Text(
                    w['text'],
                    style: TextStyle( color: Colors.black, fontWeight: FontWeight.bold,),
                  ),
                ),
              ),
            ),
          );
        }),

        // CONTROL BAR (Mic and Close)
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
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
                    onPressed: () {
                      // Placeholder for TTS
                    },
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

  void _showWordDetail(String word) {
    debugPrint("Clicked: $word");
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
                  const Text("Error",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _closeOverlay,
                  )
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Permission lost. Tap to Restore Access",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),

            TextButton(
              onPressed: () {
                FlutterOverlayWindow.shareData({'action': 'open_app_request'});
                _closeOverlay();
              },
              child: const Text("Fix Permission"),
            ),
          ],
        ),
      ),
    );
  }

}