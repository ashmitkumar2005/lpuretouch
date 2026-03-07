import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

// ════════════════════════════════════════════════════════════════════════════
//  AnimatedListItem — LPU Touch
//  Staggered fade + slide-up entry animation for list children.
// ════════════════════════════════════════════════════════════════════════════

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );

    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _translateY = Tween<double>(begin: 20.0, end: 0.0).animate(curved);

    // Staggered start: each item delays by (index * delay)
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
        ),
        child: widget.child,
      ),
    );
  }
}
