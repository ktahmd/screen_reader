import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:screen_reader/core/helpers/colors.dart';
import 'core/helpers/theme_helper.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/overlay_provider.dart';
import 'core/services/ocr_service.dart';
import 'core/services/screen_capture_service.dart';
import 'features/homeScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OverlayProvider()),
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

// class OverlayContentWidget extends StatelessWidget {
//   const OverlayContentWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // This is where your floating icon/extracted text logic goes
//     return Material(
//       color: Colors.transparent,
//       child: GestureDetector(
//         onTap: () async {
//           // Logic to switch between scanner icon and mic icon
//           // await FlutterOverlayWindow.closeOverlay();
//         },
//         onDoubleTap: () => {},// Logic to open translation screen or perform translation
//         child: Container(
//           width: 120,
//           height: 120,
//           decoration:
//               const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
//           child: const Icon(Icons.qr_code_scanner, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }

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
    // Listen for the Main App radioing back the text
    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is Map && event['action'] == 'result') {
        setState(() {
          extractedText = event['text'];
          showText = true;
          isProcessing = false;
        });
        // Make the floating window bigger to show the text
        await FlutterOverlayWindow.resizeOverlay(350, 500,false);
      } else if (event is Map && event['action'] == 'error') {
        setState(() {
          isProcessing = false;
        });
      }
    });
  }

  void _performCaptureAndOcr() {
    setState(() {
      isProcessing = true;
    });
    // Send message to Main App: "Take a screenshot!"
    FlutterOverlayWindow.shareData({'action': 'capture'});
  }

  void _closeTextWindow() async {
    setState(() {
      showText = false;
      extractedText = "";
    });
    // Shrink the window back to the small circle
    await FlutterOverlayWindow.resizeOverlay(120, 120,false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: showText 
        ? _buildTextResultCard() 
        : _buildScannerButton(),
    );
  }

  // --- UI: The Small Floating Button ---
  Widget _buildScannerButton() {
    return GestureDetector(
      onDoubleTap: isProcessing ? null : _performCaptureAndOcr,
      child: Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: AppColors.primary, 
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: isProcessing 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : const Icon(Icons.qr_code_scanner, color: Colors.white, size: 50),
      ),
    );
  }

  // --- UI: The Large White Text Window ---
  Widget _buildTextResultCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Extracted Text", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _closeTextWindow,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          ),
          
          // Extracted Text Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                extractedText.isEmpty ? "No text found on screen." : extractedText,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
