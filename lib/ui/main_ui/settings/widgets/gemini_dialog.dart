// lib/main_ui/settings/widgets/gemini_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/default_settings.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../services/tts/tts_service_core.dart';


class GeminiConfigDialog extends StatefulWidget {
  final SettingsProvider settings;
  const GeminiConfigDialog({super.key, required this.settings});

  @override
  State<GeminiConfigDialog> createState() => _GeminiConfigDialogState();
}

class _GeminiConfigDialogState extends State<GeminiConfigDialog> {
  late TextEditingController _keyController;
  late String _selectedVoice;
  String? _selectedModelId;
  List<Map<String, String>> _availableModels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.settings.geminiApiKey);
    _selectedVoice = widget.settings.geminiVoice;
    _selectedModelId = widget.settings.geminiModelTextToSpeechId;
    if (_keyController.text.isNotEmpty) _fetchModels();
  }

  Future<void> _fetchModels() async {
    if (_keyController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final models = await TtsService.fetchGeminiModels(_keyController.text.trim());
    
    if (mounted) {
      setState(() {
        _availableModels = models;
        if (models.isNotEmpty && !models.any((m) => m['id'] == _selectedModelId)) {
          _selectedModelId = models.first['id'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Gemini TTS Config"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: "Gemini API Key",
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchModels),
              ),
            ),
            const SizedBox(height: 15),
            if (_isLoading) 
              const CircularProgressIndicator()
            else if (_availableModels.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Model"),
                items: _availableModels.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedModelId = val),
              ),
            const SizedBox(height: 15),
              DropdownButtonFormField<String>(
              value: _selectedVoice,
              decoration: const InputDecoration(labelText: "Voice"),
              items: GeminiVoices.all.map((voiceName) => DropdownMenuItem(
                value: voiceName, 
                child: Text(voiceName.toUpperCase())
              )).toList(),
              onChanged: (val) { if (val != null) setState(() => _selectedVoice = val); },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            widget.settings.updateGeminiConfig(
              _keyController.text.trim(), 
              _selectedModelId ?? DefaultSettings.geminiModelTextToSpeechId, 
              _selectedVoice,
            );
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}