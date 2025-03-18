import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:blink_app/features/auth/presentation/reset_password_create_new_password_screen.dart';

class ResetPasswordVerifyOtpScreen extends StatefulWidget {
  final String email;

  const ResetPasswordVerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordVerifyOtpScreen> createState() =>
      _ResetPasswordVerifyOtpScreenState();
}

class _ResetPasswordVerifyOtpScreenState
    extends State<ResetPasswordVerifyOtpScreen> {
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
  final List<bool> _fieldValidStates = List.generate(6, (index) => true);
  String? _errorMessage;

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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // Handle backspace key press
  void _handleKeyPress(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
    }
  }

  // Handle input in OTP fields
  void _onCodeChanged(String value, int index) {
    if (value.length > 1) {
      // Handle paste into individual field
      if (value.length == 6 && RegExp(r'^\d{6}$').hasMatch(value)) {
        _handlePaste(value);
        return;
      }
      _controllers[index].text = value[0];
    }

    setState(() {
      _fieldValidStates[index] =
          value.isEmpty || RegExp(r'^\d$').hasMatch(value);
      _errorMessage = null;
    });

    if (value.length == 1 && _fieldValidStates[index]) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify when all 6 digits are entered
        if (_completeCode.length == 6) {
          _verifyOtp();
        }
      }
    }
  }

  // Handle paste functionality
  void _handlePaste(String pastedText) {
    for (var i = 0; i < 6 && i < pastedText.length; i++) {
      _controllers[i].text = pastedText[i];
      _fieldValidStates[i] = true;
    }
    _focusNodes[5].requestFocus();
  }

  // Get the complete OTP code from all fields
  String get _completeCode {
    return _controllers.map((controller) => controller.text).join();
  }

  // Verify the OTP code
  Future<void> _verifyOtp() async {
    final otp = _completeCode.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit verification code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response =
          await authService.verifyPasswordResetOtp(widget.email, otp);

      if (!mounted) return;

      if (response['success'] == true || response['message'] != null) {
        // Navigate to create new password screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordCreateNewPasswordScreen(
              email: widget.email,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ??
              'Invalid verification code. Please try again.';
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error during OTP verification',
          error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // Resend the OTP code
  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response = await authService.requestPasswordReset(widget.email);

      if (!mounted) return;

      if (response['success'] == true || response['message'] != null) {
        startTimer();
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'A new verification code has been sent to your email.',
                    style: TextStyle(
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['error'] ?? 'Failed to resend code. Please try again.';
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error resending verification code',
          error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Widget _buildOtpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 45,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _handleKeyPress(event, index),
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withAlpha(25),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _fieldValidStates[index]
                            ? Colors.white.withAlpha(51)
                            : Colors.redAccent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _fieldValidStates[index]
                            ? Colors.white.withAlpha(204)
                            : Colors.redAccent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: TextStyle(
                    color: _fieldValidStates[index]
                        ? Colors.white
                        : Colors.redAccent,
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
                  onTap: () {
                    if (_controllers[index].text.isNotEmpty) {
                      _controllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controllers[index].text.length,
                      );
                    }
                  },
                  autocorrect: false,
                  enableSuggestions: false,
                  enableInteractiveSelection: true,
                  showCursor: true,
                  autofocus: index == 0,
                ),
              ),
            ),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimerAndResend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_timeLeft > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha(51),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.white.withAlpha(230),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_timeLeft}s',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 14,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _timeLeft > 0 ? 16 : 0,
        ),
        TextButton(
          onPressed: (_timeLeft == 0 && !_isResending) ? _resendOtp : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _timeLeft == 0
                    ? Colors.white.withAlpha(77)
                    : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: _isResending
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withAlpha(204),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Colors.white.withAlpha(_timeLeft == 0 ? 230 : 102),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Resend Code',
                      style: TextStyle(
                        color:
                            Colors.white.withAlpha(_timeLeft == 0 ? 230 : 102),
                        fontSize: 14,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            (_completeCode.length == 6 && !_isVerifying) ? _verifyOtp : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF1E3A8A),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isVerifying
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF1E3A8A)),
                ),
              )
            : const Text(
                'Verify Code',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.95),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Go Back',
          ),
          title: const Text(
            'Verify Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Image.asset(
                'assets/images/blink_logo_white.png',
                height: 23,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          FadeInLeft(
                            duration: const Duration(milliseconds: 600),
                            child: const Text(
                              'Verify Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
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
                              'Enter the 6-digit code we sent to ${widget.email}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                fontFamily: 'Onest',
                                height: 1.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enter the verification code we sent to your email. If you don\'t see it, check your spam folder.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontFamily: 'Onest',
                                    height: 1.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildOtpFields(),
                                const SizedBox(height: 24),
                                Center(
                                  child: _buildTimerAndResend(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 400),
                            child: _buildVerifyButton(),
                          ),
                        ],
                      ),
                    ),
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
