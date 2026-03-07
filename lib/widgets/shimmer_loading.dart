import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

class ShimmerLoading extends StatefulWidget {
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
      borderRadius: size / 2,
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _slide =
        Tween<Offset>(begin: const Offset(-1.5, 0), end: const Offset(1.5, 0))
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.black.withAlpha(10);
    final highlightColor = Colors.black.withAlpha(25);

    return ClipRRect(
      borderRadius: widget.shape == BoxShape.circle 
          ? BorderRadius.circular(widget.height / 2)
          : BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            Container(color: baseColor),
            Positioned.fill(
              child: SlideTransition(
                position: _slide,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        highlightColor,
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
