import 'package:flutter/material.dart';
import '../../../models/ocr_word_model.dart';
import '../../../core/constants/app_colors.dart';

class WordPainter extends CustomPainter {
  final List<OcrWord> words;
  final Set<int> selectedIndices;
  final Set<int> dragIndices;
  final double pixelRatio;

  WordPainter({
    required this.words,
    required this.selectedIndices,
    required this.dragIndices,
    required this.pixelRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // final borderPaint = Paint()
    //   ..color = AppColors.primary
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 1.0;

    for (int i = 0; i < words.length; i++) {
      if (selectedIndices.contains(i) || dragIndices.contains(i)) {
        final rect = words[i].getAdjustedRect(pixelRatio);
        canvas.drawRect(rect, paint);
        // canvas.drawRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(WordPainter oldDelegate) {
    return oldDelegate.selectedIndices != selectedIndices || 
          oldDelegate.dragIndices != dragIndices;
  }
}