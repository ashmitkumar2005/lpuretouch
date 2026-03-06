import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'core/theme/design_tokens.dart';
import 'core/theme/app_theme.dart' as theme_module;
import 'core/theme/app_text_styles.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 13: Transparent status bar, dark icons globally
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Auto-logout on Linux for dev testing
  if (Platform.isLinux) {
    await AuthService().logout();
  }

  runApp(const LpuTouchApp());
}

class LpuTouchApp extends StatelessWidget {
  const LpuTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'LPU Touch',
      debugShowCheckedModeBanner: false,
      theme: theme_module.AppTheme.light,
      home: const _SplashRouter(),
      builder: (context, child) {
        return GlobalLayout(child: child!);
      },
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/dashboard': (ctx) => const DashboardScreen(),
      },
    );
  }
}

// ─── Splash Router ────────────────────────────────────────────────────────────
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PremiumSplash();
        }
        if (snapshot.data == true) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ─── Premium Animated Splash Screen ───────────────────────────────────────────
class _PremiumSplash extends StatefulWidget {
  const _PremiumSplash();

  @override
  State<_PremiumSplash> createState() => _PremiumSplashState();
}

class _PremiumSplashState extends State<_PremiumSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glowOpacity = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Step 13: Dark bg splash — override to light status bar icons
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.splashDark, AppColors.splashDarkMid],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      FadeTransition(
                        opacity: _glowOpacity,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandOrangeGlow.withAlpha(50),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'LPU Logo',
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  RepaintBoundary(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('LPU', style: AppTextStyles.logoLpu),
                        const SizedBox(width: 6),
                        Text('TOUCH', style: AppTextStyles.logoTouch),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Global Layout (Dock + Route Management) ──────────────────────────────────
class GlobalLayout extends StatefulWidget {
  final Widget child;
  const GlobalLayout({super.key, required this.child});

  static GlobalLayoutState? of(BuildContext context) {
    return context.findAncestorStateOfType<GlobalLayoutState>();
  }

  @override
  State<GlobalLayout> createState() => GlobalLayoutState();
}

class GlobalLayoutState extends State<GlobalLayout> {
  final _authService = AuthService();
  bool _isLoggedIn = false;
  int _activeIndex = 0;

  // Step 15: Navigation debounce
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    refreshAuthState();
  }

  Future<void> refreshAuthState() async {
    final loggedIn = await _authService.isLoggedIn();
    if (mounted && _isLoggedIn != loggedIn) {
      setState(() {
        _isLoggedIn = loggedIn;
      });
    }
  }

  void _setActiveIndex(int index) {
    if (!mounted) return;
    setState(() => _activeIndex = index);
  }

  void navigateTo(int targetIndex, Widget page, String routeName) async {
    // Step 15: Debounce guard — ignore taps < 300ms apart or same tab
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < AppDurations.medium) {
      return;
    }
    if (_activeIndex == targetIndex) return;
    _lastTapTime = now;

    _setActiveIndex(targetIndex);
    await Future.delayed(const Duration(milliseconds: 50));
    navigatorKey.currentState?.pushReplacement(
        _createRoute(page, targetIndex, routeName));
  }

  PageRouteBuilder _createRoute(Widget page, int targetIndex, String routeName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppDurations.medium,
      reverseTransitionDuration: AppDurations.medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeTween =
            Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));
        final scaleTween =
            Tween<double>(begin: 0.97, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLoggedIn)
          Positioned(
            bottom: AppSpacing.xxl,
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dockWidth = constraints.maxWidth;
                final itemWidth = dockWidth / 5;

                return Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 72,
                    clipBehavior: Clip.none,
                    decoration: BoxDecoration(
                      color: AppColors.dockBg,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        LiquidHighlighter(
                          activeIndex: _activeIndex,
                          itemWidth: itemWidth,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Semantics(
                                  label: 'Home',
                                  selected: _activeIndex == 0,
                                  button: true,
                                  child: _DockIcon(
                                    icon: Icons.home_rounded,
                                    isActive: _activeIndex == 0,
                                    onTap: () => navigateTo(
                                        0, const DashboardScreen(), '/dashboard'),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Semantics(
                                  label: 'Files',
                                  selected: _activeIndex == 1,
                                  button: true,
                                  child: _DockIcon(
                                    icon: Icons.folder_open_rounded,
                                    isActive: _activeIndex == 1,
                                    onTap: () => _setActiveIndex(1),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Semantics(
                                  label: 'Add',
                                  button: true,
                                  child: _DockIcon(
                                    icon: Icons.add_rounded,
                                    isCenter: true,
                                    isActive: false,
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Semantics(
                                  label: 'Gallery',
                                  selected: _activeIndex == 3,
                                  button: true,
                                  child: _DockIcon(
                                    icon: Icons.image_outlined,
                                    isActive: _activeIndex == 3,
                                    onTap: () => _setActiveIndex(3),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Semantics(
                                  label: 'Profile',
                                  selected: _activeIndex == 4,
                                  button: true,
                                  child: _DockIcon(
                                    icon: Icons.person_outline_rounded,
                                    isActive: _activeIndex == 4,
                                    onTap: () async {
                                      final user =
                                          await _authService.getUser();
                                      if (user != null) {
                                        navigateTo(4,
                                            ProfileScreen(user: user), '/profile');
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── Liquid Highlighter ───────────────────────────────────────────────────────
class LiquidHighlighter extends StatefulWidget {
  final int activeIndex;
  final double itemWidth;

  const LiquidHighlighter({
    super.key,
    required this.activeIndex,
    required this.itemWidth,
  });

  @override
  State<LiquidHighlighter> createState() => _LiquidHighlighterState();
}

class _LiquidHighlighterState extends State<LiquidHighlighter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _startCenter;
  late double _targetCenter;
  late double _currentCenter;

  @override
  void initState() {
    super.initState();
    _startCenter = _calculateCenter(widget.activeIndex);
    _targetCenter = _startCenter;
    _currentCenter = _startCenter;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _controller.addListener(() {
      setState(() {});
    });
  }

  double _calculateCenter(int index) =>
      (index * widget.itemWidth) + (widget.itemWidth / 2);

  @override
  void didUpdateWidget(covariant LiquidHighlighter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      double t = Curves.easeOutCubic.transform(_controller.value);
      _startCenter = _startCenter + (_targetCenter - _startCenter) * t;
      _targetCenter = _calculateCenter(widget.activeIndex);
      _controller.forward(from: 0.0);
    } else if (widget.itemWidth != oldWidget.itemWidth) {
      final c = _calculateCenter(widget.activeIndex);
      _startCenter = c;
      _targetCenter = c;
      _currentCenter = c;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double t = _controller.value;
    double curveT = Curves.easeOutCubic.transform(t);
    _currentCenter = _startCenter + (_targetCenter - _startCenter) * curveT;

    double distance = (_targetCenter - _startCenter).abs();
    bool isMoving = distance > 1.0;

    double stretch = 0.0;
    if (isMoving) stretch = math.sin(t * math.pi) * (distance * 0.12 + 5);

    double squash = 0.0;
    if (isMoving && t > 0.5) {
      double endT = (t - 0.5) * 2;
      squash = math.sin(endT * math.pi * 2.5) * (1 - endT) * 12;
    }

    double currentWidth = (52.0 + stretch + squash).clamp(48.0, 150.0);
    double currentHeight = (52.0 - (stretch * 0.25) - (squash * 0.6)).clamp(30.0, 56.0);

    return Positioned(
      left: _currentCenter - (currentWidth / 2),
      top: 10 + (52.0 - currentHeight) / 2,
      child: Container(
        width: currentWidth,
        height: currentHeight,
        decoration: BoxDecoration(
          color: AppColors.dockHighlight,
          borderRadius: BorderRadius.circular(currentHeight / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isCenter;
  final VoidCallback onTap;

  const _DockIcon({
    required this.icon,
    this.isActive = false,
    this.isCenter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isCenter) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
              color: AppColors.dockCenterBg, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppSpacing.massive, // 48dp touch target
        height: AppSpacing.massive,
        child: Center(
          child: AnimatedSwitcher(
            duration: AppDurations.medium,
            child: Icon(
              icon,
              key: ValueKey(isActive),
              color: isActive
                  ? AppColors.dockIconActive
                  : AppColors.dockIconInactive,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
