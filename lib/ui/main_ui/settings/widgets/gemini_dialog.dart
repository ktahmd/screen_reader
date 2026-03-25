import 'package:flutter/material.dart';
import '../../../../core/constants/default_settings.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../services/tts/tts_service.dart';
import '../../../../services/audios/audio_preview_service.dart';
import 'voice_selection_list.dart';

class GeminiConfigDialog extends StatefulWidget {
  final SettingsProvider settings;
  const GeminiConfigDialog({super.key, required this.settings});

  @override
  State<GeminiConfigDialog> createState() => _GeminiConfigDialogState();
}

class _GeminiConfigDialogState extends State<GeminiConfigDialog> {
  final AudioPreviewService _previewService = AudioPreviewService();
  late TextEditingController _keyController;
  late String _selectedVoiceId;
  String? _selectedModelId;
  List<Map<String, String>> _availableModels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.settings.geminiApiKey);
    _selectedVoiceId = widget.settings.geminiVoice;
    _selectedModelId = widget.settings.geminiModelTextToSpeechId;
    if (_keyController.text.isNotEmpty) _fetchModels();
  }

  @override
  void dispose() {
    _previewService.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    if (_keyController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final models = await TtsService.fetchGeminiModels(_keyController.text.trim());
    setState(() {
      _availableModels = models;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Gemini TTS Config"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: "API Key",
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchModels),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading) const LinearProgressIndicator(),
            if (_availableModels.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                items: _availableModels.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedModelId = val),
              ),
            const SizedBox(height: 15),
            VoiceSelectionList(
              voices: GeminiVoices.all, 
              selectedVoiceId: _selectedVoiceId,
              previewService: _previewService,
              onVoiceSelected: (id) => setState(() => _selectedVoiceId = id),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            widget.settings.updateGeminiConfig(_keyController.text.trim(), 
              _selectedModelId ?? DefaultSettings.geminiModelTextToSpeechId, _selectedVoiceId);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}