
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
  bool showText = false;
  String extractedText = "";

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is Map) {
        final String action = event['action'].toString();
        
        // Ignore our own echo!
        if (action == 'capture') return; 
        
        if (action == 'result') {
          setState(() {
            extractedText = event['text'].toString();
            showText = true;
            isProcessing = false;
          });
          await FlutterOverlayWindow.resizeOverlay(350, 500, true);
        } else if (action == 'error') {
          setState(() {
            isProcessing = false;
            extractedText = "Failed to capture. Please try again.";
            showText = true;
          });
          await FlutterOverlayWindow.resizeOverlay(350, 200, true);
        }
      }
    });
  }

  void _performCaptureAndOcr() {
    setState(() { isProcessing = true; });
    FlutterOverlayWindow.shareData({'action': 'capture'});
  }

  void _closeTextWindow() async {
    setState(() { showText = false; extractedText = ""; });
    await FlutterOverlayWindow.resizeOverlay(120, 120, true);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: showText ? _buildTextResultCard() : _buildScannerButton(),
    );
  }

  Widget _buildScannerButton() {
    return GestureDetector(
      onDoubleTap: isProcessing ? null : _performCaptureAndOcr,
      child: Container(
        width: 120, height: 120,
        decoration: const BoxDecoration(
          color: AppColors.primary, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: isProcessing 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : const Icon(Icons.qr_code_scanner, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildTextResultCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Extracted Text", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _closeTextWindow, padding: EdgeInsets.zero, constraints: const BoxConstraints())
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(extractedText.isEmpty ? "No text found on screen." : extractedText, style: const TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}