import 'package:flutter/widgets.dart';

import '../../../../../core/constants/default_settings.dart';
import '../../../../../models/tts_dialog_configs.dart';
import '../../../../../providers/settings_provider.dart';
import '../../../../../services/tts/tts_service.dart';
import 'base_config_dialog.dart';


class GeminiConfigDialog extends StatelessWidget {
  final SettingsProvider settings;
  const GeminiConfigDialog({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return BaseTtsConfigDialog(
      config: TtsDialogConfig(
        title: "Gemini TTS Config",
        apiKeyLabel: "Google API Key",
        initialApiKey: settings.geminiApiKey ?? "",
        initialModelId: settings.geminiModelTextToSpeechId,
        initialVoiceId: settings.geminiVoice,
        fetchModels: (key) => TtsService.fetchGeminiModels(key),
        fetchVoices: (_) async => GeminiVoices.all, // Gemini voices are static
        onSave: (key, model, voice) => settings.updateGeminiConfig(key, model, voice),
      ),
    );
  }
}