import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

class ComingSoonScreen extends StatefulWidget {
  final String featureName;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    this.featureName = 'Gallery',
    this.icon = Icons.image_outlined,
  });

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated Neumorphic Icon Container ──────────────────────
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: 1.0 + _pulse.value * 0.04,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.bgDashboard,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.10 + _pulse.value * 0.05),
                            blurRadius: 28,
                            offset: const Offset(8, 8),
                          ),
                          BoxShadow(
                            color: Colors.white
                                .withOpacity(0.9 + _pulse.value * 0.1),
                            blurRadius: 28,
                            offset: const Offset(-8, -8),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 48,
                    color: AppColors.primaryBlue.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // ── "Coming Soon" heading ───────────────────────────────────
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.featureName} is under development\nand will be available soon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Neumorphic "dots" progress indicator ───────────────────
                _NeumorphicDots(animation: _pulse),

                const SizedBox(height: 48),

                // ── Neumorphic "Go Back" button ─────────────────────────────
                _NeumorphicButton(
                  label: 'Go Back',
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () {
                    // Just switch back to first tab via the GlobalLayout
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Neumorphic pulsing dots row ───────────────────────────────────────────────
class _NeumorphicDots extends StatelessWidget {
  final Animation<double> animation;
  const _NeumorphicDots({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (animation.value + i / 3) % 1.0;
            final scale = 0.7 + math.sin(phase * math.pi) * 0.5;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.bgDashboard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12 * scale),
                        blurRadius: 6,
                        offset: const Offset(3, 3),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 6,
                        offset: const Offset(-3, -3),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Neumorphic tappable button ─────────────────────────────────────────────────
class _NeumorphicButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _NeumorphicButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgDashboard,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _pressed
              ? [
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 6,
                    offset: Offset(-2, -2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13),
                    blurRadius: 18,
                    offset: const Offset(6, 6),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 18,
                    offset: Offset(-6, -6),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
