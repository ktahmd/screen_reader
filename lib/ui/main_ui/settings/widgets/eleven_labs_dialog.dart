import 'package:flutter/material.dart';
import '../../../../core/constants/default_settings.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../services/tts/tts_service_core.dart';

class ElevenLabsConfigDialog extends StatefulWidget {
  final SettingsProvider settings;
  const ElevenLabsConfigDialog({super.key, required this.settings});

  @override
  State<ElevenLabsConfigDialog> createState() => _ElevenLabsConfigDialogState();
}

class _ElevenLabsConfigDialogState extends State<ElevenLabsConfigDialog> {
  late TextEditingController _keyController;
  
  String? _selectedModelId;
  String? _selectedVoiceId;
  
  List<Map<String, String>> _availableModels = [];
  List<Map<String, String>> _availableVoices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.settings.elevenLabsApiKey);
    _selectedModelId = widget.settings.elevenLabsModelId;
    _selectedVoiceId = widget.settings.elevenLabsVoiceId;
    
    if (_keyController.text.isNotEmpty) _fetchConfigData();
  }

  Future<void> _fetchConfigData() async {
    if (_keyController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    final key = _keyController.text.trim();
    
    final results = await Future.wait([
      TtsService.fetchElevenLabsModels(key),
      TtsService.fetchElevenLabsVoices(key),
    ]);
    
    if (mounted) {
      setState(() {
        _availableModels = results[0];
        _availableVoices = results[1];
        
        // Use default from Constants if the current selection isn't in the new list
        if (_availableModels.isNotEmpty && !_availableModels.any((m) => m['id'] == _selectedModelId)) {
          _selectedModelId = _availableModels.first['id'];
        }
        if (_availableVoices.isNotEmpty && !_availableVoices.any((v) => v['id'] == _selectedVoiceId)) {
          _selectedVoiceId = _availableVoices.first['id'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("ElevenLabs Config"),
      content: SingleChildScrollView(
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
            const SizedBox(height: 15),
            if (_isLoading) 
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_availableModels.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedModelId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Model"),
                  items: _availableModels.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                  onChanged: (val) => setState(() => _selectedModelId = val),
                ),
              const SizedBox(height: 15),
              if (_availableVoices.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedVoiceId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Voice"),
                  items: _availableVoices.map((v) => DropdownMenuItem(value: v['id'], child: Text(v['name']!))).toList(),
                  onChanged: (val) => setState(() => _selectedVoiceId = val),
                ),
            ]
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
              _selectedVoiceId ?? DefaultSettings.elevenLabsVoiceId,
            );
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}