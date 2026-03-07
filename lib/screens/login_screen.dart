import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/success_checkmark.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_retry_widget.dart';
import 'package:dio/dio.dart';

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
  
  final _biometricService = BiometricService();
  bool _canUseBiometrics = false;



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
    
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canUse = await _biometricService.canUseBiometrics();
    if (mounted) {
      setState(() => _canUseBiometrics = canUse);
    }
  }

  Future<void> _loginWithBiometrics() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'lpu_userId');
      final password = await storage.read(key: 'lpu_password');

      if (userId != null && password != null) {
        _userIdCtrl.text = userId;
        _passwordCtrl.text = password;
        _login(); // Perform standard login flow
      } else {
        setState(() => _error = 'Please login with credentials first');
      }
    }
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
      print('[LOGIN_SCREEN] Starting login for: ${_userIdCtrl.text.trim()}');
      final result = await _authService.login(
          _userIdCtrl.text.trim(), _passwordCtrl.text);
      print('[LOGIN_SCREEN] Result: ${result['success']}');
      
      if (!mounted) return;
      if (result['success'] == true) {
        if (mounted) {
          print('[LOGIN_SCREEN] Login success, showing checkmark...');
          // AuthService already fired updateLoginState(true)
          // Step 10: Show SuccessCheckmark dialog for 800ms then navigate
          bool dialogPopped = false;
          // Wait for the success dialog to finish and pop
          await showDialog(
            context: context,
            barrierColor: Colors.black26,
            barrierDismissible: false,
            builder: (ctx) {
              // Safety timeout
              Future.delayed(const Duration(milliseconds: 2500), () {
                if (ctx.mounted && !dialogPopped) {
                  dialogPopped = true;
                  Navigator.of(ctx).pop();
                }
              });
              
              return Center(
                child: SuccessCheckmark(
                  size: 80,
                  onComplete: () async {
                    if (!dialogPopped) {
                      dialogPopped = true;
                      // Small delay for the user to see the full checkmark
                      await Future.delayed(const Duration(milliseconds: 400));
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    }
                  },
                ),
              );
            },
          );

          if (mounted) {
            print('[LOGIN_SCREEN] Navigating to dashboard');
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } else {
        print('[LOGIN_SCREEN] Login failed: ${result['error']}');
        setState(() => _error = ErrorRetryWidget.friendlyMessage(result['error'] ?? 'Login failed'));
      }
    } catch (e, stack) {
      print('[LOGIN_SCREEN] Exception: $e');
      print(stack);
      setState(() => _error = ErrorRetryWidget.friendlyMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 13: Light bg -> dark status icons
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bgLogin,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgLoginTop, AppColors.bgLogin],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                        // Step 10: TOUCH alpha fixed to 1.0 (was 0.8)
                        const Text('LPU', style: AppTextStyles.logoLpu),
                        const SizedBox(width: 6),
                        const Text('TOUCH', style: AppTextStyles.logoTouch),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Logo
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
                      child: Container(
                        width: 140, height: 140,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgLoginTop,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 30,
                              offset: const Offset(14, 14),
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 30,
                              offset: Offset(-14, -14),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Glass card
                FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
                      decoration: BoxDecoration(
                        color: AppColors.bgLoginTop,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(14, 14),
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 30,
                            offset: Offset(-14, -14),
                          ),
                        ],
                      ),
                          child: Stack(
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text('Welcome Back',
                                          style: AppTextStyles.largeTitle.copyWith(fontSize: 32)),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    // Step 10: subtitle alpha raised from 0.4 → 0.7
                                    Text('Sign in to continue to LPU Touch',
                                        style: AppTextStyles.subhead.copyWith(
                                          color: AppColors.textPrimary.withOpacity(0.6),
                                        )),
                                    const SizedBox(height: 32),

                                    if (_error != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.red.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(_error!,
                                            style: const TextStyle(
                                                color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w600)),
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

                                    if (_canUseBiometrics) ...[
                                      const SizedBox(height: 16),
                                      _BiometricButton(onTap: _loginWithBiometrics),
                                    ],

                                    const SizedBox(height: AppSpacing.xl),
                                    // Step 10: Forgot Password — 48dp touch target
                                    Semantics(
                                      button: true,
                                      label: 'Forgot Password',
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.md,
                                          ),
                                          child: Text('Forgot Password?',
                                              style: AppTextStyles.footnote),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Divider(
                                        color: AppColors.divider.withOpacity(0.8),
                                        thickness: 1),
                                    const SizedBox(height: AppSpacing.md),
                                    // Step 10: Guest Access — Material+InkWell ripple
                                    Semantics(
                                      button: true,
                                      label: 'Guest Access',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {},
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                          splashColor: AppColors.brandOrangeGlow.withOpacity(0.22),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                              vertical: AppSpacing.xs,
                                            ),
                                            child: RichText(
                                              text: TextSpan(
                                                style: AppTextStyles.footnote,
                                                children: [
                                                  const TextSpan(text: 'New Here? '),
                                                  TextSpan(
                                                    text: 'Guest Access',
                                                    style: AppTextStyles.footnote.copyWith(
                                                      color: AppColors.brandOrangeGlow,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      ), // AnnotatedRegion close
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
    with TickerProviderStateMixin {
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
              child: SizedBox(
                height: 56,
                child: Stack(
                  children: [
                    // Base Neumorphic background
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgLoginTop,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(14, 14),
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 30,
                            offset: Offset(-14, -14),
                          ),
                        ],
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
                                  const Color(0xFF1A1A2E).withValues(alpha: 0.4),
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
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(14, 14),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 30,
                    offset: Offset(-14, -14),
                  ),
                ],
              ),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        height: 24, width: 80,
                        child: ShimmerLoading(
                          width: 80, 
                          height: 20, 
                          borderRadius: 4,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BiometricButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.bgLoginTop,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(4, 4),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: Offset(-4, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint_rounded, color: AppColors.brandOrangeGlow, size: 24),
            const SizedBox(width: 10),
            Text(
              'Sign in with Biometrics',
              style: AppTextStyles.buttonLabel.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
