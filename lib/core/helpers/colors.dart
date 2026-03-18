import 'package:flutter/material.dart';

class AppColors {
  // ===== BRAND =====
  static const Color primary = Color(0xFF026EAE);
  static const Color primaryDark = Color(0xFF001C4C);
  static const Color secondary = Color.fromARGB(255, 15, 200, 64);

  // Gradient
  static const LinearGradient primaryGradientDark = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 6, 107, 166), Color.fromARGB(255, 168, 204, 227)],
              
            );
 static const LinearGradient primaryGradientLight = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryDark, primary],
            );

  // ===== LIGHT THEME =====
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFEEEEEE);

  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textHintLight = Color(0xFF9E9E9E);

  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color dividerLight = Color(0xFFBDBDBD);

  // ===== DARK THEME =====
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E2D33);
  static const Color cardDark = Color(0xFF22343C);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);
  static const Color textHintDark = Color(0xFF78909C);

  static const Color borderDark = Color(0xFF37474F);
  static const Color dividerDark = Color(0xFF455A64);

  // ===== STATUS COLORS =====
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF29B6F6);

  // ===== EXTRA UTILS =====
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  static const Color disabled = Color(0xFFBDBDBD);
  static const Color shadow = Colors.black26;

  // Overlay (for modals, dialogs)
  static const Color overlay = Color(0x66000000);
}