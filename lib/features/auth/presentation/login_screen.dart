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
import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:blink_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:blink_app/features/auth/presentation/link_plaid_bank_screen.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool showAppBar;
  const LoginScreen({super.key, this.showAppBar = true});

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
  bool _passwordVisible = false;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late final List<AnimatedBubble> _bubbles;

  bool _showEmailError = false;
  bool _showPasswordError = false;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;

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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focusNode.hasFocus
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword ? !_passwordVisible : false,
            cursorColor: Colors.white,
            style: const TextStyle(
              fontFamily: 'Onest',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                color: focusNode.hasFocus
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0),
            ),
            validator: (value) {
              if (!isPassword) {
                // Email validation
                if (value == null || value.isEmpty) {
                  setState(() {
                    _showEmailError = true;
                    _emailErrorMessage = 'Please enter your email address';
                  });
                  return '';
                }
                final emailRegex = RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                if (!emailRegex.hasMatch(value)) {
                  setState(() {
                    _showEmailError = true;
                    _emailErrorMessage = 'Please enter a valid email address';
                  });
                  return '';
                }
                setState(() {
                  _showEmailError = false;
                  _emailErrorMessage = null;
                });
              } else {
                // Password validation
                if (value == null || value.isEmpty) {
                  setState(() {
                    _showPasswordError = true;
                    _passwordErrorMessage = 'Please enter your password';
                  });
                  return '';
                }
                setState(() {
                  _showPasswordError = false;
                  _passwordErrorMessage = null;
                });
              }
              return null;
            },
          ),
        ),
        if ((isPassword ? _showPasswordError : _showEmailError) &&
            (isPassword ? _passwordErrorMessage : _emailErrorMessage) != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPassword
                            ? _passwordErrorMessage!
                            : _emailErrorMessage!,
                        style: TextStyle(
                          fontFamily: 'Onest',
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoginButton() {
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
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF1E3A8A),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF1E3A8A)),
                ),
              )
            : const Text(
                'Log In',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _showPasswordError = false;
        _passwordErrorMessage = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final biometricService =
            Provider.of<BiometricService>(context, listen: false);
        final storageService =
            Provider.of<StorageService>(context, listen: false);

        _logger.i('Attempting login...');
        final response = await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _logger.i('Login response received: ${response.toString()}');

        // Check if login was successful by verifying token and user data exist
        if (response['token'] != null && response['user'] != null) {
          _logger.i('Login successful, storing user data...');
          final user = response['user'];
          await storageService.setUserId(user['id']);
          await storageService
              .setFullName('${user['firstName']} ${user['lastName']}');
          await storageService.setEmail(user['email']);
          _logger.i('User data stored successfully');

          // Check for linked bank accounts
          _logger.i('Checking for linked bank accounts...');
          final bankAccountResponse =
              await authService.checkLinkedBankAccount();
          _logger.i('Bank account response: ${bankAccountResponse.toString()}');
          final bool hasLinkedAccount =
              bankAccountResponse['hasLinkedAccount'] ?? false;
          _logger.i('Has linked account: $hasLinkedAccount');

          // Handle biometrics setup if needed
          final bool canUseBiometrics =
              await biometricService.isBiometricsAvailable();
          if (canUseBiometrics && mounted) {
            _logger.i('Biometrics available, showing setup dialog...');
            try {
              final bool? enableBiometrics = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
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
                _logger.i('Setting up biometrics...');
                try {
                  final bool authenticated =
                      await biometricService.authenticate();
                  if (authenticated && mounted) {
                    await biometricService.setBiometricEnabled(true);
                    await biometricService.updateLastActiveTime();
                    _logger.i('Biometrics setup completed successfully');
                  }
                } catch (e) {
                  _logger.e('Error during Face ID authentication: $e');
                }
              }
            } catch (e) {
              _logger.e('Error showing Face ID dialog: $e');
            }
          }

          // Navigate to appropriate screen
          if (mounted) {
            _logger.i(
                'Navigating to ${hasLinkedAccount ? 'HomeScreen' : 'LinkPlaidBankScreen'}...');

            // Ensure we're using the root navigator
            final navigator = Navigator.of(context, rootNavigator: true);

            if (hasLinkedAccount) {
              await navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
                (route) => false,
              );
              _logger.i('Navigation to HomeScreen completed');
            } else {
              await navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LinkPlaidBankScreen(),
                ),
                (route) => false,
              );
              _logger.i('Navigation to LinkPlaidBankScreen completed');
            }
          }
        } else {
          _logger.w('Login failed: Invalid response format');
          setState(() {
            _showPasswordError = true;
            _passwordErrorMessage =
                response['message'] ?? 'Invalid email or password';
          });
        }
      } catch (e, stackTrace) {
        _logger.e('Login error:', error: e, stackTrace: stackTrace);
        setState(() {
          _showPasswordError = true;
          _passwordErrorMessage = 'An error occurred. Please try again.';
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

    Widget mainContent = AnimatedContainer(
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
                if (widget.showAppBar) ...[
                  const SizedBox(height: 32),
                  // Logo
                  Center(
                    child: Hero(
                      tag: 'logo',
                      child: Image.asset(
                        'assets/images/blink_logo_white.png',
                        height: 33,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(
                        duration: const Duration(milliseconds: 600),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.welcomeBack,
                              style: const TextStyle(
                                fontFamily: 'Onest',
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const AnimatedEmoji(
                              AnimatedEmojis.partyPopper,
                              size: 32,
                              repeat: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          AppLocalizations.of(context)!.loginToContinue,
                          style: TextStyle(
                            fontFamily: 'Onest',
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            height: 1.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Input fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildInputField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        hintText: AppLocalizations.of(context)!.enterEmail,
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        hintText: AppLocalizations.of(context)!.enterPassword,
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 24),
                      _buildLoginButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Divider with "or continue with"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppLocalizations.of(context)!.orContinueWith,
                            style: TextStyle(
                              fontFamily: 'Onest',
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Then the social buttons
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
                // Finally the forgot password button
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
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
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.showAppBar == false) {
      return mainContent;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness:
            Brightness.dark, // For iOS: dark background = white content
        statusBarIconBrightness: Brightness.light, // For Android: white icons
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
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
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            mainContent,
          ],
        ),
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
