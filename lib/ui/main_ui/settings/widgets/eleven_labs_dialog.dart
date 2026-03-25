import 'package:flutter/material.dart';
import '../../../../core/constants/default_settings.dart';
import '../../../../models/voices/elevenlabs_voice_model.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../services/audios/audio_preview_service.dart';
import '../../../../services/tts/tts_service.dart';
import 'voice_selection_list.dart';

class ElevenLabsConfigDialog extends StatefulWidget {
  final SettingsProvider settings;
  const ElevenLabsConfigDialog({super.key, required this.settings});

  @override
  State<ElevenLabsConfigDialog> createState() => _ElevenLabsConfigDialogState();
}

class _ElevenLabsConfigDialogState extends State<ElevenLabsConfigDialog> {
  final AudioPreviewService _previewService = AudioPreviewService();
  late TextEditingController _keyController;
  late String _selectedVoiceId;
  String? _selectedModelId;
  
  List<Map<String, String>> _availableModels = [];
  List<ElevenLabsVoiceModel> _availableVoices = []; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.settings.elevenLabsApiKey);
    _selectedVoiceId = widget.settings.elevenLabsVoiceId;
    _selectedModelId = widget.settings.elevenLabsModelId;
    if (_keyController.text.isNotEmpty) _fetchConfigData();
  }

  @override
  void dispose() {
    _previewService.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _fetchConfigData() async {
    if (_keyController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final key = _keyController.text.trim();
    
    final results = await Future.wait([
      TtsService.fetchElevenLabsModels(key),
      TtsService.fetchElevenLabsVoices(key), // This now returns our model list
    ]);
    
    if (mounted) {
      setState(() {
        _availableModels = results[0] as List<Map<String, String>>;
        _availableVoices = results[1] as List<ElevenLabsVoiceModel>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("ElevenLabs Config"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: "API Key",
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchConfigData),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading) const LinearProgressIndicator(),

            if (_availableModels.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                decoration: const InputDecoration(labelText: "Model"),
                items: _availableModels.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedModelId = val),
              ),

            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Voice", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 5),

            VoiceSelectionList(
              voices: _availableVoices, 
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
            widget.settings.updateElevenLabsConfig(
              _keyController.text.trim(), 
              _selectedModelId ?? DefaultSettings.elevenLabsModelId, 
              _selectedVoiceId,
            );
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}