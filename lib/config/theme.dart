import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SikhunTheme {
  // Brand Colors
  static const Color primary = Color(0xFFB78B52); // Sikhun Warm Gold / Flame
  static const Color primaryDark = Color(0xFF8A5A32);
  static const Color secondary = Color(0xFF0F172A); // Dark Slate
  static const Color accent = Color(0xFF10B981); // Emerald
  static const Color danger = Color(0xFFEF4444); // Red

  // Light Palette
  static const Color lightBg = Color(0xFFFBF9F5);
  static const Color lightSurface = Colors.white;
  static const Color lightSurface2 = Color(0xFFF3EFE6);
  static const Color lightBorder = Color(0xFFE5DEC9);
  static const Color textDark = Color(0xFF1E1B16);
  static const Color mutedDark = Color(0xFF6B6457);

  // Dark Palette
  static const Color darkBg = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF181C26);
  static const Color darkSurface2 = Color(0xFF222736);
  static const Color darkBorder = Color(0xFF2E3547);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.hindSiliguri(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Colors.white,
        surface: darkSurface,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.hindSiliguri(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}
