import '../models/base_voice_model.dart';

class TtsDialogConfig {
  final String title;
  final String apiKeyLabel;
  final String initialApiKey;
  final String? initialModelId;
  final String initialVoiceId;
  final Future<List<Map<String, String>>> Function(String key) fetchModels;
  final Future<List<BaseVoiceModel>> Function(String key) fetchVoices;
  final Function(String key, String modelId, String voiceId) onSave;

  TtsDialogConfig({
    required this.title,
    required this.apiKeyLabel,
    required this.initialApiKey,
    this.initialModelId,
    required this.initialVoiceId,
    required this.fetchModels,
    required this.fetchVoices,
    required this.onSave,
  });
}