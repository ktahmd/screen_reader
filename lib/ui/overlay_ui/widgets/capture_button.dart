// lib/overlay_ui/overlay/widgets/capture_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/overlay_screen_provider.dart';

class CaptureButton extends StatelessWidget {
  const CaptureButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OverlayScreenProvider>();

    return SizedBox(
      width: 60,
      height: 60,
      child: Center(
        child: GestureDetector(
          onDoubleTap: provider.isProcessing ? null : provider.performCapture,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: provider.isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Icon(Icons.remove_red_eye, color: Colors.white),
          ),
        ),
      ),
    );
  }
}