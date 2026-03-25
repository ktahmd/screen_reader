// lib/overlay_ui/overlay/overlay_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/overlay_screen_provider.dart';
import 'widgets/capture_button.dart';
import 'widgets/full_overlay_layer.dart';


class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OverlayScreenProvider>();

    return Material(
      color: Colors.transparent,
      child: provider.showWords 
          ? const FullOverlayLayer() 
          : const CaptureButton(),
    );
  }
}