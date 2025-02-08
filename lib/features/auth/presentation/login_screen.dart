import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/biometric_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  final Logger _logger = Logger();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _errorMessage;

  bool _isGoogleHovered = false;
  bool _isAppleHovered = false;
  bool _obscurePassword = true;

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
    _passwordFocusNode.addListener(() {
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
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pulseAnimationController.dispose();
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

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
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
                    color: focusNode.hasFocus
                        ? Colors.white.withOpacity(0.15)
                        : Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: focusNode.hasFocus
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                      width: focusNode.hasFocus ? 1.5 : 1,
                    ),
                    boxShadow: focusNode.hasFocus
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
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: isPassword ? _obscurePassword : false,
                    style: TextStyle(
                      fontFamily: 'Onest',
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: isPassword ? 1 : 0,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(20),
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle: TextStyle(
                        fontFamily: 'Onest',
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        icon,
                        color: focusNode.hasFocus
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.5),
                      ),
                      suffixIcon: isPassword
                          ? IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: focusNode.hasFocus
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.white.withOpacity(0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            )
                          : null,
                      filled: false,
                      errorStyle: const TextStyle(height: 0),
                    ),
                    keyboardType: isPassword
                        ? TextInputType.visiblePassword
                        : TextInputType.emailAddress,
                    textInputAction: isPassword
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onFieldSubmitted: (_) {
                      if (isPassword) {
                        _handleLogin();
                      } else {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      }
                    },
                    onEditingComplete: isPassword ? _handleLogin : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      if (!isPassword) {
                        final emailRegex = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            String? errorText;
            if (value.text.isEmpty) {
              errorText = 'This field is required';
            } else if (!isPassword) {
              final emailRegex = RegExp(
                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
              if (!emailRegex.hasMatch(value.text)) {
                errorText = 'Please enter a valid email address';
              }
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
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
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
          onTap: _isSubmitting ? null : _handleLogin,
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
                      'Log In',
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final biometricService =
            Provider.of<BiometricService>(context, listen: false);

        final response = await authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response['success'] == true) {
          // Check if biometrics are available
          final bool canUseBiometrics =
              await biometricService.isBiometricsAvailable();

          if (canUseBiometrics && mounted) {
            try {
              // Show dialog to enable biometric authentication
              final bool? enableBiometrics = await showDialog<bool>(
                context: context,
                barrierDismissible: true, // Allow dismissing by tapping outside
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (BuildContext context) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.face_outlined,
                            color: Colors.blue[700],
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Enable Face ID',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Would you like to enable Face ID for quick and secure access to your account?',
                        style: TextStyle(
                          fontFamily: 'Onest',
                          fontSize: 16,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Not Now',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Enable',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (enableBiometrics == true && mounted) {
                try {
                  // Try to authenticate with biometrics
                  final bool authenticated =
                      await biometricService.authenticate();
                  if (authenticated && mounted) {
                    await biometricService.setBiometricEnabled(true);
                    await biometricService.updateLastActiveTime();

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text(
                              'Face ID enabled successfully',
                              style: TextStyle(fontFamily: 'Onest'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                } catch (e) {
                  _logger.e('Error during Face ID authentication: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Failed to enable Face ID. Please try again later.',
                                style: TextStyle(fontFamily: 'Onest'),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              _logger.e('Error showing Face ID dialog: $e');
            }
          }

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          setState(() {
            _errorMessage =
                response['error'] ?? 'An error occurred during login';
          });
        }
      } catch (e) {
        _logger.e('Login error:', error: e);
        setState(() {
          _errorMessage = 'An error occurred during login';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _handleGoogleSignIn() {
    _logger.d('Google Sign In Pressed');
  }

  void _handleAppleSignIn() {
    _logger.d('Apple Sign In Pressed');
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
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Error Message
                      if (_errorMessage != null)
                        FadeInDown(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D1B1B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF5252),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFFF5252),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontFamily: 'Onest',
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFFFF5252),
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _errorMessage = null),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FadeInLeft(
                          duration: const Duration(milliseconds: 600),
                          child: const Text(
                            'Welcome Back',
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
                            'Log in to your account',
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
                                  onPressed: _handleGoogleSignIn,
                                  isHovered: _isGoogleHovered,
                                  onHover: (value) =>
                                      setState(() => _isGoogleHovered = value),
                                ),
                                const SizedBox(height: 12),
                                _buildSocialButton(
                                  text: 'Continue with Apple',
                                  iconPath: 'assets/images/apple_icon.png',
                                  onPressed: _handleAppleSignIn,
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
                      // Login Form
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: Column(
                            children: [
                              _buildInputField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                hintText: 'Enter your email',
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                hintText: 'Enter your password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 20),
                              _buildLoginButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Forgot Password
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              // Handle forgot password
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontFamily: 'Onest',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Sign Up Link
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
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
                                    'Don\'t have an account?',
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
                                    'Sign Up',
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
