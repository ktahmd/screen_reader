import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/platform_channel_service.dart';

class OverlayProvider extends ChangeNotifier {
  final PlatformChannelService _platformService;
  bool _isOverlayActive = false;
  bool get isOverlayActive => _isOverlayActive;


  OverlayProvider(this._platformService) {
    _syncStatus();
  }

  Future<void> _syncStatus() async {
    _isOverlayActive = await FlutterOverlayWindow.isActive();
    notifyListeners();
  }

  Future<void> startOverlay() async {
    try {
      final bool isOverlayGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isOverlayGranted) {
        await FlutterOverlayWindow.requestPermission();
        return;
      }


      final bool isCaptureGranted = await _platformService.requestPermission();
      if (!isCaptureGranted) {
        debugPrint("Screen capture permission was denied by the user.");
        return;
      }

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
    // REFACTORED: Use the service
    await _platformService.stopProjection();
    _isOverlayActive = false;
    notifyListeners();
  }
}