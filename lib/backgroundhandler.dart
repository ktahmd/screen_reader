import 'core/constants/overlay_actions.dart';
import 'services/ocr_service.dart';
import 'services/platform_channel_service.dart';
import 'services/share_data_service.dart';


class BackgroundIsolateHandler {
  static void start() {
    final platformService = PlatformChannelService();

    OverlayShareDataService.messageStream.listen((event) async {
      if (event is! Map<String, dynamic>) return;
      
      switch (event['action']) {
        case OverlayActions.capture:
          _handleCapture(platformService);
          break;
        case OverlayActions.openAppRequest:
          platformService.openApp();
          break;
      }
    });
  }

  static Future<void> _handleCapture(PlatformChannelService service) async {
    try {
      final bytes = await service.captureScreen();
      if (bytes != null) {
        final words = await OcrService.extractTextDetailed(bytes);
        await OverlayShareDataService.sendOcrResults(words);
      } else {
        await OverlayShareDataService.sendError('CAPTURE_FAILED');
      }
    } catch (e) {
      await OverlayShareDataService.sendError(e.toString());
    }
  }
}