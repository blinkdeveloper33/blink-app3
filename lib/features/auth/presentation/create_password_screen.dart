import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blink_app/features/auth/presentation/link_plaid_bank_screen.dart';
import 'package:blink_app/features/auth/presentation/new_user_data_screen.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'dart:ui';

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

class CreatePasswordScreen extends StatefulWidget {
  final String email;
  final bool isGoogleSignIn;

  const CreatePasswordScreen({
    Key? key,
    required this.email,
    this.isGoogleSignIn = false,
  }) : super(key: key);

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acknowledgeTerms = false;

  double _strengthScore = 0.0;
  String _strengthText = 'Enter a password';
  Color _strengthColor = Colors.grey;

  final Logger _logger = Logger();

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late ConfettiController _confettiController;

  // Add new fields to track individual requirements
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumbers = false;
  bool _hasSpecialChars = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _passwordController.addListener(_updatePasswordStrength);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    double score = 0;
    String text = '';
    Color color = Colors.grey;

    // Reset all requirements
    _hasMinLength = false;
    _hasUppercase = false;
    _hasLowercase = false;
    _hasNumbers = false;
    _hasSpecialChars = false;

    if (password.isEmpty) {
      text = 'Enter a password';
      score = 0.0;
      color = Colors.grey;
    } else {
      // Check each requirement
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumbers = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      // Calculate score only if requirement is met
      if (_hasMinLength) score += 0.2;
      if (_hasUppercase) score += 0.2;
      if (_hasLowercase) score += 0.2;
      if (_hasNumbers) score += 0.2;
      if (_hasSpecialChars) score += 0.2;

      // Only allow certain strength levels if ALL requirements are met
      bool allRequirementsMet = _hasMinLength &&
          _hasUppercase &&
          _hasLowercase &&
          _hasNumbers &&
          _hasSpecialChars;

      if (!allRequirementsMet) {
        text = 'Weak';
        color = Colors.red;
        score = 0.2; // Keep progress bar showing some progress
      } else {
        // All requirements met, now we can show proper strength
        if (score < 0.6) {
          text = 'Weak';
          color = Colors.red;
        } else if (score < 0.8) {
          text = 'Medium';
          color = Colors.orange;
        } else if (score < 1.0) {
          text = 'Strong';
          color = Colors.yellow;
        } else {
          text = 'Very Strong';
          color = Colors.green;
        }
      }
    }

    setState(() {
      _strengthScore = score;
      _strengthText = text;
      _strengthColor = color;
    });
  }

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acknowledgeTerms) {
      _showErrorDialog('Please agree to the Terms of Service to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    try {
      _logger.i('Retrieving stored user data.');
      final firstName = storageService.getFirstName();
      final lastName = storageService.getLastName();
      final state = storageService.getState();
      final zipcode = storageService.getZipcode();

      if (firstName == null ||
          lastName == null ||
          state == null ||
          zipcode == null) {
        _logger.e('Incomplete registration data.');
        _showErrorDialog('Incomplete registration data. Please try again.');
        return;
      }

      Map<String, dynamic> response;

      // Check if this is a Google Sign-In completion or regular registration
      if (widget.isGoogleSignIn) {
        final userId = storageService.getUserId();
        if (userId == null) {
          _logger.e('User ID not found for Google Sign-In user.');
          _showErrorDialog(
              'Unable to complete profile. Please try again or contact support.');
          return;
        }

        _logger.i('Completing Google user profile.');
        response = await authService.completeGoogleUserProfile(
          userId: userId,
          password: _passwordController.text.trim(),
          state: state,
          zipCode: zipcode,
          agreedToTerms: _acknowledgeTerms,
        );
      } else {
        _logger.i('Sending registration data to backend.');
        response = await authService.registerCompleteWithLogin(
          email: widget.email,
          password: _passwordController.text.trim(),
          firstName: firstName,
          lastName: lastName,
          state: state,
          zipCode: zipcode,
          agreedToTerms: _acknowledgeTerms,
        );
      }

      _logger.i('Received response: ${response.toString()}');

      if (response['token'] != null) {
        _logger.i('Registration and login successful.');

        // Save the authentication token and user ID to storage
        await storageService.setToken(response['token']);

        // Check for user ID in different possible locations in the response
        if (response['user'] != null && response['user']['id'] != null) {
          // New response structure has user ID inside a user object
          await storageService.setUserId(response['user']['id']);
          _logger
              .i('User ID saved from user object: ${response['user']['id']}');
        } else if (response['userId'] != null) {
          await storageService.setUserId(response['userId']);
        } else if (response['user_id'] != null) {
          await storageService.setUserId(response['user_id']);
        } else if (response['id'] != null) {
          await storageService.setUserId(response['id']);
        } else {
          _logger.e('No user ID found in response: ${response.toString()}');
        }

        _logger.i('Authentication token and user ID saved to storage');

        if (mounted) {
          _showSuccessPopup(firstName);
        }
      } else {
        _logger.e('Registration failed with response: $response');
        if (mounted) {
          _showErrorDialog(response['error'] ??
              response['message'] ??
              'Registration failed. Please try again.');
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error during registration process',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessPopup(String firstName) {
    // Extract user ID for debugging
    final storageService = Provider.of<StorageService>(context, listen: false);
    final userId = storageService.getUserId();
    _logger.i('User ID before showing success popup: $userId');

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(217),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
                  ],
                  stops: [0.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withAlpha(77),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withAlpha(25),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome, $firstName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your account has been created successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Onest',
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final authService =
                              Provider.of<AuthService>(context, listen: false);
                          final storageService = Provider.of<StorageService>(
                              context,
                              listen: false);

                          // Double-check that user ID is set
                          String? userId = storageService.getUserId();
                          if (userId == null) {
                            _logger.w(
                                'User ID is still null before navigation, trying to recover...');

                            // Try to extract from the token
                            final token = await storageService.getToken();
                            if (token != null) {
                              userId =
                                  authService.extractUserIdFromToken(token);
                              if (userId != null) {
                                await storageService.setUserId(userId);
                                _logger.i(
                                    'Recovered user ID from token before navigation: $userId');
                              }
                            }
                          } else {
                            _logger.i(
                                'User ID verified before navigation: $userId');
                          }

                          // For Google sign-ins, always navigate to LinkPlaidBankScreen
                          if (widget.isGoogleSignIn) {
                            _logger.i(
                                'Google sign-in user, redirecting to link plaid bank screen');
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LinkPlaidBankScreen(),
                                ),
                                (route) => false,
                              );
                            }
                            return;
                          }

                          // For regular sign-ups, check if they already have a linked account
                          final bankAccountResponse =
                              await authService.checkLinkedBankAccount();
                          final bool hasLinkedAccount =
                              bankAccountResponse['hasLinkedAccount'] ?? false;

                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => hasLinkedAccount
                                    ? const HomeScreen()
                                    : const LinkPlaidBankScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          _logger.e('Error checking linked bank account:',
                              error: e);
                          // Default to LinkPlaidBankScreen if there's an error
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LinkPlaidBankScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          cursorColor: Colors.white,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            hintText: 'Enter your password',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding: const EdgeInsets.all(20),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
              onPressed: toggleVisibility,
              tooltip: obscureText ? 'Show Password' : 'Hide Password',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: _strengthColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Strength',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _strengthColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _strengthText,
                  style: TextStyle(
                    color: _strengthColor,
                    fontSize: 12,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _strengthScore,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          cursorColor: Colors.white,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            hintText: 'Confirm your password',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              tooltip:
                  _obscureConfirmPassword ? 'Show Password' : 'Hide Password',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePasswordButton() {
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
        onPressed: _isLoading ? null : _submitPassword,
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF1E3A8A),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF1E3A8A)),
                ),
              )
            : const Text(
                'Create Password',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: _acknowledgeTerms
                  ? const Color(0xFF2196F3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _acknowledgeTerms
                    ? const Color(0xFF2196F3)
                    : Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Checkbox(
              value: _acknowledgeTerms,
              onChanged: (bool? value) {
                setState(() {
                  _acknowledgeTerms = value ?? false;
                });
              },
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF2196F3);
                  }
                  return Colors.transparent;
                },
              ),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse('https://www.blinkfinances.com/terms');
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      _showErrorDialog(
                          'Could not open terms of service. Please try again later.');
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorDialog(
                        'Could not open terms of service. Please try again later.');
                  }
                }
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: 'Onest',
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to Blink\'s '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: Colors.blue[300],
                        decoration: TextDecoration.underline,
                      ),
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

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF64B5F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Password Requirements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          _buildEnhancedRequirementItem(
            '8+ characters',
            _hasMinLength,
            Icons.text_fields,
          ),
          _buildEnhancedRequirementItem(
            'Uppercase & lowercase',
            _hasUppercase && _hasLowercase,
            Icons.text_format,
          ),
          _buildEnhancedRequirementItem(
            'Numbers (0-9)',
            _hasNumbers,
            Icons.pin,
          ),
          _buildEnhancedRequirementItem(
            'Special characters (!@#\$%^&*...)',
            _hasSpecialChars,
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRequirementItem(String text, bool isMet, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMet
              ? const Color(0xFF2196F3).withOpacity(0.25)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isMet ? const Color(0xFF64B5F6) : Colors.white.withOpacity(0.2),
            width: isMet ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMet
                    ? const Color(0xFF2196F3).withOpacity(0.3)
                    : Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isMet ? Colors.white : Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isMet ? Colors.white : Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontFamily: 'Onest',
                  fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              isMet ? Icons.check_circle : Icons.check_circle_outline,
              color: isMet
                  ? const Color(0xFF81D4FA)
                  : Colors.white.withOpacity(0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
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
          child: Column(
            children: [
              // Fixed Header
              Container(
                color: const Color(0xFF1E3A8A).withOpacity(0.95),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 24, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed('/auth'),
                          tooltip: 'Go Back',
                        ),
                        Expanded(
                          child: const Text(
                            'Create Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/images/blink_logo_white.png',
                            height: 23,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Scrollable Content
              Expanded(
                child: Stack(
                  children: [
                    // Scrollable Form Content
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0,
                            100.0), // Added bottom padding for button
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                child: Center(
                                  child: Lottie.asset(
                                    'assets/animations/create_password.json',
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              FadeInLeft(
                                duration: const Duration(milliseconds: 600),
                                child: const Text(
                                  'Create Password',
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
                                  'Create a strong password to secure your account',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(230),
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
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(51),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose a strong password that includes a mix of letters, numbers, and symbols. This helps protect your account from unauthorized access.',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(230),
                                        fontSize: 14,
                                        fontFamily: 'Onest',
                                        height: 1.5,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildPasswordField(
                                      label: 'Password',
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      toggleVisibility: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a password';
                                        }
                                        if (_strengthScore < 0.6) {
                                          return 'Password is not strong enough';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPasswordStrengthIndicator(),
                                    const SizedBox(height: 24),
                                    _buildConfirmPasswordField(),
                                    const SizedBox(height: 24),
                                    _buildPasswordRequirements(),
                                    const SizedBox(height: 24),
                                    _buildCheckbox(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Fixed Button at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF1E3A8A).withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: SafeArea(
                          top: false,
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 400),
                            child: _buildCreatePasswordButton(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _generateBubbles() {
    final List<Widget> bubbles = [];
    final random = math.Random();

    for (int i = 0; i < 10; i++) {
      final size = (40 + random.nextDouble() * 20).toInt().toDouble();
      final initialX = random.nextDouble() * MediaQuery.of(context).size.width;
      final initialY = random.nextDouble() * MediaQuery.of(context).size.height;
      final duration = Duration(seconds: 5 + random.nextInt(10));

      bubbles.add(
        AnimatedBubble(
          size: size,
          initialX: initialX,
          initialY: initialY,
          duration: duration,
        ),
      );
    }

    return bubbles;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class UnsupportedMethodException implements Exception {
  final String message;
  UnsupportedMethodException(this.message);

  @override
  String toString() => 'UnsupportedMethodException: $message';
}
