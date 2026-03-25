import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/overlay_screen_provider.dart';
import '../../../services/tts/tts_service.dart';

class TranslationPopup extends StatelessWidget {
  const TranslationPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OverlayScreenProvider>();
    bool needsExpansion = provider.currentOriginalText.length > 45 || provider.currentTranslatedText.length > 45;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(
        maxHeight: provider.isExpanded ? MediaQuery.of(context).size.height * 0.5 : 100,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (needsExpansion)
            IconButton(
              icon: Icon(provider.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
              onPressed: provider.toggleExpanded,
            )
          else
            const SizedBox(width: 48),

          const SizedBox(width: 5),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.currentOriginalText,
                    maxLines: provider.isExpanded ? null : 1,
                    overflow: provider.isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  if (provider.isTranslating)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        provider.currentTranslatedText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: provider.isExpanded ? null : 1,
                        overflow: provider.isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // Sound Controls
          ValueListenableBuilder<AppTtsState>(
            valueListenable: TtsService.stateNotifier,
            builder: (context, state, child) {
              if (state == AppTtsState.loading) {
                return const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (state == AppTtsState.playing) {
                return IconButton(
                  icon: const Icon(Icons.pause_circle_filled, color: AppColors.primary, size: 32),
                  onPressed: () => TtsService.pause(),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                );
              }
              return IconButton(
                icon: Icon(state == AppTtsState.paused ? Icons.play_circle_filled : Icons.volume_up, color: AppColors.primary, size: 32),
                onPressed: provider.playTts,
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              );
            },
          ),
        ],
      ),
    );
  }
}