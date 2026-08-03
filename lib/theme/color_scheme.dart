import 'package:flutter/material.dart';

/// Kerala Institute Sales App Color Schemes

final lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: LightAppColors.primary,
  onPrimary: Colors.white,
  secondary: LightAppColors.secondary,
  onSecondary: Colors.white,
  tertiary: LightAppColors.accentCyan,
  onTertiary: Colors.black,
  background: LightAppColors.background,
  onBackground: LightAppColors.textPrimary,
  surface: LightAppColors.surface,
  onSurface: LightAppColors.textPrimary,
  error: LightAppColors.error,
  onError: Colors.white,
  inverseSurface: LightAppColors.inputBackground,
  onInverseSurface: LightAppColors.textPrimary,
  outline: LightAppColors.divider,
  shadow: Colors.black12,
  onSurfaceVariant: LightAppColors.textSecondary,
);

final darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: DarkAppColors.primary,
  onPrimary: Colors.black87,
  secondary: DarkAppColors.secondary,
  onSecondary: Colors.black87,
  tertiary: DarkAppColors.accentCyan,
  onTertiary: Colors.black,
  background: DarkAppColors.background,
  onBackground: DarkAppColors.textPrimary,
  surface: DarkAppColors.surface,
  onSurface: DarkAppColors.textPrimary,
  error: DarkAppColors.error,
  onError: Colors.white,
  inverseSurface: DarkAppColors.card,
  onInverseSurface: Colors.white,
  outline: DarkAppColors.divider,
  shadow: Colors.black,
  onSurfaceVariant: DarkAppColors.textSecondary,
);

class LightAppColors {
  static const Color primary = Color(0xFF008080); // Teal
  static const Color secondary = Color(0xFF006666); // Darker Teal
  static const Color accentCyan = Color(0xFF00E5FF); // Bright Cyan
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color inputBackground = Color(0xFFE8EBEE);
  static const Color textPrimary = Color(0xFF151515);
  static const Color textSecondary = Color(0xFF2E2F33);
  static const Color muted = Color(0xFFA0A5BA);
  static const Color divider = Color(0xFFE8EBEE);
  static const Color error = Color(0xFF922720);
}

class DarkAppColors {
  static const Color primary = Color(0xFF00FFFF); // Cyan Accent
  static const Color secondary = Color(0xFF00E5FF); // Secondary Cyan
  static const Color accentCyan = Color(0xFF00F2FE); // Cyan
  static const Color background = Color(0xFF0F2027); // Deep gradient start
  static const Color onboarding = Color(0xFF0F2027);
  static const Color surface = Color(0xFF203A43); // Medium gradient
  static const Color card = Color(0xFF162A35);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A9A86);
  static const Color muted = Color(0xFFA0A5BA);
  static const Color divider = Color(0xFF1E1E1E);
  static const Color error = Color(0xFF922720);
}
