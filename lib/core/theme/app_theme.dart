import 'package:flutter/material.dart';
import 'design_tokens.dart';

// ════════════════════════════════════════════════════════════════════════════
//  APP THEME — LPU Touch
//  Full Material 3 ThemeData built exclusively from design tokens.
// ════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    const isLight = true;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,

      // ── Color Scheme ──
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.brandOrange,
        surface: AppColors.cardWhite,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.bgDashboard,
      dividerColor: AppColors.divider,

      // ── App Bar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDashboard,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppColors.primaryBlue,
          size: 22,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.body,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.70),
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.brandOrangeGlow, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: AppTypography.subhead,
        ),
        errorStyle: const TextStyle(
          height: 0,
          fontSize: 0,
          color: Colors.transparent,
        ),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgWhite,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: Colors.white,
          fontSize: AppTypography.subhead,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Text Theme ──
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.largeTitle,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: AppColors.textPrimary,
          height: 1.1,
        ),
        titleLarge: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.title1Size,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.title3Size,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.body,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.subhead,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          color: AppColors.textTertiary,
        ),
        bodySmall: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.footnote,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        labelSmall: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
