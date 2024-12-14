import 'package:flutter/material.dart';
import 'package:blink_app/features/auth/presentation/enter_otp_screen.dart';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

class SelectVerificationMethodScreen extends StatefulWidget {
  final String email;

  const SelectVerificationMethodScreen({
    super.key,
    required this.email,
  });

  @override
  State<SelectVerificationMethodScreen> createState() =>
      _SelectVerificationMethodScreenState();
}

class _SelectVerificationMethodScreenState
    extends State<SelectVerificationMethodScreen> {
  bool _isSending = false;
  final Logger _logger = Logger();

  Future<void> _initiateVerification() async {
    setState(() {
      _isSending = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response = await authService.registerInitial(widget.email);

      if (response['success'] == true) {
        final storageService =
            Provider.of<StorageService>(context, listen: false);
        await storageService.setEmail(widget.email);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EnterOtpScreen(email: widget.email),
          ),
        );
      } else {
        final message = response['error'] ??
            'Failed to initiate verification. Please try again.';
        _showErrorDialog(message);
      }
    } on UserAlreadyExistsException catch (e) {
      _logger.e('User already exists', error: e);
      _showErrorDialog(e.message);
    } catch (e, stackTrace) {
      _logger.e('Error initiating verification',
          error: e, stackTrace: stackTrace);
      String errorMessage = 'An unexpected error occurred. Please try again.';
      if (e is Exception) {
        errorMessage = e.toString();
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
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

  Widget _buildVerificationOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verify Your Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your preferred verification method',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Onest',
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildOptionTile(
            icon: Icons.email_outlined,
            title: 'Email Verification',
            subtitle: 'Send code to ${widget.email}',
            onTap: _isSending ? null : _initiateVerification,
            isEnabled: true,
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildOptionTile(
            icon: Icons.phone_android_outlined,
            title: 'Phone Verification',
            subtitle: 'Coming soon',
            onTap: null,
            isEnabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white54,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isEnabled ? Colors.white : Colors.white54,
          fontSize: 18,
          fontFamily: 'Onest',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isEnabled ? Colors.white70 : Colors.white38,
          fontFamily: 'Onest',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: isEnabled
            ? Colors.white.withOpacity(0.7)
            : Colors.white.withOpacity(0.3),
        size: 18,
      ),
      onTap: onTap,
      enabled: isEnabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSending ? null : _initiateVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: _isSending ? 0 : 4,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSending
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
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
                        SvgPicture.asset(
                          'assets/images/blink_logo1.svg',
                          height: 30,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Center(
                        child: Lottie.asset(
                          'assets/animations/verification.json',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: _buildVerificationOptions(),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: _buildContinueButton(),
                    ),
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
