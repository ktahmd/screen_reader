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
    //exemple of my phone resolution is 1440x2960
    //and pixel ratio is 4.3, so we need to divide the coordinates by 4.3
    //to get the correct position on the overlay,
    //but I found that the text is slightly off,
    //so I subtracted a small value from the pixel ratio to adjust it,
    //this is a common practice when dealing with different screen densities and resolutions in Flutter.
    //TODO: In future, we can make this adjustment dynamic by testing on multiple devices and finding the optimal value or formula for it.
    Rect getAdjustedRect(double pixelRatio) {
    pixelRatio -= 0.09;
    return Rect.fromLTWH(
      boundingBox.left / pixelRatio - 8,
      boundingBox.top / pixelRatio - 15,
      boundingBox.width / pixelRatio + 6,
      boundingBox.height / pixelRatio + 6,
    );
  }

  bool containsPoint(Offset localPoint, double pixelRatio) {
    return getAdjustedRect(pixelRatio).contains(localPoint);
  }
}