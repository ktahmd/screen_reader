import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:screen_reader/core/helpers/colors.dart';
import 'core/helpers/theme_helper.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/overlay_provider.dart';
import 'core/services/ocr_service.dart';
import 'core/services/screen_capture_service.dart';
import 'features/homeScreen.dart';

// --- NEW: THE UNSTOPPABLE BACKGROUND ENGINE ---
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
      child: const MyApp(),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode, 
          theme: appTheme(Brightness.light),
          darkTheme: appTheme(Brightness.dark),
          home: const HomeScreen(),
        );
      },
    );
  }
}

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