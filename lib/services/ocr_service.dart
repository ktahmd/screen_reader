import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class OcrService {
  static Future<List<Map<String, dynamic>>> extractTextDetailed(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_capture.png');
      await tempFile.writeAsBytes(imageBytes);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      List<Map<String, dynamic>> words = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            words.add({
              'text': element.text,
              'x': element.boundingBox.left,
              'y': element.boundingBox.top,
              'w': element.boundingBox.width,
              'h': element.boundingBox.height,
            });
          }
        }
      }

      textRecognizer.close();
      if (await tempFile.exists()) await tempFile.delete();
      
      return words;
    } catch (e) {
      return [];
    }
  }
}