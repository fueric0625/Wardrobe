import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5B6CFF);
  static const primarySoft = Color(0xFFE8EBFF);
  static const background = Color(0xFFF5F6FA);
  static const surface = Colors.white;
  static const text = Color(0xFF2B2F3A);
  static const textMuted = Color(0xFF8A90A5);
  static const border = Color(0xFFEEF0F6);
  static const sidebar = Color(0xFFFFFFFF);
}

ThemeData buildAppTheme(String fontFamily) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    surface: AppColors.surface,
  ).copyWith(primary: AppColors.primary);
  final base = ThemeData(useMaterial3: true, fontFamily: fontFamily);
  final text = base.textTheme.apply(
    fontFamily: fontFamily,
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  return base.copyWith(
    colorScheme: scheme,
    textTheme: text,
    primaryTextTheme: text,
    scaffoldBackgroundColor: AppColors.background,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: TextStyle(fontFamily: fontFamily, letterSpacing: 0),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
  );
}
