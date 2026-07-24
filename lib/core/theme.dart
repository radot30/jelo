import 'package:flutter/material.dart';

class AppTheme {
  // Premium 2025 Deep Navy & Amber Palette
  static const Color accentColor = Color(0xFFF59E0B); // Amber 500
  static const Color orangeColor = Color(0xFFF97316); // Orange 500
  static const Color darkNavy = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBg: lightBg,
      appBarBg: Colors.white,
      appBarFg: darkNavy,
      cardColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        secondary: orangeColor,
        surface: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBg: darkNavy,
      appBarBg: darkNavy,
      appBarFg: Colors.white,
      cardColor: darkSurface,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: orangeColor,
        surface: darkSurface,
      ),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color appBarBg,
    required Color appBarFg,
    required Color cardColor,
    required Color shadowColor,
    required ColorScheme colorScheme,
  }) {
    return ThemeData(
      brightness: brightness,
      primaryColor: accentColor,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: colorScheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: brightness == Brightness.light ? 2 : 4,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: cardColor,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        backgroundColor: cardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
