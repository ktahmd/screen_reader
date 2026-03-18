import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../services/ocr_service.dart';
import '../services/screen_capture_service.dart';

class OverlayProvider extends ChangeNotifier {
  bool _isOverlayActive = false;
  bool get isOverlayActive => _isOverlayActive;
  
  // OverlayProvider() {
  //   FlutterOverlayWindow.overlayListener.listen((event) async {
  //     // If the overlay radios us saying "capture":
  //     if (event is Map && event['action'] == 'capture') {
        
  //       // 1. Take the screenshot (Main App does this safely)
  //       final bytes = await ScreenCaptureService.captureScreen();
        
  //       if (bytes != null) {
  //         // 2. Extract the text
  //         final text = await OcrService.extractText(bytes);
          
  //         // 3. Radio the text BACK to the Overlay
  //         FlutterOverlayWindow.shareData({'action': 'result', 'text': text});
  //       } else {
  //         // Tell overlay it failed
  //         FlutterOverlayWindow.shareData({'action': 'error'});
  //       }
  //     }
  //   });
  // }

Future<void> startOverlay() async {
    try {
      // Floating Window Permission
      final bool isOverlayGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isOverlayGranted) {
        await FlutterOverlayWindow.requestPermission();
        return; // Exit if permission is not granted, user needs to trigger again after granting
      }

      // MediaProjection Permission 
      final bool isCaptureGranted = await ScreenCaptureService.requestPermission();
      
      if (!isCaptureGranted) {
        debugPrint("Screen capture permission was denied by the user.");
        return; 
      }



      // 3. Show the Floating Window
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Translator",
        width: 120,
        height: 120,
        alignment: OverlayAlignment.centerRight,
        visibility: NotificationVisibility.visibilityPublic,
        startPosition: const OverlayPosition(60, 100),
      );
      
      _isOverlayActive = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error starting overlay: $e");
    }
  }
  Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    await ScreenCaptureService.stopProjection();
    _isOverlayActive = false;
    notifyListeners();
  }
}
