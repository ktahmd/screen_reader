import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData appTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? const ColorScheme.dark(
          primary: Color.fromARGB(255, 130, 188, 221),
          secondary: AppColors.secondary,
          surface: AppColors.surfaceDark,
          background: AppColors.backgroundDark,
          error: AppColors.error,

          onPrimary: Color.fromARGB(255, 53, 85, 103),
          onSecondary: AppColors.black,
          onSurface: AppColors.textPrimaryDark,
          onBackground: AppColors.textPrimaryDark,
          onError: AppColors.white,
        )
      : const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceLight,
          background: AppColors.backgroundLight,
          error: AppColors.error,

          onPrimary: AppColors.backgroundLight,
          onSecondary: AppColors.black,
          onSurface: AppColors.textPrimaryLight,
          onBackground: AppColors.textPrimaryLight,
          onError: AppColors.white,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,

    scaffoldBackgroundColor:
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight,

    // ===== APP BAR =====
    appBarTheme: AppBarTheme(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      foregroundColor:
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      elevation: 0,
    ),

    // ===== CARD =====
    cardTheme: CardTheme(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // ===== TEXT =====
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
      ),
      bodyMedium: TextStyle(
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    ),

    // ===== INPUT =====
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
    ),

    // ===== BUTTON =====
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    // ===== DIVIDER =====
    dividerColor:
        isDark ? AppColors.dividerDark : AppColors.dividerLight,
  );
}