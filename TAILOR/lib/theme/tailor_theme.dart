import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean Light theme for the Tailor Dashboard matching the Customer Dashboard aesthetic.
class TailorTheme {
  // ── Brand Colors ──────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFFFAFAFC);
  static const Color cardBackground = Colors.white;
  static const Color primaryPurple  = Color(0xFFD49228); // Gold accent
  static const Color primaryGreen   = Color(0xFF132238); // Navy brand
  static const Color accentAmber    = Color(0xFFD49228);
  static const Color brandNavy      = Color(0xFF132238);
  static const Color brandGold      = Color(0xFFD49228);
  static const Color borderLight    = Color(0xFFE2E8F0);

  // ── Text Colors ───────────────────────────────────────────────────
  static const Color textWhite  = Color(0xFF132238);
  static const Color textGrey   = Color(0xFF64748B);

  // ── Theme Data ────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryGold,
    colorScheme: const ColorScheme.light(
      primary: brandGold,
      secondary: brandNavy,
      surface: cardBackground,
      background: darkBackground,
      onPrimary: Colors.white,
      onSurface: brandNavy,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: brandNavy),
      titleTextStyle: TextStyle(
        color: brandNavy,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brandGold,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderLight),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: brandNavy, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
    ),
  );

  static Color get primaryGold => brandGold;
}
