import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:blink_app/features/auth/presentation/select_verification_method_screen.dart';
import 'package:blink_app/features/auth/presentation/login_screen.dart';
import 'package:logger/logger.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';

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
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.4,
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  final Logger _logger = Logger();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isGoogleHovered = false;
  bool _isAppleHovered = false;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late final List<AnimatedBubble> _bubbles;

  List<AnimatedBubble> _generateBubbles() {
    final random = math.Random();
    const containerWidth = 600.0;
    const containerHeight = 800.0;

    return List.generate(8, (index) {
      final size = 150.0 + random.nextDouble() * 200;
      final x = -100.0 + random.nextDouble() * (containerWidth + 200);
      final y = -100.0 + random.nextDouble() * (containerHeight + 200);
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
    _bubbles = _generateBubbles();

    _emailFocusNode.addListener(() {
      setState(() {});
    });

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _submitSignUp() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final email = _emailController.text.trim();

      _logger.d('Signing up with email: $email');

      // Navigate to verification screen immediately
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SelectVerificationMethodScreen(email: email),
        ),
      );
    }
  }

  void _handleGoogleSignUp() {
    _logger.d('Google Sign Up Pressed');
  }

  void _handleAppleSignUp() {
    _logger.d('Apple Sign Up Pressed');
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: isHovered ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (0.02 * value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1 + (0.05 * value)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2 + (0.1 * value)),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 * value),
                    blurRadius: 10 * value,
                    offset: Offset(0, 4 * value),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset(
                          iconPath,
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          text,
                          style: TextStyle(
                            fontFamily: 'Onest',
                            color:
                                Colors.white.withOpacity(0.9 + (0.1 * value)),
                            fontSize: 16,
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
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _emailFocusNode.hasFocus
                        ? Colors.white.withOpacity(0.15)
                        : Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: _emailFocusNode.hasFocus
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                      width: _emailFocusNode.hasFocus ? 1.5 : 1,
                    ),
                    boxShadow: _emailFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ]
                        : [],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    style: TextStyle(
                      fontFamily: 'Onest',
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(20),
                      border: InputBorder.none,
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                        fontFamily: 'Onest',
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: _emailFocusNode.hasFocus
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.5),
                      ),
                      filled: false,
                      errorStyle: const TextStyle(height: 0),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitSignUp(),
                    onEditingComplete: _submitSignUp,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      final emailRegex = RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            );
          },
        ),
        Builder(
          builder: (context) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: _emailController,
              builder: (context, value, child) {
                String? errorText;
                if (value.text.isEmpty) {
                  errorText = 'Please enter your email address';
                } else if (!RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    .hasMatch(value.text)) {
                  errorText = 'Please enter a valid email address';
                }

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: errorText != null ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16),
                    child: Text(
                      errorText ?? '',
                      style: TextStyle(
                        fontFamily: 'Onest',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSubmitting ? null : _submitSignUp,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _isSubmitting
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
                      'Continue',
                      style: TextStyle(
                        fontFamily: 'Onest',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
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
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: _bubbles,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              0,
              bottomPadding > 0 ? -screenHeight * 0.15 : 0,
              0,
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: bottomPadding > 0 ? bottomPadding + 24 : 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      // Logo
                      Center(
                        child: Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/images/blink_logo_white.png',
                            height: 49,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FadeInLeft(
                          duration: const Duration(milliseconds: 600),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FadeInLeft(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            'Sign up to get started with Blink',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              height: 1.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Social Buttons
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: StatefulBuilder(
                            builder: (context, setState) => Column(
                              children: [
                                _buildSocialButton(
                                  text: 'Continue with Google',
                                  iconPath: 'assets/images/google_icon.png',
                                  onPressed: _handleGoogleSignUp,
                                  isHovered: _isGoogleHovered,
                                  onHover: (value) =>
                                      setState(() => _isGoogleHovered = value),
                                ),
                                const SizedBox(height: 12),
                                _buildSocialButton(
                                  text: 'Continue with Apple',
                                  iconPath: 'assets/images/apple_icon.png',
                                  onPressed: _handleAppleSignUp,
                                  isHovered: _isAppleHovered,
                                  onHover: (value) =>
                                      setState(() => _isAppleHovered = value),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    fontFamily: 'Onest',
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Email Form
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: Column(
                            children: [
                              _buildEmailField(),
                              const SizedBox(height: 20),
                              _buildContinueButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Login Link
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Already have an account?',
                                    style: TextStyle(
                                      fontFamily: 'Onest',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontFamily: 'Onest',
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}
