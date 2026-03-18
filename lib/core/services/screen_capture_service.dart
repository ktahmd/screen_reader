import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScreenCaptureService {
  // CHANNEL name in Kotlin
  static const MethodChannel _channel = MethodChannel('com.screen_reader/capture');

  static Future<bool> requestPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestPermission');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to request permission: '${e.message}'.");
      return false;
    }
  }

  static Future<Uint8List?> captureScreen() async {
    try {
      final Uint8List? imageBytes = await _channel.invokeMethod('captureScreen');
      return imageBytes;
    } on PlatformException catch (e) {
      debugPrint("Failed to capture screen: '${e.message}'.");
      return null;
    }
  }

   static Future<void> stopProjection() async {
    try {
      await _channel.invokeMethod('stopProjection');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop projection: '${e.message}'.");
    }
  }
}