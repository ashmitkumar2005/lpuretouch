import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/design_tokens.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
    this.shape = BoxShape.rectangle,
  });

  /// Shimmer for a generic card
  factory ShimmerLoading.card({double? width, double? height}) {
    return ShimmerLoading(
      width: width ?? double.infinity,
      height: height ?? 100,
      borderRadius: AppRadius.lg,
    );
  }

  /// Shimmer for a circle (e.g. Avatar)
  factory ShimmerLoading.circle({required double size}) {
    return ShimmerLoading(
      width: size,
      height: size,
      shape: BoxShape.circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle 
            ? BorderRadius.circular(borderRadius) 
            : null,
        ),
      ),
    );
  }
}
