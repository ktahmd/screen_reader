// lib/ui/overlay_ui/widgets/full_overlay_layer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/overlay_screen_provider.dart';
import 'word_painter.dart'; // New import
import 'translation_popup.dart';
import 'error_card.dart';

class FullOverlayLayer extends StatelessWidget {
  const FullOverlayLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OverlayScreenProvider>();
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Stack(
      children: [
        // 1. Unified Gesture and Paint Layer
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (details) => provider.handleTapAt(details.localPosition, pixelRatio),
            onDoubleTap: provider.closeOverlay,
            onPanStart: (details) => provider.handlePanStart(details.localPosition),
            onPanUpdate: (details) => provider.handlePanUpdate(details.localPosition, pixelRatio),
            onPanEnd: (details) => provider.handlePanEnd(),
            child: CustomPaint(
              painter: WordPainter(
                words: provider.words,
                selectedIndices: provider.selectedWordIndices,
                dragIndices: provider.dragIndices,
                pixelRatio: pixelRatio,
              ),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // 2. Drag Selection Rectangle (Visual Guide)
        if (provider.dragStart != null && provider.dragCurrent != null)
          Positioned.fromRect(
            rect: Rect.fromPoints(provider.dragStart!, provider.dragCurrent!),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
            ),
          ),

        // 3. UI Components (Popups, Buttons)
        if (provider.selectedWordIndices.isNotEmpty && provider.dragStart == null)
          Positioned(bottom: provider.isExpanded ? 150 : 120, left: 10, right: 10, 
            child: const TranslationPopup()),

        _buildBottomActions(provider),
        
        if (provider.errorCode != null) const ErrorCard(),
      ],
    );
  }

  Widget _buildBottomActions(OverlayScreenProvider provider) {
    return Positioned(
      bottom: 40, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(provider.selectedWordIndices.length == provider.words.length
                    ? Icons.deselect : Icons.select_all, color: Colors.white),
                onPressed: provider.toggleSelectAll,
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: provider.closeOverlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}