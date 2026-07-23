import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/app_provider.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TailorConnectApp());
}

class TailorConnectApp extends StatelessWidget {
  const TailorConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'TailorConnect',
        debugShowCheckedModeBanner: false,
        theme: _buildAppTheme(),
        home: const LoginScreen(),
      ),
    );
  }

  /// App-wide clean light theme matching the TailorConnect Login UI design.
  /// Brand Navy: #132238
  /// Brand Gold: #D49228
  /// Background: #FAFAFC
  ThemeData _buildAppTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.brandNavy,
        surface: AppColors.surface,
        background: AppColors.background,
        onPrimary: Colors.white,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
    );
  }
}

/// Central color constants matching the Login UI palette.
class AppColors {
  // --- Brand Colors ---
  static const Color brandNavy = Color(0xFF132238);
  static const Color brandGold = Color(0xFFD49228);

  // --- Primary Brand Color (Gold Accent) ---
  static const Color primary = Color(0xFFD49228);
  static const Color primaryLight = Color(0xFFB4751D);
  static const Color primaryDark = Color(0xFF8A5710);

  // --- Background Layers ---
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFF1F5F9);

  // --- Border Colors ---
  static const Color border = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFDFE4EA);

  // --- Text Colors (all dark enough to read on white/light backgrounds) ---
  static const Color textPrimary   = Color(0xFF132238); // brand navy — very dark
  static const Color textSecondary = Color(0xFF3D4F63); // dark slate — clearly readable
  static const Color textMuted     = Color(0xFF5A6A7E); // medium slate — still readable

  // --- Status Colors ---
  static const Color statusSubmitted = Color(0xFF386FA4);
  static const Color statusAccepted  = Color(0xFF0F9D6C);
  static const Color statusCutting   = Color(0xFFB45309);
  static const Color statusFitting   = Color(0xFFB4751D);
  static const Color statusCompleted = Color(0xFF0F766E);

  // --- Accent Colors ---
  static const Color emerald = Color(0xFF0F9D6C);
  static const Color amber   = Color(0xFFB45309);
  static const Color indigo  = Color(0xFF2563EB);
  static const Color red     = Color(0xFFDC2626);
}
