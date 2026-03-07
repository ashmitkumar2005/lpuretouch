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
    this.size = 64.0,
    this.onComplete,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _checkProgress;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Phase 1 (0–0.5): circle scales up with elastic overshoot
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );

    // Phase 2 (0.5–1.0): checkmark draws in
    _checkProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hapticFired) {
        _hapticFired = true;
        HapticFeedback.heavyImpact();
        widget.onComplete?.call();
      }
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
          return Transform.scale(
            scale: _scale.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _CheckmarkPainter(
                  progress: _checkProgress.value,
                  bgColor: AppColors.success,
                  checkColor: Colors.white,
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
  final double progress;
  final Color bgColor;
  final Color checkColor;

  const _CheckmarkPainter({
    required this.progress,
    required this.bgColor,
    required this.checkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle background
    canvas.drawCircle(center, radius, Paint()..color = bgColor);

    if (progress == 0) return;

    // Checkmark path: two segments
    // Tip at ~(25%, 55%), Mid at ~(42%, 70%), End at ~(75%, 35%)
    final double w = size.width;
    final double h = size.height;

    final p1 = Offset(w * 0.22, h * 0.52);
    final p2 = Offset(w * 0.42, h * 0.70);
    final p3 = Offset(w * 0.75, h * 0.33);

    final paint = Paint()
      ..color = checkColor
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Total path length split: first segment ~40% of total, second ~60%
    const seg1Frac = 0.40;

    if (progress <= seg1Frac) {
      // Draw first segment partly
      final t = progress / seg1Frac;
      final mid = Offset.lerp(p1, p2, t)!;
      canvas.drawLine(p1, mid, paint);
    } else {
      // Draw full first segment + partial second segment
      final t = (progress - seg1Frac) / (1.0 - seg1Frac);
      final mid = Offset.lerp(p2, p3, t)!;
      canvas.drawLine(p1, p2, paint);
      canvas.drawLine(p2, mid, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}
