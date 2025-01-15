import 'package:flutter/material.dart';
import 'package:blink_app/features/onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    try {
      _mainController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      );

      _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
        ),
      );

      Future.microtask(() {
        if (mounted) {
          _mainController.forward();
        }
      });
    } catch (e) {
      debugPrint('Error initializing SplashScreen: $e');
    }

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    try {
      _mainController.dispose();
    } catch (e) {
      debugPrint('Error disposing SplashScreen controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D47A1), // Rich azure blue
              const Color(0xFF1565C0), // Medium azure blue
              const Color(0xFF1976D2), // Lighter azure blue
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Hero(
              tag: 'logo',
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  double maxSize = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: maxSize * 0.25,
                        height: maxSize * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      // Logo
                      Image.asset(
                        'assets/images/blink_logo_white.png',
                        width: maxSize * 0.22,
                        height: maxSize * 0.22,
                        fit: BoxFit.contain,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
