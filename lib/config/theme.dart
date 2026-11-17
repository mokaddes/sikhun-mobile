import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SikhunTheme {
  // Sikhun Design System — "Uday (উদয়) — the Rising Sun"
  // Matching resources/css/app.css EXACTLY

  // Brand Primaries
  static const Color primary = Color(0xFF8A5A32); // Warm Leather / Rising Sun
  static const Color primaryHover = Color(0xFF704525);
  static const Color secondary = Color(0xFF80684C);
  static const Color secondaryHover = Color(0xFF665139);
  static const Color accent = Color(0xFF8A5A32);
  static const Color tertiary = Color(0xFF80684C);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // Light Palette (Warm Paper / Cream / Ivory)
  static const Color lightBg = Color(0xFFFAF8F4);
  static const Color lightSurface = Color(0xFFFFFEFA);
  static const Color lightSurface2 = Color(0xFFF1EDE6);
  static const Color lightBorder = Color(0xFFE5DED2);
  static const Color textDark = Color(0xFF29251F);
  static const Color mutedDark = Color(0xFF625B51);

  // Dark Palette (Obsidian / Ink)
  static const Color darkPrimary = Color(0xFFD2AD7C);
  static const Color darkSecondary = Color(0xFFC4AB87);
  static const Color darkBg = Color(0xFF171613);
  static const Color darkSurface = Color(0xFF211F1A);
  static const Color darkSurface2 = Color(0xFF2A2721);
  static const Color darkBorder = Color(0xFF38342C);
  static const Color darkText = Color(0xFFEEE9DF);
  static const Color darkTextMuted = Color(0xFFB9B1A4);

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
        onSurface: textDark,
        surfaceContainerHighest: lightSurface2,
        outline: lightBorder,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
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
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primary.withAlpha(35),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.hindSiliguri(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            );
          }
          return GoogleFonts.hindSiliguri(
            fontSize: 11,
            color: mutedDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: mutedDark, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        onSurface: darkText,
        surfaceContainerHighest: darkSurface2,
        outline: darkBorder,
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
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
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: darkPrimary.withAlpha(45),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.hindSiliguri(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkPrimary,
            );
          }
          return GoogleFonts.hindSiliguri(
            fontSize: 11,
            color: darkTextMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary, size: 24);
          }
          return const IconThemeData(color: darkTextMuted, size: 22);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
    );
  }
}
