import 'package:flutter/material.dart';
import 'package:wardrobe/core/design_system/app_appearance.dart';
import 'package:wardrobe/core/design_system/app_font.dart';

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

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({required this.primary, required this.primarySoft});

  final Color primary;
  final Color primarySoft;

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ??
        const AppPalette(
          primary: AppColors.primary,
          primarySoft: AppColors.primarySoft,
        );
  }

  @override
  AppPalette copyWith({Color? primary, Color? primarySoft}) {
    return AppPalette(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
    );
  }
}

ThemeData buildAppTheme(AppAppearance appearance) {
  final palette = AppPalette(
    primary: appearance.color.primary,
    primarySoft: appearance.color.primarySoft,
  );
  final fontFamily = appearance.fontFamily;
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: Brightness.light,
    surface: AppColors.surface,
  ).copyWith(primary: palette.primary);
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    fontFamilyFallback: appFontFallback,
  );
  final text = base.textTheme.apply(
    fontFamily: fontFamily,
    fontFamilyFallback: appFontFallback,
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  return base.copyWith(
    colorScheme: scheme,
    extensions: [palette],
    textTheme: text,
    primaryTextTheme: text,
    scaffoldBackgroundColor: AppColors.background,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: appFontFallback,
          letterSpacing: 0,
        ),
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
        borderSide: BorderSide(color: palette.primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
  );
}
