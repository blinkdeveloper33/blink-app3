import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' show pi, sin, cos, Random, sqrt;
import 'package:provider/provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import '../blink_advance_screen.dart';
import 'package:http/http.dart' as http;
import 'package:blink_app/config/api_config.dart';
import 'dart:convert';

class Particle {
  double x;
  double y;
  double speed;
  double theta;
  double radius;
  Color color;
  double opacity;
  double velocityX;
  double velocityY;
  double glowRadius;
  double glowIntensity;
  final random = Random();

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.theta,
    required this.radius,
    required this.color,
    required this.opacity,
    required this.velocityX,
    required this.velocityY,
    required this.glowRadius,
    required this.glowIntensity,
  });

  factory Particle.random() {
    final random = Random();
    final baseRadius = random.nextDouble() * 2 + 1;
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      speed: random.nextDouble() * 0.2 + 0.1,
      theta: random.nextDouble() * 2 * pi,
      radius: baseRadius,
      color: Colors.white.withOpacity(random.nextDouble() * 0.3),
      opacity: random.nextDouble() * 0.5,
      velocityX: (random.nextDouble() - 0.5) * 0.01,
      velocityY: (random.nextDouble() - 0.5) * 0.01,
      glowRadius: baseRadius * 3,
      glowIntensity: random.nextDouble() * 0.3 + 0.2,
    );
  }

  void update(double animation) {
    x += velocityX * sin(animation * pi * 2);
    y += velocityY * cos(animation * pi * 2);
    opacity += (random.nextDouble() - 0.5) * 0.01;
    opacity = opacity.clamp(0.1, 0.5);

    radius += sin(animation * pi * 4) * 0.1;
    glowRadius = radius * 3 + sin(animation * pi * 2) * radius;
    glowIntensity = (0.2 + sin(animation * pi * 2) * 0.1).clamp(0.1, 0.4);

    if (x < 0) {
      x = 1;
      velocityX = -velocityX;
    } else if (x > 1) {
      x = 0;
      velocityX = -velocityX;
    }

    if (y < 0) {
      y = 1;
      velocityY = -velocityY;
    } else if (y > 1) {
      y = 0;
      velocityY = -velocityY;
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final random = Random();

  ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.update(animation.value);

      // Draw particle glow with multiple layers for smooth transition
      final glowPaint = Paint()
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          particle.glowRadius,
        );

      // Outer glow
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.1);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius * 3,
        glowPaint,
      );

      // Middle glow
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.2);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius * 2,
        glowPaint,
      );

      // Inner glow
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.3);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius,
        glowPaint,
      );

      // Core particle
      paint.color = Colors.white.withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );

      // Draw connecting lines with smooth opacity transition
      for (var other in particles) {
        final distance = _calculateDistance(
          particle.x * size.width,
          particle.y * size.height,
          other.x * size.width,
          other.y * size.height,
        );

        if (distance < 100) {
          final opacity = (1 - distance / 100) * 0.15 * particle.opacity;
          canvas.drawLine(
            Offset(particle.x * size.width, particle.y * size.height),
            Offset(other.x * size.width, other.y * size.height),
            Paint()
              ..color = Colors.white.withOpacity(opacity)
              ..strokeWidth = 0.5
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class BlinkAdvanceSplashScreen extends StatefulWidget {
  final String bankAccountId;

  const BlinkAdvanceSplashScreen({
    Key? key,
    required this.bankAccountId,
  }) : super(key: key);

  @override
  State<BlinkAdvanceSplashScreen> createState() =>
      _BlinkAdvanceSplashScreenState();
}

class _BlinkAdvanceSplashScreenState extends State<BlinkAdvanceSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  bool _isTransitioning = false;
  final List<Particle> _particles = [];
  final int _numberOfParticles = 50;
  Map<String, dynamic>? _activeAdvance;
  bool _hasActiveAdvance = false;
  bool _isLoading = true;
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkActiveAdvance();
  }

  void _initializeAnimations() {
    // Initialize logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 60.0,
      ),
    ]).animate(_logoController);

    _logoOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60.0,
      ),
    ]).animate(_logoController);

    // Initialize background animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    // Initialize particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    // Initialize particles
    _initializeParticles();

    // Start animations
    _logoController.forward();
  }

  Future<void> _checkActiveAdvance() async {
    try {
      // Start loading animation
      setState(() {
        _isLoading = true;
      });

      // Create a minimum loading duration for better UX
      final minimumLoadingDuration =
          Future.delayed(const Duration(milliseconds: 2500));

      // Get auth token and make API call
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/blink-advances/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Wait for minimum loading time to complete
      await minimumLoadingDuration;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          // Fade out current content
          _logoController.reverse();

          await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted) return;

          // Update state and show warning
          setState(() {
            _activeAdvance = data['data'];
            _hasActiveAdvance = true;
            _isLoading = false;
          });

          // Animate warning content in
          _logoController.forward(from: 0.0);

          // Show warning for 5 seconds then return to home
          await Future.delayed(const Duration(seconds: 5));

          if (!mounted) return;

          // Fade out warning
          await _logoController.reverse();

          if (!mounted) return;

          // Return to home with data
          Navigator.of(context).pop(_activeAdvance);
        } else {
          setState(() {
            _isLoading = false;
          });
          _proceedToAdvanceScreen();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _proceedToAdvanceScreen();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _proceedToAdvanceScreen();
    }
  }

  void _proceedToAdvanceScreen() {
    _scheduleTransition();
  }

  Future<void> _scheduleTransition() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return BlinkAdvanceScreen(bankAccountId: widget.bankAccountId);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _initializeParticles() {
    for (int i = 0; i < _numberOfParticles; i++) {
      _particles.add(Particle.random());
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background with color based on active advance
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _hasActiveAdvance
                        ? [
                            Color.lerp(
                              const Color(0xFFB91C1C),
                              const Color(0xFF991B1B),
                              _backgroundAnimation.value,
                            )!,
                            Color.lerp(
                              const Color(0xFF7F1D1D),
                              const Color(0xFF881D1D),
                              _backgroundAnimation.value,
                            )!,
                          ]
                        : [
                            Color.lerp(
                              const Color(0xFF1E40AF),
                              const Color(0xFF1E3A8A),
                              _backgroundAnimation.value,
                            )!,
                            Color.lerp(
                              const Color(0xFF1E3A8A),
                              const Color(0xFF2563EB),
                              _backgroundAnimation.value,
                            )!,
                          ],
                  ),
                ),
              );
            },
          ),

          // Particle effect
          if (!_hasActiveAdvance)
            CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                animation: _particleController,
              ),
            ),

          // Content
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hasActiveAdvance) ...[
                            const Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 64,
                            ).animate().scale(
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: 24),
                            Text(
                              'Active Advance Detected',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 24,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().fadeIn(
                                  duration: 400.ms,
                                  delay: 200.ms,
                                ),
                            const SizedBox(height: 16),
                            if (_activeAdvance != null) ...[
                              Text(
                                'Amount: ${currencyFormatter.format(double.tryParse(_activeAdvance!['amount']?.toString() ?? '0') ?? 0.0)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Due: ${DateFormat('MMM d, yyyy').format(DateTime.tryParse(_activeAdvance!['repayment_date']?.toString() ?? '') ?? DateTime.now())}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Total to Repay: ${currencyFormatter.format(double.tryParse(_activeAdvance!['total_repayment_amount']?.toString() ?? '0') ?? 0.0)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              if (_activeAdvance!['fee_discount_applied'] ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.discount_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_activeAdvance!['discount_percentage']?.toString() ?? '0'}% Discount Applied',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              Text(
                                'Please repay your current advance\nbefore requesting a new one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontFamily: 'Onest',
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ] else ...[
                            // Logo
                            Hero(
                              tag: 'blink-advance-logo',
                              child: Image.asset(
                                'assets/images/blink_logo_white.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Loading indicator
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ).animate().scale(
                                  duration: 600.ms,
                                  delay: 400.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 24),
                            // Loading text
                            Text(
                              'Preparing your advance...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(
                                  duration: 400.ms,
                                  delay: 600.ms,
                                  curve: Curves.easeOut,
                                ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
