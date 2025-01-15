import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blink_app/features/auth/presentation/new_user_data_screen.dart';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class AnimatedBubble extends StatefulWidget {
  final double size;
  final double initialX;
  final double initialY;
  final Duration duration;

  const AnimatedBubble({
    Key? key,
    required this.size,
    required this.initialX,
    required this.initialY,
    required this.duration,
  }) : super(key: key);

  @override
  State<AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.initialX + _positionAnimation.value,
          top: widget.initialY + _positionAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(_opacityAnimation.value * 0.1),
            ),
          ),
        );
      },
    );
  }
}

class EnterOtpScreen extends StatefulWidget {
  final String email;

  const EnterOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<EnterOtpScreen> createState() => _EnterOtpScreenState();
}

class _EnterOtpScreenState extends State<EnterOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  Timer? _timer;
  int _timeLeft = 30;
  bool _isVerifying = false;
  bool _isResending = false;
  final Logger _logger = Logger();

  List<AnimatedBubble> _generateBubbles() {
    final random = math.Random();
    return List.generate(8, (index) {
      final size = 150.0 + random.nextDouble() * 200;
      final x = -100.0 +
          random.nextDouble() * (MediaQuery.of(context).size.width + 200);
      final y = -100.0 +
          random.nextDouble() * (MediaQuery.of(context).size.height + 200);
      return AnimatedBubble(
        size: size,
        initialX: x,
        initialY: y,
        duration: Duration(milliseconds: 4000 + random.nextInt(3000)),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = 30);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String get _completeCode {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    final otp = _completeCode.trim();
    if (otp.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP.', isError: true);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response = await authService.verifyOtp(widget.email, otp);
      if (response['success']) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NewUserDataScreen(
              email: widget.email,
            ),
          ),
        );
      } else {
        final message =
            response['message'] ?? 'OTP verification failed. Please try again.';
        _showErrorDialog(message);
      }
    } on InvalidOtpException catch (e) {
      _logger.e('Invalid OTP', error: e);
      _showErrorDialog(e.message);
    } catch (e, stackTrace) {
      _logger.e('Error during OTP verification',
          error: e, stackTrace: stackTrace);
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response = await authService.sendOtp(widget.email);
      if (response['success']) {
        startTimer();
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        _showSnackBar('A new verification code has been sent to your email.');
      } else {
        final message =
            response['message'] ?? 'Failed to resend OTP. Please try again.';
        _showErrorDialog(message);
      }
    } catch (e, stackTrace) {
      _logger.e('Error during resending OTP', error: e, stackTrace: stackTrace);
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061535),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.redAccent,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Onest',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Onest',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _autofillCode() {
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = '1';
    }
    setState(() {});
    _focusNodes[5].requestFocus();
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) => _onCodeChanged(value, index),
          ),
        ),
      ),
    );
  }

  Widget _buildAutofillButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _autofillCode,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Icon(
          Icons.smart_button,
          color: Colors.white.withOpacity(0.9),
        ),
        label: Text(
          'Autofill Code',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          'Time Remaining ${_timeLeft.toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyNowButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            (_completeCode.length == 6 && !_isVerifying) ? _verifyOtp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isVerifying
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              )
            : const Text(
                'Verify Now',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResendCodeOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t Receive Anything? ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w400,
          ),
        ),
        TextButton(
          onPressed: (_timeLeft == 0 && !_isResending) ? _resendOtp : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: _isResending
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                )
              : Text(
                  'Resend Code',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbles = _generateBubbles();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF2563EB),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Bubbles
            ...bubbles,
            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            ),
                            tooltip: 'Go Back',
                          ),
                          Hero(
                            tag: 'logo',
                            child: Image.asset(
                              'assets/images/blink_logo_white.png',
                              height: 42,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Center(
                          child: Lottie.asset(
                            'assets/animations/enterotp.json',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 600),
                        child: const Text(
                          'Enter Verification Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'We\'ve sent a verification code to ${widget.email}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontFamily: 'Onest',
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: _buildOtpFields(),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            _buildAutofillButton(),
                            const SizedBox(height: 16),
                            _buildTimerDisplay(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: _buildVerifyNowButton(),
                      ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: _buildResendCodeOption(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
