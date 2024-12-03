// lib/features/auth/presentation/sign_up_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/features/auth/presentation/select_verification_method_screen.dart';
import 'package:logger/logger.dart';
import 'package:animate_do/animate_do.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  final Logger _logger = Logger();

  // Add hover states for social buttons
  bool _isGoogleHovered = false;
  bool _isAppleHovered = false;

  void _submitEmail() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final email = _emailController.text.trim();
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SelectVerificationMethodScreen(email: email),
          ),
        );
      });
    }
  }

  void _handleGoogleSignIn() {
    // TODO: Implement Google Sign In
    _logger.d('Google Sign In Pressed');
  }

  void _handleAppleSignIn() {
    // TODO: Implement Apple Sign In
    _logger.d('Apple Sign In Pressed');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildSocialButton({
    required String text,
    required String iconPath,
    required VoidCallback onPressed,
    required bool isHovered,
    required Function(bool) onHover,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isHovered ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Image.asset(
                    iconPath,
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.w600,
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

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email address';
            }
            final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: _isSubmitting ? 0 : 4,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Continue with Email',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white24,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Onest',
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white24,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061535),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Image.asset(
                      'assets/images/blink_logo.png',
                      height: 60, // Reduced from 120 to 80
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeInLeft(
                  duration: const Duration(milliseconds: 800),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    'Create an account to get started',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontFamily: 'Onest',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: StatefulBuilder(
                    builder: (context, setState) => Column(
                      children: [
                        _buildSocialButton(
                          text: 'Continue with Google',
                          iconPath: 'assets/images/google_icon.png',
                          onPressed: _handleGoogleSignIn,
                          isHovered: _isGoogleHovered,
                          onHover: (value) => setState(() => _isGoogleHovered = value),
                        ),
                        const SizedBox(height: 16),
                        _buildSocialButton(
                          text: 'Continue with Apple',
                          iconPath: 'assets/images/apple_icon.png', // You'll need to add this asset
                          onPressed: _handleAppleSignIn,
                          isHovered: _isAppleHovered,
                          onHover: (value) => setState(() => _isAppleHovered = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: _buildDivider(),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 24),
                        _buildContinueButton(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 600),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement sign in navigation
                      },
                      child: const Text(
                        'Already have an account? Log In',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w600,
                        ),
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

