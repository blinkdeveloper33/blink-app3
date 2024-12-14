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

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D47A1),
          Color(0xFF1565C0),
          Color(0xFF1976D2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final circlePaint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2), 100, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.8), 150, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
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
            builder: (context) => NewUserDataScreen(email: widget.email),
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
          title: Text(
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF2196F3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Onest',
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
        icon: Icon(Icons.smart_button, color: Color(0xFF2196F3)),
        label: const Text(
          'Autofill Code',
          style: TextStyle(
            color: Color(0xFF2196F3),
            fontSize: 16,
            fontFamily: 'Onest',
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Time Remaining ${_timeLeft.toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontFamily: 'Onest',
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            (_completeCode.length == 6 && !_isVerifying) ? _verifyOtp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: _isVerifying
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Verify Now',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Onest',
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
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontFamily: 'Onest',
          ),
        ),
        TextButton(
          onPressed: (_timeLeft == 0 && !_isResending) ? _resendOtp : null,
          child: _isResending
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Resend Code',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
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
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: BackgroundPainter(),
            child: Container(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
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
                        Image.asset(
                          'assets/images/blink_logo.png',
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: FadeInDown(
                        duration: Duration(milliseconds: 800),
                        child: Lottie.asset(
                          'assets/animations/enterotp.json',
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInLeft(
                      duration: Duration(milliseconds: 800),
                      child: const Text(
                        'Enter Verification Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInLeft(
                      duration: Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 200),
                      child: Text(
                        'We\'ve sent a verification code to ${widget.email}. Please enter it below to verify your account.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Onest',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildOtpFields(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 600),
                      child: Column(
                        children: [
                          _buildAutofillButton(),
                          const SizedBox(height: 8),
                          _buildTimerDisplay(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 800),
                      child: _buildVerifyNowButton(),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 1000),
                      child: _buildResendCodeOption(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
