// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:path_provider/path_provider.dart';

// class OCRService {
//   // We use the Latin script for English (You can add others later like Japanese/Korean)
//   final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

//   /// Takes the image bytes, saves temporarily, extracts text with coordinates, and deletes the image.
//   Future<RecognizedText?> extractTextFromBytes(Uint8List imageBytes) async {
//     File? tempFile;
//     try {
//       // 1. Get the temporary cache directory of the phone
//       final directory = await getTemporaryDirectory();
      
//       // 2. Create a temporary file path
//       final imagePath = '${directory.path}/temp_capture_${DateTime.now().millisecondsSinceEpoch}.png';
//       tempFile = File(imagePath);

//       // 3. Write the bytes to this temporary file
//       await tempFile.writeAsBytes(imageBytes);

//       // 4. Feed the image file to Google ML Kit
//       final inputImage = InputImage.fromFilePath(imagePath);
//       final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

//       // 5. Return the full object (which contains the text and the X/Y coordinates)
//       return recognizedText;

//     } catch (e) {
//       if (kDebugMode) {
//         print("OCR Error: $e");
//       }
//       return null;
//     } finally {
//       // 6. CRITICAL CLEANUP: Delete the temporary file immediately so we don't waste phone storage!
//       if (tempFile != null && await tempFile.exists()) {
//         await tempFile.delete();
//       }
//     }
//   }

//   /// Always close the recognizer when the app/service shuts down
//   void dispose() {
//     _textRecognizer.close();
//   }
// }

import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class OcrService {
  static Future<String> extractText(Uint8List imageBytes) async {
    try {
      // 1. Save the image bytes to a temporary file 
      // (ML Kit works fastest with file paths)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_capture.png');
      await tempFile.writeAsBytes(imageBytes);

      // 2. Prepare the image for ML Kit
      final inputImage = InputImage.fromFilePath(tempFile.path);
      
      // 3. Initialize the Text Recognizer (Latin script for English/French/Spanish etc.)
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      // 4. Process the image
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // 5. Clean up memory
      textRecognizer.close();
      if (await tempFile.exists()) {
        await tempFile.delete(); // Delete the temp image immediately!
      }
      
      return recognizedText.text;
    } catch (e) {
      return "Error extracting text: $e";
    }
  }
}