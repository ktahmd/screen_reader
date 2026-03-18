import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/overlay_provider.dart';
import 'widget/langButton.dart';
import 'widget/powerToggle.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {

  final Map<String, String> languageMap = {
    "English": "us",
    "Arabic": "sa",
    "Spanish": "es",
    "French": "fr",
    "German": "de",
  };

  String sourceLang = "English";
  String targetLang = "Arabic";

  void _showLanguagePicker(bool isSource) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: 300,
        child: ListView(
          children: languageMap.keys.map((lang) => ListTile(
            leading: CircleFlag(languageMap[lang]!, size: 30),
            title: Text(
              lang,
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              setState(() {
                isSource ? sourceLang = lang : targetLang = lang;
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlayProvider = Provider.of<OverlayProvider>(context);
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
                label: sourceLang,
                flagCode: languageMap[sourceLang]!,
                onTap: () => _showLanguagePicker(true),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    final temp = sourceLang;
                    sourceLang = targetLang;
                    targetLang = temp;
                  });
                },
                icon: Icon(
                  Icons.swap_horiz,
                  color: theme.colorScheme.primary,
                ),
              ),

              LanguageButton(
                label: targetLang,
                flagCode: languageMap[targetLang]!,
                onTap: () => _showLanguagePicker(false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}