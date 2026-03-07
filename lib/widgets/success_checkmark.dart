import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/design_tokens.dart';

// ════════════════════════════════════════════════════════════════════════════
//  SuccessCheckmark — LPU Touch
//  Animated circle that scales up → draws white checkmark inside.
//  Triggers HapticFeedback.heavyImpact() on completion.
// ════════════════════════════════════════════════════════════════════════════

class SuccessCheckmark extends StatefulWidget {
  final double size;
  final VoidCallback? onComplete;

  const SuccessCheckmark({
    super.key,
    this.size = 80.0,
    this.onComplete,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _ringProgress;
  late final Animation<double> _checkProgress;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Initial scale & fade in
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Phase 1 (0.1–0.6): Outer ring draws
    _ringProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.6, curve: Curves.easeInOutCubic),
      ),
    );

    // Phase 2 (0.5–1.0): Checkmark draws
    _checkProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hapticFired) {
        _hapticFired = true;
        HapticFeedback.mediumImpact();
        widget.onComplete?.call();
      }
    });

    // Small delay haptic for the "pop"
    Future.delayed(const Duration(milliseconds: 100), () {
       if (mounted) HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _CheckmarkPainter(
                    ringProgress: _ringProgress.value,
                    checkProgress: _checkProgress.value,
                    color: const Color(0xFF1C1C1E), // Premium dark gray/black
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double ringProgress;
  final double checkProgress;
  final Color color;

  const _CheckmarkPainter({
    required this.ringProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.07;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 1. Draw Ring
    if (ringProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -1.5708, // -90 degrees (top)
        6.28318 * ringProgress, // 360 degrees
        false,
        paint,
      );
    }

    // 2. Draw Checkmark
    if (checkProgress > 0) {
      final double w = size.width;
      final double h = size.height;

      // Premium proportions for the tick
      final p1 = Offset(w * 0.28, h * 0.52);
      final p2 = Offset(w * 0.44, h * 0.68);
      final p3 = Offset(w * 0.72, h * 0.36);

      const seg1Frac = 0.40;
      if (checkProgress <= seg1Frac) {
        final t = checkProgress / seg1Frac;
        final mid = Offset.lerp(p1, p2, t)!;
        canvas.drawLine(p1, mid, paint);
      } else {
        final t = (checkProgress - seg1Frac) / (1.0 - seg1Frac);
        final mid = Offset.lerp(p2, p3, t)!;
        canvas.drawLine(p1, p2, paint);
        canvas.drawLine(p2, mid, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.ringProgress != ringProgress || old.checkProgress != checkProgress;
}
