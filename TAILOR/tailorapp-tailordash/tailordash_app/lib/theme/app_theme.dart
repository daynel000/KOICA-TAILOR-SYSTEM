import 'package:flutter/material.dart';

class AppTheme {
  // Define our core colors based on the design mockup
  static const Color darkBackground = Color(0xFF121212); // Deep dark background
  static const Color cardBackground = Color(0xFF1E1E1E); // Slightly lighter for cards
  static const Color primaryPurple = Color(0xFF8B5CF6);  // Accent purple
  static const Color primaryGreen = Color(0xFF10B981);   // Accent green
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryPurple,
    
    // Setup generic app bar style
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textWhite),
      titleTextStyle: TextStyle(
        color: textWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Setup floating action button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: textWhite,
    ),
    
    // Setup standard card design
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
