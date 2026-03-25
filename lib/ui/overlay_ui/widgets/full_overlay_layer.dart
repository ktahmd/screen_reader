import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/overlay_screen_provider.dart';
import 'error_card.dart';
import 'translation_popup.dart';
class FullOverlayLayer extends StatelessWidget {
  const FullOverlayLayer({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider for state changes
    final provider = context.watch<OverlayScreenProvider>();
    
    // Pixel ratio math (kept exactly as you had it)
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Stack(
      children: [
        // 1. The transparent background that detects dragging
        Positioned.fill(
          child: GestureDetector(
            onTap: provider.clearSelection,
            onDoubleTap: provider.closeOverlay,
            onPanStart: (details) => provider.handlePanStart(details.localPosition),
            onPanUpdate: (details) => provider.handlePanUpdate(details.localPosition, pixelRatio),
            onPanEnd: (details) => provider.handlePanEnd(),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 2. The Extracted Words
        ...provider.words.asMap().entries.map((entry) {
          final int index = entry.key;
          final w = entry.value;

          final bool isSelected = provider.selectedWordIndices.contains(index) ||
              provider.dragSelectedIndices.contains(index);
          final adjustedRect = w.getAdjustedRect(pixelRatio);

          return Positioned(
            left: adjustedRect.left,
            top: adjustedRect.top,
            width: adjustedRect.width,
            height: adjustedRect.height,
            child: GestureDetector(
              onTap: () {
                provider.clearSelection();
                provider.toggleWordSelection(index);
              },
              onLongPress: () => provider.toggleWordSelection(index),
              child: Container(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white.withOpacity(0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    w.text,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0)
                          : Colors.black.withOpacity(0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        // 3. The Drag Selection Rectangle (Blue outline)
        if (provider.dragStart != null && provider.dragCurrent != null)
          Positioned.fromRect(
            rect: Rect.fromPoints(provider.dragStart!, provider.dragCurrent!),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),

        // 4. The Translation Popup (Appears when words are selected)
        if (provider.selectedWordIndices.isNotEmpty && provider.dragStart == null)
          Positioned(
            bottom: provider.isExpanded ? 150 : 120,
            left: 10,
            right: 10,
            child: const TranslationPopup(), 
          ),

        // 5. The Bottom Control Bar (Select All / Close)
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        provider.selectedWordIndices.length == provider.words.length
                            ? Icons.deselect
                            : Icons.select_all,
                        color: Colors.white,
                      ),
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
          ),
        ),

        // 6. The Error Card (If something goes wrong)
        if (provider.errorCode != null) 
          const ErrorCard(),
      ],
    );
  }
}