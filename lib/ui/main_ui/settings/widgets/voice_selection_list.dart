import 'package:flutter/material.dart';
import '../../../../models/base_voice_model.dart';
import '../../../../services/audios/audio_preview_service.dart';


class VoiceSelectionList extends StatelessWidget {
  final List<BaseVoiceModel> voices;
  final String selectedVoiceId;
  final ValueChanged<String> onVoiceSelected;
  final AudioPreviewService previewService;

  const VoiceSelectionList({
    super.key,
    required this.voices,
    required this.selectedVoiceId,
    required this.onVoiceSelected,
    required this.previewService,
  });

  @override
  Widget build(BuildContext context) {
    if (voices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No voices found.", textAlign: TextAlign.center),
        ),
      );
    }
    
    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: previewService.playingIdNotifier,
        builder: (context, playingId, _) {
          return ListView.separated(
            shrinkWrap: true,
            itemCount: voices.length, 
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final voice = voices[index];
              final isSelected = selectedVoiceId == voice.id;
              final isPlaying = playingId == voice.id;

              return ListTile(
                selected: isSelected,
                leading: IconButton(
                  icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_outline),
                  onPressed: () => previewService.play(voice.id, voice.previewUrl),
                ),
                title: Text(voice.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(voice.description, style: const TextStyle(fontSize: 11)),
                onTap: () => onVoiceSelected(voice.id),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue, size: 20) : null,
              );
            },
          );
        },
      ),
    );
  }
}