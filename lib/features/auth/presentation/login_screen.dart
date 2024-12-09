import 'package:flutter/material.dart';
import 'package:myapp/features/auth/presentation/sign_up_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:myapp/features/home/presentation/home_screen.dart';
import 'package:myapp/features/auth/presentation/link_plaid_bank_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  final Logger _logger = Logger();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
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

        if (loginResponse['success']) {
          final userId = storageService.getUserId();
          final fullName = storageService.getFullName();

          if (userId == null) {
            _showErrorDialog('User ID not found. Please try logging in again.');
            return;
          }

          // Fetch detailed bank accounts
          final detailedBankAccounts =
              await authService.getDetailedBankAccounts();
          await storageService.setDetailedBankAccounts(detailedBankAccounts);

          // Now that we have the token and user ID, check the user status
          UserStatus userStatus = await authService.getUserStatus();

          if (!mounted) return;

          switch (userStatus) {
            case UserStatus.newUser:
              Navigator.of(context).pushReplacementNamed('/signup');
              break;
            case UserStatus.noBankAccount:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LinkPlaidBankScreen(),
                ),
              );
              break;
            case UserStatus.complete:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    userName: fullName ?? 'User',
                    bankAccountId: '',
                  ),
                ),
              );
              break;
          }
        } else {
          _showErrorDialog(
              loginResponse['message'] ?? 'Login failed. Please try again.');
        }
      } catch (e) {
        _logger.e('Error during login', error: e);
        _showErrorDialog('An unexpected error occurred. Please try again.');
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
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
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            hintText: 'Enter your password',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
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
                  ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                  delay: const Duration(milliseconds: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 24),
                        _buildPasswordField(),
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
    );
  }
}
