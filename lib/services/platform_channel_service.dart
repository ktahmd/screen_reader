import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.screen_reader/capture');

  Future<bool> requestPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestPermission');
      return result;
    } catch (e) {
      debugPrint("Error requesting permission: $e");
      return false;
    }
  }

  Future<Uint8List?> captureScreen() async {
    return await _channel.invokeMethod<Uint8List>('captureScreen');
  }

  Future<void> openApp() async {
    await _channel.invokeMethod('openApp');
  }

  Future<void> stopProjection() async {
    await _channel.invokeMethod('stopProjection');
  }
}