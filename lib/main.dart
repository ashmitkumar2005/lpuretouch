import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const LpuTouchApp());
}

class LpuTouchApp extends StatelessWidget {
  const LpuTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LPU Touch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF26522)),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
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
