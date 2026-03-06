import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  static const double _topSlotHeight = 0;

  late AnimationController _entranceCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;

  late Animation<double> _logoFade, _textFade, _cardFade;
  late Animation<Offset> _logoSlide, _textSlide, _cardSlide;
  late Animation<double> _float, _glowOpacity;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _textFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _textSlide = Tween<Offset>(
        begin: const Offset(0, -0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOut)));
    _logoSlide = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.15, 0.7, curve: Curves.easeOutBack)));

    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut)));
    _cardSlide = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic)));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.3, end: 0.6).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 80),
        () { if (mounted) _entranceCtrl.forward(); });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _authService.login(
          _userIdCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _error = result['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFD6DBE6),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBEEF3), Color(0xFFD6DBE6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 28),

                // LPU TOUCH header
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('LPU', style: TextStyle(
                          color: Color(0xFFFF8C00),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          fontFamily: 'Virgo',
                        )),
                        const SizedBox(width: 4),
                        Text('TOUCH', style: TextStyle(
                          color: const Color(0xFFFF8C00).withAlpha(220),
                          fontWeight: FontWeight.w300,
                          fontSize: 24,
                          letterSpacing: 6,
                        )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_topSlotHeight > 0) ...[
                  SizedBox(height: _topSlotHeight,
                      child: const Center(child: SizedBox.shrink())),
                  const SizedBox(height: 16),
                ],

                // Logo: floats + pulses
                FadeTransition(
                  opacity: _logoFade,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _float.value),
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // GPU-Accelerated Glow
                          FadeTransition(
                            opacity: _glowOpacity,
                            child: Container(
                              width: 160, height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8C00).withAlpha(40),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ClipOval(child: Image.asset(
                            'assets/logo.png',
                            width: 122, height: 122, fit: BoxFit.cover,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Glass card
                FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                          decoration: BoxDecoration(
                            // Gradient fill: top bright, bottom slightly dim — like light from above
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withAlpha(220),
                                Colors.white.withAlpha(155),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withAlpha(230),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(18),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(children: [
                            Form(
                              key: _formKey,
                              child: Column(children: [
                              const Text('Welcome Back',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  )),
                              const SizedBox(height: 6),
                              const Text('Sign in to continue to LPU Touch',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  )),
                              const SizedBox(height: 28),

                              if (_error != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.red.withAlpha(76)),
                                  ),
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 13)),
                                ),
                              ],

                              _LiquidGlassField(
                                controller: _userIdCtrl,
                                hint: 'Registration Number',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => v!.isEmpty
                                    ? 'Registration Number required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _LiquidGlassField(
                                controller: _passwordCtrl,
                                hint: 'Password',
                                prefixIcon: Icons.key_outlined,
                                obscure: _obscurePassword,
                                suffixWidget: GestureDetector(
                                  onTap: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'Password required' : null,
                              ),
                              const SizedBox(height: 20),

                              _AnimatedButton(
                                  loading: _loading, onTap: _login),

                              const SizedBox(height: 20),
                              const Text('Forgot Password?',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280))),
                              const SizedBox(height: 16),
                              Divider(
                                  color: const Color(0xFFE5E7EB).withAlpha(200),
                                  thickness: 1),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('New Here? ',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280))),
                                  Text('Guest Access',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFFF8C00),
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ]),
                          ),  // close Form
                         ]),  // close Stack children
                        ),    // close Container
                      ),      // close BackdropFilter
                    ),        // close ClipRRect
                  ),          // close SlideTransition child
                ),            // close FadeTransition child


                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ══════════════════════════════════════════════════════════════
//  Apple Liquid Glass Field
// ══════════════════════════════════════════════════════════════
class _LiquidGlassField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;

  const _LiquidGlassField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscure = false,
    this.suffixWidget,
    this.validator,
  });

  @override
  State<_LiquidGlassField> createState() => _LiquidGlassFieldState();
}

class _LiquidGlassFieldState extends State<_LiquidGlassField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focus;
  late AnimationController _animCtrl;
  late Animation<double> _glowOpacity;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();

    // Focus glow animation
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _glowOpacity = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    });

    // Shake animation: 400ms damped oscillation
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shake = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _focus.dispose();
    _animCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _triggerError(String? err) {
    setState(() => _errorText = err);
    if (err != null) {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.mediumImpact();
    } else {
      _shakeCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Field with shake wrapper ─────────────────────────
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final shakeOffset =
                math.sin(_shake.value * math.pi * 8) * 8 * (1 - _shake.value);
            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: child,
            );
          },
          child: RepaintBoundary( // Prevent blurring recreation during shake
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: SizedBox(
                  height: 56,
                  child: Stack(
                    children: [
                      // Base unfocused background (Static)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withAlpha(200),
                              Colors.white.withAlpha(140),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withAlpha(220),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      // GPU-Accelerated Focused Background Glow
                      FadeTransition(
                        opacity: _glowOpacity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withAlpha(170),
                                Colors.white.withAlpha(120),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFF8C00),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withAlpha(50),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                        // Top specular highlight
                        Positioned(
                          top: 0, left: 12, right: 12,
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                Colors.white.withAlpha(220),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                        // Text field
                        SizedBox.expand(
                          child: TextFormField(
                            controller: widget.controller,
                            focusNode: _focus,
                            obscureText: widget.obscure,
                            textAlignVertical: TextAlignVertical.center,
                            validator: (v) {
                              final err = widget.validator?.call(v);
                              _triggerError(err);
                              return err;
                            },
                            style: const TextStyle(
                                color: Color(0xFF1A1A2E), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: widget.hint,
                              hintStyle: TextStyle(
                                  color:
                                      const Color(0xFF1A1A2E).withAlpha(100),
                                  fontSize: 15),
                              prefixIcon: AnimatedBuilder(
                                animation: _glowOpacity,
                                builder: (context, child) => Icon(
                                  widget.prefixIcon,
                                  color: Color.lerp(
                                    const Color(0xFF9CA3AF),
                                    const Color(0xFFFF8C00),
                                    _glowOpacity.value * 0.6,
                                  ),
                                  size: 20,
                                ),
                              ),
                              suffixIcon: widget.suffixWidget,
                              border: InputBorder.none,
                              isDense: true,
                              errorStyle: const TextStyle(
                                  height: 0,
                                  fontSize: 0,
                                  color: Colors.transparent),
                              errorMaxLines: 1,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ), // Stack
                  ), // SizedBox
                ), // BackdropFilter
              ), // ClipRRect
            ), // RepaintBoundary
          ), // AnimatedBuilder
        // ── Styled error message ─────────────────────────────
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 5),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: Color(0xFFE53935)),
                const SizedBox(width: 4),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}


// Animated Sign In button
class _AnimatedButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _AnimatedButton({required this.loading, required this.onTap});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); if (!widget.loading) widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: RepaintBoundary( // Caches button contents to avoid blurring dynamically
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  // Left-to-right gradient for button premium look
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.loading
                        ? [
                            Colors.black.withAlpha(160),
                            Colors.black.withAlpha(130),
                          ]
                        : [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF0A0A0A),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withAlpha(30),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top specular highlight
                    Positioned(
                      top: 0, left: 20, right: 20,
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            Colors.white.withAlpha(70),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    Center(
                      child: widget.loading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(
                                  color: Color(0xFFFF8C00), strokeWidth: 2),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
