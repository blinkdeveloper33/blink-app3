import 'package:flutter/material.dart';
import 'package:blink_app/features/auth/presentation/select_verification_method_screen.dart';
import 'package:blink_app/features/auth/presentation/login_screen.dart';
import 'package:logger/logger.dart';
import 'package:animate_do/animate_do.dart';

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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  //final TextEditingController _nameController = TextEditingController();
  //final TextEditingController _passwordController = TextEditingController();
  //final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  final Logger _logger = Logger();
  final FocusNode _emailFocusNode = FocusNode();
  //final FocusNode _nameFocusNode = FocusNode();
  //final FocusNode _passwordFocusNode = FocusNode();
  //final FocusNode _confirmPasswordFocusNode = FocusNode();
  //bool _obscurePassword = true;
  //bool _obscureConfirmPassword = true;
  bool _isGoogleHovered = false;
  bool _isAppleHovered = false;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    //_nameFocusNode.addListener(() {
    //  setState(() {});
    //});
    //_passwordFocusNode.addListener(() {
    //  setState(() {});
    //});
    //_confirmPasswordFocusNode.addListener(() {
    //  setState(() {});
    //});

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
    //_nameFocusNode.dispose();
    //_passwordFocusNode.dispose();
    //_confirmPasswordFocusNode.dispose();
    _emailController.dispose();
    //_nameController.dispose();
    //_passwordController.dispose();
    //_confirmPasswordController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _submitSignUp() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      _pulseAnimationController.repeat(reverse: true);
      final email = _emailController.text.trim();

      _logger.d('Signing up with email: $email');

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _pulseAnimationController.stop();
          });
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  SelectVerificationMethodScreen(email: email),
            ),
          );
        }
      });
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
    //bool isPassword = false,
    //bool isConfirmPassword = false,
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
                  //obscureText: isPassword ? _obscurePassword : (isConfirmPassword ? _obscureConfirmPassword : false),
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
                    //suffixIcon: (isPassword || isConfirmPassword)
                    //    ? IconButton(
                    //        icon: Icon(
                    //          (isPassword ? _obscurePassword : _obscureConfirmPassword) ? Icons.visibility_off : Icons.visibility,
                    //          color: Colors.white70,
                    //        ),
                    //        onPressed: () {
                    //          setState(() {
                    //            if (isPassword) {
                    //              _obscurePassword = !_obscurePassword;
                    //            } else {
                    //              _obscureConfirmPassword = !_obscureConfirmPassword;
                    //            }
                    //          });
                    //        },
                    //      )
                    //    : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ${label.toLowerCase()}';
                    }
                    if (label == 'Email Address') {
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

  Widget _buildSignUpButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitSignUp,
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
                        'Sign Up',
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
                        'Create Account',
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
                        'Sign up to get started',
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
                              onPressed: _handleGoogleSignUp,
                              isHovered: _isGoogleHovered,
                              onHover: (value) =>
                                  setState(() => _isGoogleHovered = value),
                            ),
                            const SizedBox(height: 16),
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
                            _buildInputField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 24),
                            _buildSignUpButton(),
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
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
        ],
      ),
    );
  }
}
