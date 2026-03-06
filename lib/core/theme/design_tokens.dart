import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS — LPU Touch
//  Single source of truth for all visual constants.
//  Import this file wherever a color, spacing, or radius is needed.
// ════════════════════════════════════════════════════════════════════════════

// ─── Colors ─────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Brand
  static const Color primaryBlue     = Color(0xFF2050E4); // Dashboard brand blue
  static const Color primaryBlueLt   = Color(0xFF3B82F6); // Lighter variant
  static const Color brandOrange     = Color(0xFFF26522); // LPU identity orange
  static const Color brandOrangeGlow = Color(0xFFFF8C00); // Logo / glow orange

  // Splash
  static const Color splashDark       = Color(0xFF0D1B2A);
  static const Color splashDarkMid    = Color(0xFF1A2F4A);

  // Backgrounds
  static const Color bgLogin          = Color(0xFFD6DBE6);
  static const Color bgLoginTop       = Color(0xFFEBEEF3);
  static const Color bgDashboard      = Color(0xFFF9F9F9);
  static const Color bgWhite          = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary      = Color(0xFF0F172A); // Near-black
  static const Color textSecondary    = Color(0xFF1E293B); // Dark slate
  static const Color textTertiary     = Color(0xFF6B7280); // Gray
  static const Color textInput        = Color(0xFF1A1A2E); // Input value
  static const Color textHint         = Color(0xFF9CA3AF); // Placeholder
  static const Color textOnDark       = Color(0xFFFFFFFF); // White text

  // Semantic
  static const Color error            = Color(0xFFB91C1C);
  static const Color errorField       = Color(0xFFE53935);
  static const Color success          = Color(0xFF10B981);
  static const Color warning          = Color(0xFFFF9500);

  // Glass / Card surfaces
  static const Color cardWhite        = Color(0xFFFFFFFF);
  /// Semi-transparent white — 70% opacity, used for glassmorphism
  static Color cardGlass              = Colors.white.withOpacity(0.70);
  static Color cardGlassBorder       = Colors.white.withOpacity(0.50);

  // Dividers & borders
  static const Color divider          = Color(0xFFE5E5E5);
  static const Color border           = Color(0xFFE2E8F0);
  static Color borderSubtle          = Colors.black.withOpacity(0.04);

  // Dashboard specific
  static const Color searchHint       = Color(0xFFC4C4C4);
  static const Color viewedLinksBg   = Color(0xFFF0F4FF); // Replaced yellow with subtle blue
  static const Color viewedLinksText  = Color(0xFF2050E4);
  static const Color heroCardGradA    = Color(0xFFF0F5FF); // Blue-tinted white
  static const Color heroCardGradB    = Color(0xFFE0EAFF); // Slightly deeper blue tint

  // Profile avatar
  static const Color avatarGradA      = Color(0xFFE2E8F0);
  static const Color avatarGradB      = Color(0xFFCBD5E1);
  static const Color avatarInitials   = Color(0xFF475569);

  // Dock
  static const Color dockBg          = Color(0xFF000000);
  static const Color dockIconActive  = Colors.black;
  static Color dockIconInactive      = Colors.white.withOpacity(0.70);
  static const Color dockHighlight   = Color(0xFFFFFFFF);
  static const Color dockCenterBg    = Color(0xFF2050E4);
}

// ─── Spacing ─────────────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();
  static const double xs      = 4.0;
  static const double sm      = 8.0;
  static const double md      = 12.0;
  static const double lg      = 16.0;
  static const double xl      = 20.0;
  static const double xxl     = 24.0;
  static const double xxxl    = 32.0;
  static const double huge    = 40.0;
  static const double massive = 48.0;

  /// Standard horizontal edge padding for all screens.
  static const double screenH = xxl;
  /// Bottom padding buffer for floating Dock.
  static const double dockBuffer = 120.0;
}

// ─── Border Radius ───────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double pill = 100.0;

  static BorderRadius rSm  = BorderRadius.circular(sm);
  static BorderRadius rMd  = BorderRadius.circular(md);
  static BorderRadius rLg  = BorderRadius.circular(lg);
  static BorderRadius rXL  = BorderRadius.circular(xl);
  static BorderRadius rXXL = BorderRadius.circular(xxl);
  static BorderRadius rPill = BorderRadius.circular(pill);
}

// ─── Typography ─────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();
  static const String fontFamily = 'SF Pro Display';
  static const String logoFont   = 'Virgo';

  // Size scale (same as Apple HIG sp values)
  static const double caption    = 11.0;
  static const double footnote   = 13.0;
  static const double subhead    = 15.0;
  static const double body       = 17.0;
  static const double title3Size = 20.0;
  static const double title2Size = 22.0;
  static const double title1Size = 28.0;
  static const double largeTitle = 34.0;
}

// ─── Shadows ─────────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  /// Subtle resting card shadow — pair with a zero-elevation Container.
  static List<BoxShadow> get cardSoft => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Elevated card / floating element shadow.
  static List<BoxShadow> get cardElevated => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Modal / bottom sheet shadow.
  static List<BoxShadow> get modal => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 40,
      offset: const Offset(0, -8),
    ),
  ];
}

// ─── Durations ───────────────────────────────────────────────────────────────

class AppDurations {
  AppDurations._();
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow   = Duration(milliseconds: 500);
}
