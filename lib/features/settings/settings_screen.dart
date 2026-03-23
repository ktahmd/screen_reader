import 'package:flutter/material.dart';
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
          SliverToBoxAdapter(child: _buildHeader("Reading Sentences")),
          _buildEngineList(context, settings.sentenceMode, false),
          
          const SliverToBoxAdapter(child: Divider(height: 40)),
          
          SliverToBoxAdapter(child: _buildHeader("Clicking Single Words")),
          _buildEngineList(context, settings.wordMode, true),
          
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

  Widget _buildEngineList(BuildContext context, TtsVoiceMode current, bool isWord) {
    return SliverList(
      delegate: SliverChildListDelegate([
        _cuteTile(context, "Auto Mode", "Smart switching", Icons.auto_awesome, TtsVoiceMode.auto, current, isWord),
        _cuteTile(context, "Offline", "Fast & Data-free", Icons.cloud_off, TtsVoiceMode.offline, current, isWord),
        _cuteTile(context, "Google TTS", "Standard Web Voice", Icons.g_translate, TtsVoiceMode.google, current, isWord),
        _cuteTile(context, "Premium (Elisabeth)", "High Quality", Icons.face_3, TtsVoiceMode.elisabeth, current, isWord),
      ]),
    );
  }

  Widget _cuteTile(BuildContext context, String title, String sub, IconData icon, TtsVoiceMode mode, TtsVoiceMode current, bool isWord) {
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(sub),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.circle_outlined),
      onTap: () => context.read<SettingsProvider>().updateMode(mode, isWord),
    );
  }
}