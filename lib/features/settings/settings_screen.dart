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
        slivers: [
          SliverToBoxAdapter(child: _buildHeader("Reading Paragraphs")),
          _buildEngineList(context, settings.sentenceMode, false, settings),
          
          const SliverToBoxAdapter(child: Divider(height: 40)),
          
          SliverToBoxAdapter(child: _buildHeader("Short sentences (1-3 words selected)")),
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
        _cuteTile(context, "Google TTS", "Standard Web Voice", Icons.g_translate, TtsVoiceMode.google, current, isWord),
        
        // ElevenLabs Tile has a trailing Settings Icon
        _cuteTile(
            context,
            "ElevenLabs",
            "Advanced AI Voices",
            Icons.record_voice_over,
            TtsVoiceMode.elevenlabs,
            current,
            isWord,
            trailingWidgets: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.blue),
                onPressed: () =>
                    _showElevenLabsConfigDialog(context, settings),
              ),
            ],
            errorMessage: "Please add an ElevenLabs API Key",
            onErrorAction: () =>
                _showElevenLabsConfigDialog(context, settings),
          ),
      ]),
    );
  }

  Widget _cuteTile(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    TtsVoiceMode mode,
    TtsVoiceMode current,
    bool isWord, {
    List<Widget>? trailingWidgets,
    String? errorMessage,
    VoidCallback? onErrorAction,
  }) {
    final isSelected = mode == current;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(sub),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...?trailingWidgets,
          if (trailingWidgets != null) const SizedBox(width: 8),
          isSelected
              ? const Icon(Icons.check_circle, color: Colors.blue)
              : const Icon(Icons.circle_outlined),
        ],
      ),
      onTap: () async {
        bool success = await context
            .read<SettingsProvider>()
            .updateMode(mode, isWord);

        if (!success && context.mounted) {
          Fluttertoast.showToast(
              msg: errorMessage ?? "Configuration required");

          if (onErrorAction != null) {
            onErrorAction();
          }
        }
      },
    );
  }

  void _showElevenLabsConfigDialog(BuildContext context, SettingsProvider settings) {
    final TextEditingController keyController = TextEditingController(text: settings.elevenLabsApiKey);
    ElevenLabsVoice selectedVoice = settings.elevenLabsVoice;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("ElevenLabs Config"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: "API Key",
                      border: OutlineInputBorder(),
                      hintText: "Enter your xi-api-key",
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<ElevenLabsVoice>(
                    value: selectedVoice,
                    decoration: const InputDecoration(labelText: "Voice", border: OutlineInputBorder()),
                    items: ElevenLabsVoice.values.map((voice) {
                      return DropdownMenuItem(
                        value: voice,
                        child: Text(voice.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedVoice = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    settings.updateElevenLabsConfig(keyController.text.trim(), selectedVoice);
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
        );
      }
    );
  }
}