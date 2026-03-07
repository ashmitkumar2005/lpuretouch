import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'widgets/offline_banner.dart';
import 'core/theme/design_tokens.dart';
import 'core/theme/app_theme.dart' as theme_module;
import 'core/theme/app_text_styles.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Tracks route stack depth so the dock hides on any pushed non-main screen.
const _mainRoutes = {'/', '/dashboard', '/timetable', '/profile', '/login'};

class _DockObserver extends NavigatorObserver {
  // > 0 means dock should be hidden
  final ValueNotifier<int> modalDepth = ValueNotifier(0);

  bool _shouldHide(Route? route) {
    if (route == null) return false;
    if (route is PopupRoute) return true;
    final name = route.settings.name;
    // Hide dock for any named route that isn't a main tab,
    // and also for any unnamed pushed page routes (e.g. MaterialPageRoute).
    if (name == null) {
      // Unnamed routes are always sub-pages (e.g. AnnouncementsScreen)
      return true;
    }
    return !_mainRoutes.contains(name);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (_shouldHide(route)) modalDepth.value++;
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (_shouldHide(route)) {
      modalDepth.value = (modalDepth.value - 1).clamp(0, 99);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (_shouldHide(route)) {
      modalDepth.value = (modalDepth.value - 1).clamp(0, 99);
    }
  }
}

final _dockObserver = _DockObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 13: Transparent status bar, dark icons globally
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Init cache before runApp so it's ready for first frame
  await CacheService().init();
  await ConnectivityService().init();

  // Auto-logout on Linux for dev testing
  if (Platform.isLinux) {
    await AuthService().logout();
  }

  runApp(const LpuTouchApp());
}

// ─── Lenis-equivalent smooth scroll ─────────────────────────────────────────
// BouncingScrollPhysics gives momentum-preserving inertia (same feel as
// Lenis on web). Applied globally so every scrollable gets it automatically.
class _LenisBehavior extends ScrollBehavior {
  const _LenisBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

// ─── Root App ─────────────────────────────────────────────────────────────────
class LpuTouchApp extends StatelessWidget {
  const LpuTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const _LenisBehavior(),
      navigatorKey: navigatorKey,
      navigatorObservers: [_dockObserver],
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
      future: AuthService().validateSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PremiumSplash();
        }

        // Mark app as ready to allow dock visibility once splash is done
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GlobalLayout.isAppReady.value = true;
        });

        // If validation successful, go to dashboard. Otherwise, login.
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

  // Tracks if the initial splash sequence is finished
  static final ValueNotifier<bool> isAppReady = ValueNotifier(false);

  @override
  State<GlobalLayout> createState() => GlobalLayoutState();
}

class GlobalLayoutState extends State<GlobalLayout> {
  final _authService = AuthService();
  int _activeIndex = 0;

  // Step 15: Navigation debounce
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    refreshAuthState();
    AuthService.onForceLogout.addListener(_handleForceLogout);
  }

  @override
  void dispose() {
    AuthService.onForceLogout.removeListener(_handleForceLogout);
    super.dispose();
  }

  void _handleForceLogout() {
    if (AuthService.onForceLogout.value) {
      AuthService.resetForceLogout();
      if (mounted) {
        // Clear navigation stack and go to login
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> refreshAuthState() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      // Synchronize the notifier if we found a token on startup
      _authService.updateLoginState(true);
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
        ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService().isConnected,
          builder: (context, isConnected, _) {
            return OfflineBanner(visible: !isConnected);
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: GlobalLayout.isAppReady,
          builder: (context, isAppReady, _) {
            if (!isAppReady) return const SizedBox.shrink();

            return ValueListenableBuilder<bool>(
              valueListenable: _authService.isLoggedInNotifier,
              builder: (context, isLoggedIn, _) {
                if (!isLoggedIn) return const SizedBox.shrink();

                return Positioned(
                  bottom: AppSpacing.xxl - 13,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _dockObserver.modalDepth,
                    builder: (_, depth, dockChild) => AnimatedSlide(
                      offset: depth > 0 ? const Offset(0, 2.5) : Offset.zero,
                      duration: depth > 0
                          ? const Duration(milliseconds: 220)
                          : const Duration(milliseconds: 380),
                      curve: depth > 0 ? Curves.easeIn : Curves.elasticOut,
                      child: dockChild!,
                    ),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.75,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final dockWidth = constraints.maxWidth;
                            final itemWidth = dockWidth / 5;

                            return RepaintBoundary(
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(36),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            width: 1.0,
                                          ),
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
                                                _buildDockItem(0, Icons.home_rounded, 'Home',
                                                    () => navigateTo(0, const DashboardScreen(), '/dashboard')),
                                                _buildDockItem(1, Icons.calendar_month_rounded, 'Timetable',
                                                    () => navigateTo(1, const TimetableScreen(), '/timetable')),
                                                _buildDockItem(2, Icons.folder_open_rounded, 'Files',
                                                    () => _setActiveIndex(2)),
                                                _buildDockItem(3, Icons.image_outlined, 'Gallery',
                                                    () => _setActiveIndex(3)),
                                                _buildDockItem(4, Icons.person_outline_rounded, 'Profile', () async {
                                                  final user = await _authService.getUser();
                                                  if (user != null) {
                                                    navigateTo(4, ProfileScreen(user: user), '/profile');
                                                  }
                                                }),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDockItem(int index, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Center(
        child: Semantics(
          label: label,
          selected: _activeIndex == index,
          button: true,
          child: _DockIcon(
            icon: icon,
            isActive: _activeIndex == index,
            onTap: onTap,
          ),
        ),
      ),
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
  late AnimationController _ctrl;

  double _centerXFor(int index) =>
      index * widget.itemWidth + widget.itemWidth / 2;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 48, // >= 2*sqrt(500)≈44.7 → no overshoot
  );

  void _springTo(double target) {
    _ctrl.animateWith(
        SpringSimulation(_spring, _ctrl.value, target, _ctrl.velocity));
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(
        vsync: this, value: _centerXFor(widget.activeIndex));
  }

  @override
  void didUpdateWidget(covariant LiquidHighlighter old) {
    super.didUpdateWidget(old);
    if (widget.activeIndex != old.activeIndex) {
      _springTo(_centerXFor(widget.activeIndex));
    } else if (widget.itemWidth != old.itemWidth) {
      _ctrl.value = _centerXFor(widget.activeIndex);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double pillH = 48.0;
    const double pillW = 52.0;
    const double dockH = 72.0;
    const double pillTop = (dockH - pillH) / 2;

    final minX = _centerXFor(0);
    final maxX = _centerXFor(4);

    return Positioned(
      left: 0,
      top: pillTop,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          // Clamp so it never flies outside the bounds
          final cx = _ctrl.value.clamp(minX - 4, maxX + 4);
          final vel = _ctrl.velocity;
          // Squash-stretch scalar
          final scaleX = 1.0 + (vel.abs() * 0.0012).clamp(0.0, 0.35);

          // Zero-paint layout translations (pure GPU matrix)
          return Transform.translate(
            offset: Offset(cx - pillW / 2, 0),
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: 1.0 / scaleX,
              child: child,
            ),
          );
        },
        child: Container(
          width: pillW,
          height: pillH,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(pillH / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DockIcon({
    required this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppSpacing.massive,
        height: AppSpacing.massive,
        child: Center(
          // Static icon — no animation controller, no rebuilds.
          // The sliding pill IS the active indicator.
          child: Icon(
            icon,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            size: 26,
          ),
        ),
      ),
    );
  }
}
