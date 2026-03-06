import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Auto-logout on app start if running on Linux to ensure fresh session for testing
  if (Platform.isLinux) {
// INIT Linux detected. Clearing session for fresh login...
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF26522)),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
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

/// Decides whether to show login or dashboard based on auth state
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

/// Premium Animated Splash Screen
class _PremiumSplash extends StatefulWidget {
  const _PremiumSplash();
  @override
  State<_PremiumSplash> createState() => _PremiumSplashState();
}

class _PremiumSplashState extends State<_PremiumSplash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glowOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1A2F4A)],
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
                    // GPU-Accelerated Glow Layer (0 repaints)
                    FadeTransition(
                      opacity: _glowOpacity,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withAlpha(50),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Static Logo Image
                    ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const RepaintBoundary(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('LPU', style: TextStyle(
                        color: Color(0xFFFF8C00),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        letterSpacing: -0.5,
                        fontFamily: 'Virgo',
                      )),
                      SizedBox(width: 6),
                      Text('TOUCH', style: TextStyle(
                        // using constant color here
                        color: Color(0xCCFF8C00), // 0xCC is roughly 200 alpha
                        fontWeight: FontWeight.w300,
                        fontSize: 28,
                        letterSpacing: 8,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    if (_activeIndex != targetIndex) {
      _setActiveIndex(targetIndex);
      await Future.delayed(const Duration(milliseconds: 50));
      navigatorKey.currentState?.pushReplacement(
        _createRoute(page, targetIndex, routeName)
      );
    }
  }

  PageRouteBuilder _createRoute(Widget page, int targetIndex, String routeName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Apple HIG: Top-level tab switching should generally NOT slide horizontally.
        // A subtle cross-fade with a very slight scale-up (zoom in) feels much more premium
        // and keeps the user grounded while the dock slime performs its lateral physics.
        
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic));
        var scaleTween = Tween<double>(begin: 0.97, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic));

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
                bottom: 24,
                left: 24,
                right: 24,
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
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 🍎 Apple-style Liquid Moving Highlighter
                            LiquidHighlighter(
                              activeIndex: _activeIndex,
                              itemWidth: itemWidth,
                            ),
                            // Navigation Icons - Using Expanded + Center for perfect alignment
                            Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: _DockIcon(
                                      icon: Icons.home_rounded,
                                      isActive: _activeIndex == 0,
                                      onTap: () {
                                        navigateTo(0, const DashboardScreen(), '/dashboard');
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: _DockIcon(
                                      icon: Icons.folder_open_rounded,
                                      isActive: _activeIndex == 1,
                                      onTap: () {
                                        _setActiveIndex(1);
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: _DockIcon(
                                      icon: Icons.add_rounded,
                                      isCenter: true,
                                      isActive: false,
                                      onTap: () {},
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: _DockIcon(
                                      icon: Icons.image_outlined,
                                      isActive: _activeIndex == 3,
                                      onTap: () {
                                        _setActiveIndex(3);
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: _DockIcon(
                                      icon: Icons.person_outline_rounded,
                                      isActive: _activeIndex == 4,
                                      onTap: () async {
                                        final user = await _authService.getUser();
                                        if (user != null) {
                                          navigateTo(4, ProfileScreen(user: user), '/profile');
                                        }
                                      },
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

class _LiquidHighlighterState extends State<LiquidHighlighter> with SingleTickerProviderStateMixin {
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

  double _calculateCenter(int index) {
    return (index * widget.itemWidth) + (widget.itemWidth / 2);
  }

  @override
  void didUpdateWidget(covariant LiquidHighlighter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      // Calculate current visual center based on animation state to handle interruptions seamlessly
      double t = Curves.easeOutCubic.transform(_controller.value);
      _startCenter = _startCenter + (_targetCenter - _startCenter) * t;
      _targetCenter = _calculateCenter(widget.activeIndex);
      _controller.forward(from: 0.0);
    } else if (widget.itemWidth != oldWidget.itemWidth) {
      final targetCenter = _calculateCenter(widget.activeIndex);
      _startCenter = targetCenter;
      _targetCenter = targetCenter;
      _currentCenter = targetCenter;
      setState((){});
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

    // 1. Motion Stretch: peaks at middle of animation
    double stretch = 0.0;
    if (isMoving) {
      stretch = math.sin(t * math.pi) * (distance * 0.12 + 5); 
    }

    // 2. Impact Squash (Horizontal): wobble as it arrives
    double squash = 0.0;
    if (isMoving && t > 0.5) {
      double endT = (t - 0.5) * 2; // maps to 0-1
      squash = math.sin(endT * math.pi * 2.5) * (1 - endT) * 12; // damped wiggle
    }

    double currentWidth = 52.0 + stretch + squash;
    double currentHeight = 52.0 - (stretch * 0.25) - (squash * 0.6);

    // Safety bounds: ensures width is NEVER < 48 (preventing vertical squashing feeling)
    currentWidth = currentWidth.clamp(48.0, 150.0);
    currentHeight = currentHeight.clamp(30.0, 56.0);

    return Positioned(
      left: _currentCenter - (currentWidth / 2),
      top: 10 + (52.0 - currentHeight) / 2, // Keep vertically centered
      child: Container(
        width: currentWidth,
        height: currentHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(currentHeight / 2), // maintain smooth pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4),
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Color(0xFF2050E4), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              icon,
              key: ValueKey(isActive),
              color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.7),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
