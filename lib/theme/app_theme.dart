import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme: A comprehensive Apple-Design Theme System for LPU Touch.
/// 
/// This system follows Apple's Human Interface Guidelines (HIG) for colors,
/// typography, and spacing to deliver a premium, native feel.
class AppTheme {
  // ─── Spacing Constants ────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // ─── Border Radius ───────────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;

  // ─── Colors (Light) ──────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF007AFF); // iOS System Blue
  static const Color secondaryBlue = Color(0xFF5856D6); // iOS System Indigo
  
  static const Color backgroundLight = Color(0xFFF2F2F7); // Subtle warm gray
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textTertiaryLight = Color(0xFFC7C7CC);
  
  static const Color errorLight = Color(0xFFFF3B30); // iOS System Red
  static const Color successLight = Color(0xFF34C759); // iOS System Green
  static const Color warningLight = Color(0xFFFF9500); // iOS System Orange
  
  static const Color dividerLight = Color(0xFFC6C6C8);

  // ─── Colors (Dark) ───────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textTertiaryDark = Color(0xFF48484A);
  
  static const Color errorDark = Color(0xFFFF453A);
  static const Color successDark = Color(0xFF30D158);
  static const Color warningDark = Color(0xFFFF9F0A);
  
  static const Color dividerDark = Color(0xFF38383A);

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static final BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    offset: const Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  static final BoxShadow modalShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    offset: const Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );

  // ─── Typography ─────────────────────────────────────────────────────────
  // Using 'Inter' as it closely mimics the proportions and readability of SF Pro.
  static TextTheme get _textTheme => GoogleFonts.interTextTheme();

  static TextStyle _baseStyle(double size, FontWeight weight, double letterSpacing, Color color) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ─── Theme Data (Light) ──────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundLight,
      dividerColor: dividerLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surfaceLight,
        error: errorLight,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: _baseStyle(34, FontWeight.bold, -0.4, textPrimaryLight), // Large Title
        displayMedium: _baseStyle(28, FontWeight.bold, -0.4, textPrimaryLight), // Title 1
        displaySmall: _baseStyle(22, FontWeight.bold, -0.4, textPrimaryLight), // Title 2
        headlineMedium: _baseStyle(20, FontWeight.w600, -0.4, textPrimaryLight), // Title 3
        headlineSmall: _baseStyle(17, FontWeight.w600, -0.4, textPrimaryLight), // Headline
        bodyLarge: _baseStyle(17, FontWeight.normal, -0.4, textPrimaryLight), // Body
        bodyMedium: _baseStyle(16, FontWeight.normal, -0.4, textPrimaryLight), // Callout
        bodySmall: _baseStyle(15, FontWeight.normal, -0.4, textPrimaryLight), // Subheadline
        labelLarge: _baseStyle(13, FontWeight.normal, -0.4, textPrimaryLight), // Footnote
        labelMedium: _baseStyle(12, FontWeight.normal, 0.0, textPrimaryLight), // Caption 1
        labelSmall: _baseStyle(11, FontWeight.normal, 0.0, textPrimaryLight), // Caption 2
      ),
      cardTheme: CardTheme(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Theme Data (Dark) ───────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundDark,
      dividerColor: dividerDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surfaceDark,
        error: errorDark,
        onPrimary: Colors.white,
        onSurface: textPrimaryDark,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: _baseStyle(34, FontWeight.bold, -0.4, textPrimaryDark), // Large Title
        displayMedium: _baseStyle(28, FontWeight.bold, -0.4, textPrimaryDark), // Title 1
        displaySmall: _baseStyle(22, FontWeight.bold, -0.4, textPrimaryDark), // Title 2
        headlineMedium: _baseStyle(20, FontWeight.w600, -0.4, textPrimaryDark), // Title 3
        headlineSmall: _baseStyle(17, FontWeight.w600, -0.4, textPrimaryDark), // Headline
        bodyLarge: _baseStyle(17, FontWeight.normal, -0.4, textPrimaryDark), // Body
        bodyMedium: _baseStyle(16, FontWeight.normal, -0.4, textPrimaryDark), // Callout
        bodySmall: _baseStyle(15, FontWeight.normal, -0.4, textPrimaryDark), // Subheadline
        labelLarge: _baseStyle(13, FontWeight.normal, -0.4, textPrimaryDark), // Footnote
        labelMedium: _baseStyle(12, FontWeight.normal, 0.0, textPrimaryDark), // Caption 1
        labelSmall: _baseStyle(11, FontWeight.normal, 0.0, textPrimaryDark), // Caption 2
      ),
      cardTheme: CardTheme(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
