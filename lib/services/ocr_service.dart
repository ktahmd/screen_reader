import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ocr_word_model.dart';

class OcrService {
  static Future<List<OcrWord>> extractTextDetailed(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_capture.png');
      await tempFile.writeAsBytes(imageBytes);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      final List<OcrWord> words = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            words.add(OcrWord(
              text: element.text,
              boundingBox: element.boundingBox,
            ));
          }
        }
      }

      textRecognizer.close();
      if (await tempFile.exists()) await tempFile.delete();
      
      return words;
    } catch (e) {
      debugPrint("OCR Service Error: $e"); 
      return [];
    }
  }
}