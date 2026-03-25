import 'package:flutter/widgets.dart';

import '../../../../../models/tts_dialog_configs.dart';
import '../../../../../providers/settings_provider.dart';
import '../../../../../services/tts/tts_service.dart';
import 'base_config_dialog.dart';

class ElevenLabsConfigDialog extends StatelessWidget {
  final SettingsProvider settings;
  const ElevenLabsConfigDialog({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return BaseTtsConfigDialog(
      config: TtsDialogConfig(
        title: "ElevenLabs Config",
        apiKeyLabel: "XI-API-KEY",
        initialApiKey: settings.elevenLabsApiKey ?? "",
        initialModelId: settings.elevenLabsModelId,
        initialVoiceId: settings.elevenLabsVoiceId,
        fetchModels: (key) => TtsService.fetchElevenLabsModels(key),
        fetchVoices: (key) async => await TtsService.fetchElevenLabsVoices(key),
        onSave: (key, model, voice) => settings.updateElevenLabsConfig(key, model, voice),
      ),
    );
  }
}
