import '../base_voice_model.dart';


class GeminiVoiceModel implements BaseVoiceModel {
  @override
  final String id;
  @override
  final String name;
  @override
  final String description;

  const GeminiVoiceModel({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  String get previewUrl => 
    "https://docs.cloud.google.com/text-to-speech/docs/audio/chirp3-hd-$id.wav";
}