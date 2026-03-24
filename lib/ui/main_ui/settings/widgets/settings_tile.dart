// lib/main_ui/settings/widgets/settings_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../services/tts/tts_service_core.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final TtsVoiceMode mode;
  final TtsVoiceMode current;
  final bool isWord;
  final List<Widget>? trailingWidgets;
  final String? errorMessage;
  final VoidCallback? onErrorAction;

  const SettingsTile({
    super.key, required this.title, required this.sub, required this.icon,
    required this.mode, required this.current, required this.isWord,
    this.trailingWidgets, this.errorMessage, this.onErrorAction,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(sub),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...?trailingWidgets,
          if (trailingWidgets != null) const SizedBox(width: 8),
          isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.circle_outlined),
        ],
      ),
      onTap: () async {
        bool success = await context.read<SettingsProvider>().updateMode(mode, isWord);
        if (!success && context.mounted) {
          Fluttertoast.showToast(msg: errorMessage ?? "Configuration required");
          if (onErrorAction != null) onErrorAction!();
        }
      },
    );
  }
}