import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/overlay_actions.dart';
import '../../../providers/overlay_screen_provider.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OverlayScreenProvider>();

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.error, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Error",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: provider.closeOverlay,
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.errorCode == 'NEED_PERMISSION'
                  ? "Permission lost. Tap below to Restore Access."
                  : "An error occurred: ${provider.errorCode}",
              textAlign: TextAlign.center,
            ),
            if (provider.errorCode == 'NEED_PERMISSION')
              TextButton(
                onPressed: () {
                  FlutterOverlayWindow.shareData({'action': OverlayActions.openAppRequest});
                  provider.closeOverlay();
                },
                child: const Text("Fix Permission"),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}