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
    glowRadius =
        (radius * 2 + sin(animation * pi * 2) * radius).clamp(0.0, 10.0);
    glowIntensity = (0.2 + sin(animation * pi * 2) * 0.1).clamp(0.1, 0.3);

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

      // Skip drawing particles that are too close to the top-left corner
      if (particle.x < 0.1 && particle.y < 0.1) continue;

      // Draw particle glow with multiple layers for smooth transition
      final glowPaint = Paint()
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          particle.glowRadius,
        );

      // Outer glow - reduce opacity
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.08);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius * 3,
        glowPaint,
      );

      // Middle glow - reduce opacity
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.15);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius * 2,
        glowPaint,
      );

      // Inner glow - reduce opacity
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.2);
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
          final opacity = (1 - distance / 100) * 0.12 * particle.opacity;
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
  bool _isApproved = false;
  String _approvalStatusMessage = '';
  String? _userFirstName;
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkApprovalStatus();
  }

  void _initializeAnimations() {
    // Initialize logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
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

    // Make the logo pulsate continuously until the screen disappears
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // When the animation completes, create a gentle pulsating effect
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_logoController.isAnimating && mounted) {
            _logoController.forward(
                from: 0.8); // Restart from 80% to create a subtle pulse
          }
        });
      }
    });

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

  Future<void> _checkApprovalStatus() async {
    try {
      // Start loading animation
      setState(() {
        _isLoading = true;
      });

      // Create a minimum loading duration for better UX
      final minimumLoadingDuration =
          Future.delayed(const Duration(milliseconds: 2000));

      // Get user profile in parallel with the approval status check
      final userProfileFuture = _fetchUserProfile();

      // Get auth token and make API call
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/cash-advance/approval-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Wait for minimum loading time to complete and user profile
      await Future.wait([minimumLoadingDuration, userProfileFuture]);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Debug the response to see what's happening
        print("Cash advance approval status response: $responseBody");

        // Parse the JSON response
        final data = jsonDecode(responseBody);

        // Check different possible response structures
        String? status;
        String statusMessage = '';

        // Check if the response has direct approvalStatus field
        if (data['approvalStatus'] != null) {
          status = data['approvalStatus']?.toString().toLowerCase();
          statusMessage = data['message'] ?? '';
          print("Status from direct API response: '$status'");
        }
        // Check if response has nested data structure
        else if (data['data'] != null && data['success'] == true) {
          status = data['data']['status']?.toString().toLowerCase() ?? '';
          statusMessage = data['data']['message'] ?? '';
          print("Status from nested API response: '$status'");
        }

        // Make case-insensitive check to handle any capitalization issues
        if (status != null &&
            (status == 'approved' || status.contains('approved'))) {
          // User is approved - check if they have an active advance
          setState(() {
            _isApproved = true;
            _approvalStatusMessage = statusMessage;
          });

          await _checkActiveAdvance();
        } else {
          // User is not approved or status couldn't be determined
          print("User not approved. Status: $status");

          // Fade out current content
          _logoController.reverse();

          await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted) return;

          // Update state to show denied status
          setState(() {
            _isApproved = false;
            _approvalStatusMessage = statusMessage.isNotEmpty
                ? statusMessage
                : 'You are not currently eligible for a cash advance.';
            _isLoading = false;
          });

          // Animate warning content in
          _logoController.forward(from: 0.0);

          // Show message for 5 seconds then return to home
          await Future.delayed(const Duration(seconds: 5));

          if (!mounted) return;

          // Fade out warning
          await _logoController.reverse();

          if (!mounted) return;

          // Return to home with denial data and quick action status
          Navigator.of(context).pop({
            'approval_status': 'denied',
            'message': _approvalStatusMessage,
            'quick_action_status':
                'not_eligible', // Status for the quick action card
            'has_active_advance': false // No active advance in this case
          });
        }
      } else {
        throw Exception(
            'Failed to check approval status: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      print("Error checking approval status: $e");

      // Show error and return to home screen
      setState(() {
        _isLoading = false;
        _isApproved = false;
        _approvalStatusMessage =
            'Unable to verify eligibility at this time. Please try again later.';
      });

      // Fade out current content if needed
      if (_logoController.status != AnimationStatus.dismissed) {
        await _logoController.reverse();
      }

      if (!mounted) return;

      // Show error message briefly
      _logoController.forward(from: 0.0);

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // Return to home with error data and quick action status
      Navigator.of(context).pop({
        'error': e.toString(),
        'quick_action_status':
            'error', // Error status for the quick action card
        'has_active_advance': false, // No advance in error case
        'message': _approvalStatusMessage
      });
    }
  }

  Future<void> _checkActiveAdvance() async {
    try {
      // Get auth token and make API call
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/cash-advance/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug the response
        print("Active cash advance response: ${response.body}");

        // Check if user has active cash advance
        if (data['hasActiveCashAdvance'] == true &&
            data['cashAdvance'] != null) {
          // Fade out current content
          _logoController.reverse();

          await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted) return;

          // Map the cash advance data to match the expected structure
          final cashAdvance = data['cashAdvance'];

          // Debug cash advance object
          print("Cash advance details: $cashAdvance");

          // Safely extract values with null checking
          String principalAmount =
              _safeGetString(cashAdvance, 'principal_amount') ??
                  _safeGetString(cashAdvance, 'principalAmount') ??
                  '0.00';

          String finalFee = _safeGetString(cashAdvance, 'final_fee') ??
              _safeGetString(cashAdvance, 'finalFee') ??
              '0.00';

          bool hasDiscount = false;
          int discountPercentage = 0;

          if (cashAdvance['metadata'] != null) {
            final metadata = cashAdvance['metadata'];
            hasDiscount = metadata['discount_applied'] == true ||
                metadata['fee_discount_applied'] != null;

            if (metadata['fee_discount_applied'] != null) {
              // Handle different types (int, double, string)
              var discount = metadata['fee_discount_applied'];
              if (discount is int) {
                discountPercentage = discount;
              } else if (discount is double) {
                discountPercentage = discount.toInt();
              } else if (discount is String) {
                discountPercentage = int.tryParse(discount) ?? 0;
              }
            }
          }

          // Extract the status with default fallback
          String status = _safeGetString(cashAdvance, 'status') ?? 'active';

          final mappedAdvance = {
            'id': cashAdvance['id'] ?? '',
            'amount': principalAmount,
            'repayment_date': cashAdvance['repayment_due_date'] ??
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'total_repayment_amount':
                _calculateTotalRepayment(principalAmount, finalFee),
            'fee_discount_applied': hasDiscount,
            'discount_percentage': discountPercentage,
            'status': status,
          };

          // Update state and show warning
          setState(() {
            _activeAdvance = mappedAdvance;
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

          // Return to home with data including a specific 'quick_action_status' for the home screen
          final resultData = {
            ..._activeAdvance!,
            'quick_action_status':
                'requested', // This will make the quick action show "Requested" status
            'has_active_advance':
                true // Clear flag to indicate there's an active advance
          };
          print("🔴 Returning to home screen with active advance data: $resultData");
          Navigator.of(context).pop(resultData);
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
      print("Error checking active cash advance: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _proceedToAdvanceScreen();
    }
  }

  // Helper method to safely get string value from map
  String? _safeGetString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;

    if (value is String) return value;
    return value.toString();
  }

  // Helper method to calculate total repayment amount
  String _calculateTotalRepayment(String principalStr, String feeStr) {
    try {
      final principal = double.tryParse(principalStr.toString()) ?? 0.0;
      final fee = double.tryParse(feeStr.toString()) ?? 0.0;
      return (principal + fee).toString();
    } catch (e) {
      print("Error calculating total repayment: $e");
      return "0.0";
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      debugPrint('Calling user profile API to get first name');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _userFirstName = data['data']['firstName'];
          });
          debugPrint(
              '🎉 Successfully retrieved user name from API: $_userFirstName');
        } else {
          debugPrint('❌ User profile API returned success: false or no data');
        }
      } else {
        debugPrint(
            '❌ Failed to get user profile: HTTP ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
    }
  }

  void _proceedToAdvanceScreen() {
    _scheduleTransition();
  }

  Future<void> _scheduleTransition() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      final result = await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return BlinkAdvanceScreen(
              bankAccountId: widget.bankAccountId,
              userName: _userFirstName,
              // Note: We could extend this to pass more data if needed in the future
            );
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

      // If the advance screen returns a result (e.g., user backs out without taking an advance)
      if (mounted && result != null) {
        Navigator.of(context).pop({
          'quick_action_status':
              'approved', // Default to approved if they're just returning
          'has_active_advance': false,
          ...(result is Map
              ? result
              : {}) // Include any data returned from advance screen
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop({
          'error': e.toString(),
          'quick_action_status': 'error',
          'has_active_advance': false
        });
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
    // Set status bar to light mode (white text and icons)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // For Android
      statusBarBrightness: Brightness.dark, // For iOS (dark = white content)
    ));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background with color based on active advance or approval status
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
                        : !_isApproved && !_isLoading
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
          if (!_hasActiveAdvance && _isApproved)
            CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                animation: _particleController,
              ),
            ),

          // Content
          Center(
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                              _activeAdvance!['status']?.toString()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(_activeAdvance!['status']?.toString()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_activeAdvance!['fee_discount_applied'] == true) ...[
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Please repay your current advance\nbefore requesting a new one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontFamily: 'Onest',
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Returning to home screen...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Onest',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ] else if (!_isApproved && !_isLoading) ...[
                    // Not approved UI
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 64,
                    ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 24),
                    Text(
                      'Not Eligible',
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
                    Text(
                      _approvalStatusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'Onest',
                        height: 1.4,
                      ),
                    ).animate().fadeIn(
                          duration: 400.ms,
                          delay: 300.ms,
                        ),
                  ] else ...[
                    // Loading or approved UI - Only apply animations to the logo
                    Hero(
                      tag: 'blink-advance-logo',
                      child: AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Opacity(
                              opacity: _logoOpacityAnimation.value,
                              child: Image.asset(
                                'assets/images/blink_logo_white.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Preparing your advance...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'requested':
        return Colors.orange.withOpacity(0.7);
      case 'disbursed':
        return Colors.green.withOpacity(0.7);
      case 'approved':
        return Colors.green.withOpacity(0.7);
      case 'pending':
        return Colors.orange.withOpacity(0.7);
      case 'overdue':
        return Colors.red.withOpacity(0.7);
      default:
        return Colors.blue.withOpacity(0.7);
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'requested':
        return 'Processing Request';
      case 'disbursed':
        return 'Funds Disbursed';
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Active Advance';
    }
  }
}
