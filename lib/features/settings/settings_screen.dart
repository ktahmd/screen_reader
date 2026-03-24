import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/tts_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Voice Settings")),
      body: CustomScrollView(
        slivers:[
          SliverToBoxAdapter(child: _buildHeader("Reading Paragraphs")),
          _buildEngineList(context, settings.sentenceMode, false, settings),
          const SliverToBoxAdapter(child: Divider(height: 40)),
          SliverToBoxAdapter(child: _buildHeader("Short sentences (1-3 words)")),
          _buildEngineList(context, settings.wordMode, true, settings),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildEngineList(BuildContext context, TtsVoiceMode current, bool isWord, SettingsProvider settings) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _cuteTile(context, "Auto Mode", "Smart switching", Icons.auto_awesome, TtsVoiceMode.auto, current, isWord),
        _cuteTile(context, "Offline", "Fast & Data-free", Icons.cloud_off, TtsVoiceMode.offline, current, isWord),
        _cuteTile(context, isWord ? "Google TTS (Recommended)" : "Google TTS", "Standard Web Voice", Icons.g_translate, TtsVoiceMode.google, current, isWord),
        
        // ElevenLabs Tile
        _cuteTile(
          context, "ElevenLabs", "Advanced AI Voices", Icons.record_voice_over, TtsVoiceMode.elevenlabs, current, isWord,
          trailingWidgets:[
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.blue),
              onPressed: () => _showElevenLabsDialog(context, settings),
            ),
          ],
          errorMessage: "Please add an ElevenLabs API Key",
          onErrorAction: () => _showElevenLabsDialog(context, settings),
        ),
        
        // Gemini Tile
        _cuteTile(
          context, "Google Gemini", "AI Expressive Voices", Icons.auto_awesome_mosaic, TtsVoiceMode.gemini, current, isWord,
          trailingWidgets:[
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.blue),
              onPressed: () => _showGeminiDialog(context, settings),
            ),
          ],
          errorMessage: "Please add a Gemini API Key",
          onErrorAction: () => _showGeminiDialog(context, settings),
        ),
      ]),
    );
  }

  Widget _cuteTile(BuildContext context, String title, String sub, IconData icon, TtsVoiceMode mode, TtsVoiceMode current, bool isWord, {List<Widget>? trailingWidgets, String? errorMessage, VoidCallback? onErrorAction}) {
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(sub),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children:[
          ...?trailingWidgets,
          if (trailingWidgets != null) const SizedBox(width: 8),
          isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.circle_outlined),
        ],
      ),
      onTap: () async {
        bool success = await context.read<SettingsProvider>().updateMode(mode, isWord);
        if (!success && context.mounted) {
          Fluttertoast.showToast(msg: errorMessage ?? "Configuration required");
          if (onErrorAction != null) onErrorAction();
        }
      },
    );
  }

  void _showElevenLabsDialog(BuildContext context, SettingsProvider settings) {
    showDialog(context: context, builder: (ctx) => ElevenLabsConfigDialog(settings: settings));
  }

  void _showGeminiDialog(BuildContext context, SettingsProvider settings) {
    showDialog(context: context, builder: (ctx) => GeminiConfigDialog(settings: settings));
  }
}

// ================= DIALOG WIDGETS =================

class ElevenLabsConfigDialog extends StatefulWidget {
  final SettingsProvider settings;
  const ElevenLabsConfigDialog({super.key, required this.settings});
  @override
  State<ElevenLabsConfigDialog> createState() => _ElevenLabsConfigDialogState();
}

class _ElevenLabsConfigDialogState extends State<ElevenLabsConfigDialog> {
  late TextEditingController _keyController;
  late ElevenLabsVoice _selectedVoice;
  String? _selectedModelId;
  List<Map<String, String>> _availableModels =[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.settings.elevenLabsApiKey);
    _selectedVoice = widget.settings.elevenLabsVoice;
    _selectedModelId = widget.settings.elevenLabsModelId;
    if (_keyController.text.isNotEmpty) _fetchModels();
  }

  Future<void> _fetchModels() async {
    setState(() => _isLoading = true);
    final models = await TtsService.fetchElevenLabsModels(_keyController.text.trim());
    setState(() {
      _availableModels = models;
      if (models.isNotEmpty && !models.any((m) => m['id'] == _selectedModelId)) {
        _selectedModelId = models.first['id'];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("ElevenLabs Config"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: "API Key",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchModels),
              ),
            ),
            const SizedBox(height: 15),
            if (_isLoading) const CircularProgressIndicator()
            else if (_availableModels.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Model", border: OutlineInputBorder()),
                items: _availableModels.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedModelId = val),
              ),
            const SizedBox(height: 15),
            DropdownButtonFormField<ElevenLabsVoice>(
              value: _selectedVoice,
              decoration: const InputDecoration(labelText: "Voice", border: OutlineInputBorder()),
              items: ElevenLabsVoice.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name.toUpperCase()))).toList(),
              onChanged: (val) { if (val != null) setState(() => _selectedVoice = val); },
            ),
          ],
        ),
      ),
      actions:[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            widget.settings.updateElevenLabsConfig(_keyController.text.trim(), _selectedModelId ?? "eleven_flash_v2_5", _selectedVoice);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class GeminiConfigDialog extends StatefulWidget {
  final SettingsProvider settings;
  const GeminiConfigDialog({super.key, required this.settings});
  @override
  State<GeminiConfigDialog> createState() => _GeminiConfigDialogState();
}

class _GeminiConfigDialogState extends State<GeminiConfigDialog> {
  late TextEditingController _keyController;
  late GeminiVoice _selectedVoice;
  String? _selectedModelId;
  List<Map<String, String>> _availableModels =[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.settings.geminiApiKey);
    _selectedVoice = widget.settings.geminiVoice;
    _selectedModelId = widget.settings.geminiModelId;
    if (_keyController.text.isNotEmpty) _fetchModels();
  }

  Future<void> _fetchModels() async {
    setState(() => _isLoading = true);
    final models = await TtsService.fetchGeminiModels(_keyController.text.trim());
    setState(() {
      _availableModels = models;
      if (models.isNotEmpty && !models.any((m) => m['id'] == _selectedModelId)) {
        _selectedModelId = models.first['id'];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Gemini TTS Config"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: "Gemini API Key",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchModels),
              ),
            ),
            const SizedBox(height: 15),
            if (_isLoading) const CircularProgressIndicator()
            else if (_availableModels.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Model", border: OutlineInputBorder()),
                items: _availableModels.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                onChanged: (val) => setState(() => _selectedModelId = val),
              ),
            const SizedBox(height: 15),
            DropdownButtonFormField<GeminiVoice>(
              value: _selectedVoice,
              decoration: const InputDecoration(labelText: "Voice", border: OutlineInputBorder()),
              items: GeminiVoice.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name.toUpperCase()))).toList(),
              onChanged: (val) { if (val != null) setState(() => _selectedVoice = val); },
            ),
          ],
        ),
      ),
      actions:[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            widget.settings.updateGeminiConfig(_keyController.text.trim(), _selectedModelId ?? "gemini-2.5-flash", _selectedVoice);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}