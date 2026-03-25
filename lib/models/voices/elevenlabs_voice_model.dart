import '../base_voice_model.dart';

class ElevenLabsVoiceModel implements BaseVoiceModel {
  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String previewUrl;

  const ElevenLabsVoiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.previewUrl,
  });


  factory ElevenLabsVoiceModel.fromMap(Map<String, dynamic> map) {
    final labels = map['labels'] as Map<String, dynamic>? ?? {};
    
    return ElevenLabsVoiceModel(
      id: map['voice_id'] as String,
      name: map['name'] as String,
      description: _buildDescription(labels),
      previewUrl: map['preview_url'] as String,
    );
  }


  static String _buildDescription(Map<String, dynamic> labels) {
    final parts = [
      labels['gender'],
      labels['accent'],
      labels['age'],
      labels['use_case'],
    ].where((part) => part != null && (part as String).isNotEmpty).toList();
    

    return parts.map((part) => (part as String).replaceFirst(part[0], part[0].toUpperCase())).join(', ');
  }
}