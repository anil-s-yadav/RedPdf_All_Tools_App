import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color? primary;
  final Color? background;
  final Color? surface;
  final Color? text;
  final Color? subtitle;
  final Color? divider;
  final Color? lightPrimary;
  final Color? cardBackground;

  const AppColors({
    required this.primary,
    required this.background,
    required this.surface,
    required this.text,
    required this.subtitle,
    required this.divider,
    required this.lightPrimary,
    required this.cardBackground,
  });

  @override
  AppColors copyWith({
    Color? primary,
    Color? background,
    Color? surface,
    Color? text,
    Color? subtitle,
    Color? divider,
    Color? lightPrimary,
    Color? cardBackground,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      subtitle: subtitle ?? this.subtitle,
      divider: divider ?? this.divider,
      lightPrimary: lightPrimary ?? this.lightPrimary,
      cardBackground: cardBackground ?? this.cardBackground,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t),
      background: Color.lerp(background, other.background, t),
      surface: Color.lerp(surface, other.surface, t),
      text: Color.lerp(text, other.text, t),
      subtitle: Color.lerp(subtitle, other.subtitle, t),
      divider: Color.lerp(divider, other.divider, t),
      lightPrimary: Color.lerp(lightPrimary, other.lightPrimary, t),
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t),
    );
  }
}

class AppTheme {
  // Light Theme
  static final lightMode = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF4E50),
      primary: const Color(0xFFFF4E50),
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    // Using default system font to avoid Google Fonts network issues
    extensions: const [
      AppColors(
        primary: Color(0xFFFF4E50),
        background: Color(0xFFFAFAFA),
        surface: Colors.white,
        text: Color(0xFF1E1E1E),
        subtitle: Color(0xFF757575),
        divider: Color(0xFFEEEEEE),
        lightPrimary: Color(0xFFFFF0F0),
        cardBackground: Colors.white,
      ),
    ],
  );

  // Dark Theme
  static final darkMode = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF4E50),
      primary: const Color(0xFFFF4E50),
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    extensions: const [
      AppColors(
        primary: Color(0xFFFF4E50),
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
        text: Colors.white,
        subtitle: Colors.white70,
        divider: Colors.white12,
        lightPrimary: Color(0x33FF4E50), // Subtle primary for dark mode
        cardBackground: Color(0xFF1E1E1E),
      ),
    ],
  );
}

extension AppThemeExtension on ThemeData {
  AppColors get appColors => extension<AppColors>()!;
}
