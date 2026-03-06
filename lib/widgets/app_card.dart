import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

// ════════════════════════════════════════════════════════════════════════════
//  AppCard — LPU Touch
//  A versatile card with solid-white or glassmorphism styles.
// ════════════════════════════════════════════════════════════════════════════

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool isGlass;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.isGlass = false,
    this.onTap,
    this.radius = AppRadius.xl,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.xl);
    final clipRadius = BorderRadius.circular(radius);

    Widget content = Padding(padding: effectivePadding, child: child);

    if (isGlass) {
      content = ClipRRect(
        borderRadius: clipRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardGlass,
              borderRadius: clipRadius,
              border: Border.all(
                color: AppColors.cardGlassBorder,
                width: 1.5,
              ),
            ),
            child: content,
          ),
        ),
      );
    } else {
      content = Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: clipRadius,
          boxShadow: AppShadows.cardSoft,
        ),
        child: content,
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: clipRadius,
          splashColor: AppColors.primaryBlue.withOpacity(0.06),
          highlightColor: AppColors.primaryBlue.withOpacity(0.03),
          child: content,
        ),
      );
    }

    return content;
  }
}
