import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:blink_app/features/auth/presentation/select_verification_method_screen.dart';
import 'package:blink_app/features/auth/presentation/login_screen.dart';
import 'package:blink_app/features/auth/presentation/new_user_data_screen.dart';
import 'package:blink_app/services/google_auth_service.dart';
import 'package:logger/logger.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/utils/temp_localizations.dart';

class SignUpScreen extends StatefulWidget {
  final bool showAppBar;
  const SignUpScreen({super.key, this.showAppBar = true});

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
  bool _showError = false;
  String? _errorMessage;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
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

  void _submitSignUp() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _showError = false;
        _errorMessage = null;
      });

      final email = _emailController.text.trim();
      _logger.d('Storing email and navigating to verification screen: $email');

      try {
        // Store email
        final storageService =
            Provider.of<StorageService>(context, listen: false);
        await storageService.setEmail(email);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  SelectVerificationMethodScreen(email: email),
            ),
          );
        }
      } catch (e) {
        _logger.e('Error during email storage:', error: e);
        setState(() {
          _showError = true;
          _errorMessage = 'An error occurred. Please try again.';
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

  void _handleGoogleSignUp() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _showError = false;
      _errorMessage = null;
    });

    try {
      _logger.d('Starting Google Sign Up process');

      // Get the GoogleAuthService
      final googleAuthService = GoogleAuthService(
        storageService: Provider.of<StorageService>(context, listen: false),
        authService: Provider.of<AuthService>(context, listen: false),
      );

      // Start the Google Sign-In flow
      final response = await googleAuthService.signInWithGoogle(context);

      if (!mounted) return;

      // Handle response based on isNewUser flag
      if (response['isNewUser'] == true) {
        // New user - navigate to profile completion
        _logger.i('New Google user, redirecting to profile completion');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NewUserDataScreen(
              email: response['email'] ?? '',
              firstName: response['firstName'] ?? '',
              lastName: response['lastName'] ?? '',
              isGoogleSignIn: true,
            ),
          ),
        );
      } else {
        // Existing user - navigate to link plaid bank screen
        _logger
            .i('Existing Google user, redirecting to link plaid bank screen');
        Navigator.of(context).pushReplacementNamed('/link_plaid');
      }
    } catch (e) {
      _logger.e('Google Sign Up error:', error: e);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showError = true;
          _errorMessage = e.toString().contains('canceled')
              ? 'Sign in was canceled'
              : 'Failed to sign in with Google. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleAppleSignUp() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    _logger.d('Apple Sign Up Pressed');
  }

  Widget _buildSocialButton({
    required String text,
    required String iconPath,
    required VoidCallback onPressed,
    required bool isHovered,
    required Function(bool) onHover,
  }) {
    // If Google button is in loading state during authentication, show the loading indicator
    final bool isLoading = text == 'Google' && _isSubmitting;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: isHovered ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (0.02 * value),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(isHovered ? 0.3 : 0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isLoading ? null : onPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.9),
                              ),
                            ),
                          )
                        else
                          Image.asset(
                            iconPath,
                            height: 20,
                            width: 20,
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isLoading ? "Signing in..." : text,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Onest',
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _emailFocusNode.hasFocus
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            cursorColor: Colors.white,
            style: const TextStyle(
              fontFamily: 'Onest',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: _emailFocusNode.hasFocus
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              errorStyle: const TextStyle(height: 0), // Hide default error
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitSignUp(),
            onEditingComplete: _submitSignUp,
            validator: (value) {
              if (value == null || value.isEmpty) {
                _showError = true;
                _errorMessage = 'Please enter your email address';
                return ''; // Return empty string to trigger error without showing default message
              }
              final emailRegex = RegExp(
                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
              if (!emailRegex.hasMatch(value)) {
                _showError = true;
                _errorMessage = 'Please enter a valid email address';
                return '';
              }
              _showError = false;
              _errorMessage = null;
              return null;
            },
          ),
        ),
        if (_showError && _errorMessage != null) _buildErrorMessage(),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
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
                decoration: TextDecoration.none,
                decorationColor: Colors.black.withOpacity(0.87),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
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
        onPressed: _submitSignUp,
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
                'Continue',
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    Widget mainContent = GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: AnimatedContainer(
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
                  // Welcome text section with increased spacing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        FadeInLeft(
                          duration: const Duration(milliseconds: 600),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.welcomeToBlink,
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
                                AnimatedEmojis.wave,
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
                            AppLocalizations.of(context)!.signUpToContinue,
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
                  const SizedBox(height: 40), // Increased spacing
                  // Email form with refined padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 24), // Increased button spacing
                        _buildContinueButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40), // Increased divider spacing
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
                  // Social Buttons
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: StatefulBuilder(
                        builder: (context, setState) => Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                text: 'Google',
                                iconPath: 'assets/images/google_icon.png',
                                onPressed: _handleGoogleSignUp,
                                isHovered: _isGoogleHovered,
                                onHover: (value) =>
                                    setState(() => _isGoogleHovered = value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSocialButton(
                                text: 'Apple',
                                iconPath: 'assets/images/apple_icon.png',
                                onPressed: _handleAppleSignUp,
                                isHovered: _isAppleHovered,
                                onHover: (value) =>
                                    setState(() => _isAppleHovered = value),
                              ),
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
