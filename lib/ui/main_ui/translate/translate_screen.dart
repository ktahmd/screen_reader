import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/translation_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/overlay_provider.dart';

import 'widgets/langButton.dart';
import 'widgets/powerToggle.dart';

class TranslatorScreen extends StatelessWidget {
  const TranslatorScreen({super.key});

  void _showLanguagePicker(BuildContext context, bool isSource) {
    final theme = Theme.of(context);
    final translationProvider = context.read<TranslationProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: 300,
        child: ListView(
          children: AppConstants.languageMap.keys.map((lang) => ListTile(
            leading: CircleFlag(AppConstants.languageMap[lang]!, size: 30),
            title: Text(lang, style: theme.textTheme.bodyLarge),
            onTap: () {
              if (isSource) {
                translationProvider.setSourceLanguage(lang);
              } else {
                translationProvider.setTargetLanguage(lang);
              }
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to providers
    final overlayProvider = context.watch<OverlayProvider>();
    final translationProvider = context.watch<TranslationProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        PowerToggleSection(
          isActive: overlayProvider.isOverlayActive,
          onTap: () async {
            overlayProvider.isOverlayActive
                ? await overlayProvider.closeOverlay()
                : await overlayProvider.startOverlay();
          },
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              LanguageButton(
                label: translationProvider.sourceLang,
                flagCode: AppConstants.languageMap[translationProvider.sourceLang]!,
                onTap: () => _showLanguagePicker(context, true),
              ),
              IconButton(
                onPressed: () => context.read<TranslationProvider>().swapLanguages(),
                icon: Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
              ),
              LanguageButton(
                label: translationProvider.targetLang,
                flagCode: AppConstants.languageMap[translationProvider.targetLang]!,
                onTap: () => _showLanguagePicker(context, false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}