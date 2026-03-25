class GeminiVoiceModel {
  final String id;
  final String name;        
  final String description; 

  const GeminiVoiceModel({
    required this.id,
    required this.name,
    required this.description,
  });

  // The Official Google Audio Preview URL pattern
  String get previewUrl => 
    "https://docs.cloud.google.com/text-to-speech/docs/audio/chirp3-hd-$id.wav";
}