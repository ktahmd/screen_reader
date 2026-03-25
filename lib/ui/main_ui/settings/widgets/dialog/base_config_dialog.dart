import 'package:flutter/material.dart';
import '../../../../../models/base_voice_model.dart';
import '../../../../../models/tts_dialog_configs.dart';
import '../../../../../services/audios/audio_preview_service.dart';
import '../voice_selection_list.dart';

class BaseTtsConfigDialog extends StatefulWidget {
  final TtsDialogConfig config;
  const BaseTtsConfigDialog({super.key, required this.config});

  @override
  State<BaseTtsConfigDialog> createState() => _BaseTtsConfigDialogState();
}

class _BaseTtsConfigDialogState extends State<BaseTtsConfigDialog> {
  final AudioPreviewService _previewService = AudioPreviewService();
  late TextEditingController _keyController;
  late String _selectedVoiceId;
  String? _selectedModelId;
  
  List<Map<String, String>> _availableModels = [];
  List<BaseVoiceModel> _availableVoices = []; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.config.initialApiKey);
    _selectedVoiceId = widget.config.initialVoiceId;
    _selectedModelId = widget.config.initialModelId;
    if (_keyController.text.isNotEmpty) _loadData();
  }

  Future<void> _loadData() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.config.fetchModels(key),
        widget.config.fetchVoices(key),
      ]);
      setState(() {
        _availableModels = results[0] as List<Map<String, String>>;
        _availableVoices = results[1] as List<BaseVoiceModel>;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _previewService.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.config.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: widget.config.apiKeyLabel,
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
              ),
            ),
            if (_isLoading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            
            if (_availableModels.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                decoration: const InputDecoration(labelText: "Select AI Model"),
                items: _availableModels.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedModelId = val),
              ),
            ],

            const SizedBox(height: 15),
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
            widget.config.onSave(_keyController.text.trim(), _selectedModelId ?? "", _selectedVoiceId);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}