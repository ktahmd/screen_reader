import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/tts/tts_service.dart';
import 'widgets/settings_tile.dart';
import 'widgets/eleven_labs_dialog.dart';
import 'widgets/gemini_dialog.dart';

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
        SettingsTile(title: "Auto Mode", sub: "Smart switching", icon: Icons.auto_awesome_mosaic, mode: TtsVoiceMode.auto, current: current, isWord: isWord),
        SettingsTile(title: "Offline", sub: "Fast & Data-free", icon: Icons.cloud_off, mode: TtsVoiceMode.offline, current: current, isWord: isWord),
        SettingsTile(title: isWord ? "Google TTS (Recommended)" : "Google TTS", sub: "Standard Web Voice", icon: Icons.g_translate, mode: TtsVoiceMode.google, current: current, isWord: isWord),
        
        SettingsTile(
          title: "ElevenLabs", sub: "Advanced AI Voices", icon: Icons.record_voice_over, mode: TtsVoiceMode.elevenlabs, current: current, isWord: isWord,
          trailingWidgets: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => showDialog(context: context, builder: (_) => ElevenLabsConfigDialog(settings: settings)),
            ),
          ],
          errorMessage: "Please add an ElevenLabs API Key",
          onErrorAction: () => showDialog(context: context, builder: (_) => ElevenLabsConfigDialog(settings: settings)),
        ),
        
        SettingsTile(
          title: "Google Gemini", sub: "AI Expressive Voices", icon: Icons.auto_awesome, mode: TtsVoiceMode.gemini, current: current, isWord: isWord,
          trailingWidgets: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => showDialog(context: context, builder: (_) => GeminiConfigDialog(settings: settings)),
            ),
          ],
          errorMessage: "Please add a Gemini API Key",
          onErrorAction: () => showDialog(context: context, builder: (_) => GeminiConfigDialog(settings: settings)),
        ),
      ]),
    );
  }
}