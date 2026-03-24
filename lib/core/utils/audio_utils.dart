import 'dart:typed_data';

class AudioUtils {
  /// Adds a standard WAV header to raw PCM audio data (Required for Gemini)
  static Uint8List addWavHeader(Uint8List pcmData) {
    int channels = 1, sampleRate = 24000, byteRate = sampleRate * channels * 2;
    int totalDataLen = pcmData.length, totalAudioLen = totalDataLen + 36;
    var header = ByteData(44);
    
    header.setUint8(0, 82); header.setUint8(1, 73); header.setUint8(2, 70); header.setUint8(3, 70);
    header.setUint32(4, totalAudioLen, Endian.little);
    header.setUint8(8, 87); header.setUint8(9, 65); header.setUint8(10, 86); header.setUint8(11, 69);
    header.setUint8(12, 102); header.setUint8(13, 109); header.setUint8(14, 116); header.setUint8(15, 32);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 100); header.setUint8(37, 97); header.setUint8(38, 116); header.setUint8(39, 97);
    header.setUint32(40, totalDataLen, Endian.little);
    
    var b = BytesBuilder();
    b.add(header.buffer.asUint8List());
    b.add(pcmData);
    return b.toBytes();
  }
}