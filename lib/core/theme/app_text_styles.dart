import 'package:flutter/material.dart';
import 'design_tokens.dart';

// ════════════════════════════════════════════════════════════════════════════
//  APP TEXT STYLES — LPU Touch
//  Central registry of all TextStyle definitions.
//  Use .copyWith() for color or weight overrides in context.
// ════════════════════════════════════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();

  // ─── Display / Title ──────────────────────────────────────────────────────

  /// 34sp bold — screen hero titles (Dashboard welcome).
  static const TextStyle largeTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.largeTitle,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  /// 28sp bold — card or modal headers.
  static const TextStyle title1 = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.title1Size,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// 22sp bold — section headers.
  static const TextStyle title2 = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.title2Size,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// 20sp semibold — card titles.
  static const TextStyle title3 = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.title3Size,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────

  /// 17sp semibold — list item titles, button labels (override color).
  static const TextStyle headline = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.body,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// 17sp regular — primary reading text.
  static const TextStyle body = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.body,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// 15sp regular — secondary descriptive text (textSecondary color).
  static const TextStyle subhead = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.subhead,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    color: AppColors.textTertiary,
  );

  // ─── Small ────────────────────────────────────────────────────────────────

  /// 13sp regular — meta info, timestamps (textTertiary).
  static const TextStyle footnote = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.footnote,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    color: AppColors.textTertiary,
  );

  /// 11sp medium — badges, labels, grid card text.
  static const TextStyle caption = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.caption,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );

  // ─── Semantic / Special ───────────────────────────────────────────────────

  /// 17sp semibold white — primary CTA button labels.
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.body,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
    letterSpacing: -0.3,
  );

  /// AppBar centre title — matches iOS navigation bar convention.
  static const TextStyle navBarTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: AppTypography.body,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // ─── Logo / Brand ─────────────────────────────────────────────────────────

  static const TextStyle logoLpu = TextStyle(
    fontFamily: AppTypography.logoFont,
    fontWeight: FontWeight.bold,
    fontSize: 28,
    letterSpacing: -0.8,
    color: AppColors.brandOrangeGlow,
  );

  static const TextStyle logoTouch = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontWeight: FontWeight.w300,
    fontSize: 28,
    letterSpacing: 10,
    color: AppColors.brandOrangeGlow, // full opacity — WCAG contrast fix
  );
}
