import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'core/helpers/theme_helper.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/overlay_provider.dart';
import 'core/services/ocr_service.dart';
import 'core/services/screen_capture_service.dart';
import 'features/homeScreen.dart';
import 'overlay/overlay.dart';

// --- BACKGROUND ENGINE ---
@pragma("vm:entry-point")
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterOverlayWindow.overlayListener.listen((event) async {
    if (event is Map && event['action'] == 'capture') {
      debugPrint("🤖 BACKGROUND ENGINE: Taking screenshot...");
      
      final bytes = await ScreenCaptureService.captureScreen();
      
      if (bytes != null) {
        final text = await OcrService.extractText(bytes);
        FlutterOverlayWindow.shareData({'action': 'result', 'text': text});
      } else {
        FlutterOverlayWindow.shareData({'action': 'error'});
      }
    }
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OverlayProvider(), lazy: false),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode, 
            theme: appTheme(Brightness.light),
            darkTheme: appTheme(Brightness.dark),
            home: const HomeScreen(),
          );
        },
      ),
    ),
  );
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayContentWidget(),
  ));
}


