import 'package:flutter/material.dart';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:blink_app/features/auth/presentation/link_plaid_bank_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  final Logger _logger = Logger();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isGoogleHovered = false;
  bool _isAppleHovered = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  String? _errorMessage;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
          parent: _pulseAnimationController, curve: Curves.easeInOut),
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

  Future<void> _submitLogin() async {
    setState(() {
      _errorMessage = null;
      _showError = false;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final storageService =
            Provider.of<StorageService>(context, listen: false);

        final loginResponse = await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (loginResponse['success'] == true) {
          final userId = storageService.getUserId();
          if (userId == null) {
            setState(() {
              _errorMessage = 'Account not found. Would you like to sign up?';
              _showError = true;
            });
            return;
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          String errorMessage = 'Invalid email or password. ';
          if (loginResponse['message']?.contains('not found') ?? false) {
            errorMessage += 'Don\'t have an account? Sign up below!';
          } else {
            errorMessage += 'Please try again.';
          }
          setState(() {
            _errorMessage = errorMessage;
            _showError = true;
          });
        }
      } catch (e) {
        _logger.e('Error during login', error: e);
        setState(() {
          _errorMessage =
              'Unable to connect. Please check your internet connection and try again.';
          _showError = true;
        });
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _handleGoogleSignIn() {
    _logger.d('Google Sign In Pressed');
    // TODO: Implement Google Sign In
  }

  void _handleAppleSignIn() {
    _logger.d('Apple Sign In Pressed');
    // TODO: Implement Apple Sign In
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
              color: Colors.black.withAlpha(25),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Stack(
              children: [
                TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: isPassword ? _obscurePassword : false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withAlpha(25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withAlpha(76)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Color(0xFF2196F3), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    prefixIcon: Icon(icon, color: Colors.white70),
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ${label.toLowerCase()}';
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
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top:
                      focusNode.hasFocus || controller.text.isNotEmpty ? 8 : 20,
                  left: 56,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: focusNode.hasFocus || controller.text.isNotEmpty
                          ? 12
                          : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Text(label),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLogin,
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
                        'Log In',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
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

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? Color(0xFF2196F3) : Colors.white70,
                width: 2,
              ),
              color: _rememberMe ? Color(0xFF2196F3) : Colors.transparent,
            ),
            child: _rememberMe
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Remember Me',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontFamily: 'Onest',
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
                    const SizedBox(height: 40),
                    Center(
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Image.asset(
                          'assets/images/blink_logo.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInLeft(
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        'Welcome Back',
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
                        'Log in to your account',
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
                              onHover: (value) =>
                                  setState(() => _isGoogleHovered = value),
                            ),
                            const SizedBox(height: 16),
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
                            if (_showError && _errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: AnimatedErrorMessage(
                                  message: _errorMessage!,
                                  onDismiss: () =>
                                      setState(() => _showError = false),
                                ),
                              ),
                            _buildInputField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 16),
                            _buildRememberMeCheckbox(),
                            const SizedBox(height: 24),
                            _buildLoginButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 600),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password functionality
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 16,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 800),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Don\'t have an account? Sign Up',
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
        ],
      ),
    );
  }
}

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

class AnimatedErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const AnimatedErrorMessage({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withAlpha(76)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  height: 1.4,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
