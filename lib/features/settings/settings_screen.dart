import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/tts_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch allows the UI to rebuild when setTtsMode is called
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader(context, "Voice Engine"),
          _buildTtsTile(
            context,
            title: "Offline (Basic)",
            subtitle: "Uses phone's default voice. Data-free.",
            mode: TtsVoiceMode.offline,
            currentMode: settingsProvider.currentTtsMode,
            icon: Icons.cloud_off_rounded,
          ),
          _buildTtsTile(
            context,
            title: "Google TTS",
            subtitle: "Natural sounding, requires internet.",
            mode: TtsVoiceMode.google,
            currentMode: settingsProvider.currentTtsMode,
            icon: Icons.fmd_good_rounded,
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(thickness: 1),
          ),
          
          _buildSectionHeader(context, "Premium Voices (ElevenLabs)"),
          _buildTtsTile(
            context,
            title: "Elisabeth",
            subtitle: "Clear & Professional female voice",
            mode: TtsVoiceMode.elisabeth,
            currentMode: settingsProvider.currentTtsMode,
            icon: Icons.face_3_rounded,
          ),
          _buildTtsTile(
            context,
            title: "Adam",
            subtitle: "Deep & Authoritative male voice",
            mode: TtsVoiceMode.adam,
            currentMode: settingsProvider.currentTtsMode,
            icon: Icons.face_6_rounded,
          ),
          _buildTtsTile(
            context,
            title: "Bella",
            subtitle: "Soft & Friendly female voice",
            mode: TtsVoiceMode.bella,
            currentMode: settingsProvider.currentTtsMode,
            icon: Icons.face_2_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTtsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required TtsVoiceMode mode,
    required TtsVoiceMode currentMode,
    required IconData icon,
  }) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primary.withOpacity(0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, 
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected 
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary) 
            : const Icon(Icons.circle_outlined, color: Colors.grey),
        onTap: () {
          context.read<SettingsProvider>().setTtsMode(mode);
        },
      ),
    );
  }
}