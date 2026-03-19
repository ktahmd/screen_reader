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

  double imgW = 1;
  double imgH = 1;

  @override
  void initState() {
    super.initState();

    FlutterOverlayWindow.overlayListener.listen((event) async {
      if (event is Map) {
        final action = event['action'];

        if (action == 'result') {
          final data = event['data'];

          setState(() {
            words = data['words'] as List<dynamic>;
            imgW = (data['imgW'] as num).toDouble();
            imgH = (data['imgH'] as num).toDouble();
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
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.remove_red_eye, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ---------- FULL OVERLAY ----------
  Widget _buildFullOverlay() {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    final scaleX = screenW / imgW;
    final scaleY = screenH / imgH;

    return Stack(
      children: [
        // WORDS
        ...words.map((w) {
          final x = (w['x'] as num).toDouble();
          final y = (w['y'] as num).toDouble();
          final h = (w['h'] as num).toDouble();

          return Positioned(
            left: x * scaleX,
            top: y * scaleY,
            child: GestureDetector(
              onTap: () => _showWordDetail(w['text']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                color: Colors.white,
                child: Text(
                  w['text'],
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: h * scaleY * 0.8,
                  ),
                ),
              ),
            ),
          );
        }),

        // TOP CARD
        // Positioned(
        //   top: 40,
        //   left: 20,
        //   right: 20,
        //   child: SizedBox(
        //     height: 250,
        //     child: _buildTextResultCard(),
        //   ),
        // ),

        // CONTROL BAR
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
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white, size: 30),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
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

  // ---------- CARD ----------
  // Widget _buildTextResultCard() {
  //   final fullText = words.map((e) => e['text']).join(' ');

  //   return Container(
  //   decoration: BoxDecoration(
  //     color: Colors.white,
  //     borderRadius: BorderRadius.circular(15),
  //     border: Border.all(color: AppColors.primary, width: 2),
  //     boxShadow: const [
  //       BoxShadow(color: Colors.black26, blurRadius: 10)
  //     ],
  //   ),
  //   child: Column(
  //     children: [
  //       Container(
  //         padding:
  //             const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //         decoration: const BoxDecoration(
  //           color: AppColors.primary,
  //           borderRadius:
  //               BorderRadius.vertical(top: Radius.circular(12)),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Text("Extracted Text",
  //                 style: TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.bold)),
  //             IconButton(
  //               icon: const Icon(Icons.close, color: Colors.white),
  //               onPressed: _closeOverlay,
  //             )
  //           ],
  //         ),
  //       ),
  //       Expanded(
  //         child: SingleChildScrollView(
  //           padding: const EdgeInsets.all(16),
  //           child: Text(
  //             fullText.isEmpty
  //                 ? "No text found on screen."
  //                 : fullText,
  //             style:
  //                 const TextStyle(color: Colors.black, fontSize: 16),
  //           ),
  //         ),
  //       ),
  //     ],
  //   ),
  // );
  // }

  void _showWordDetail(String word) {
    debugPrint("Clicked: $word");
  }

  Widget _buildErrorCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.error, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Error",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _closeOverlay,
                    )
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Permission lost. Tap to Restore Access",
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      FlutterOverlayWindow.shareData(
                          {'action': 'open_app_request'});
                      _closeOverlay();
                    },
                    child: const Text("Fix Permission"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
