import 'package:flutter/material.dart';
import 'package:myapp/features/auth/presentation/enter_otp_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class SelectVerificationMethodScreen extends StatefulWidget {
  final String email;

  const SelectVerificationMethodScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

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
                  'Select Verification Method',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how you\'d like to receive your verification code',
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
            icon: Icons.email,
            title: 'Email Verification',
            subtitle: 'Send code to ${widget.email}',
            onTap: _isSending ? null : _initiateVerification,
            isEnabled: true,
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildOptionTile(
            icon: Icons.phone,
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
      leading: Icon(icon,
          color: isEnabled ? Colors.white : Colors.white54, size: 28),
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
        child: _isSending
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Send Email Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061535),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
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
                        child:
                            const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Go Back',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Image.asset(
                        'assets/images/blink_logo.png',
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/images/verification.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                _buildVerificationOptions(),
                const SizedBox(height: 32),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
