import 'package:flutter/material.dart';

class OcrWord {
  final String text;
  final Rect boundingBox;

  OcrWord({
    required this.text,
    required this.boundingBox,
  });

  factory OcrWord.fromMap(Map<String, dynamic> map) {
    return OcrWord(
      text: map['text'] as String,
      boundingBox: Rect.fromLTWH(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
        (map['w'] as num).toDouble(),
        (map['h'] as num).toDouble(),
      ),
    );
  }
}