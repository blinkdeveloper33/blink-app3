// lib/features/auth/presentation/link_plaid_bank_screen.dart

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '/services/auth_service.dart';
import '/services/storage_service.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'package:animate_do/animate_do.dart'; // Import animate_do
import 'package:lottie/lottie.dart'; // Import lottie
import 'package:flutter/rendering.dart';
import 'package:blink_app/features/auth/presentation/auth_screen.dart';
import 'package:flutter/services.dart';

class LinkPlaidBankScreen extends StatefulWidget {
  const LinkPlaidBankScreen({super.key});

  @override
  State<LinkPlaidBankScreen> createState() => _LinkPlaidBankScreenState();
}

class _LinkPlaidBankScreenState extends State<LinkPlaidBankScreen> {
  bool _isConnecting = false;
  final String _plaidPrivacyPolicyUrl = 'https://plaid.com/privacy/';
  final Logger _logger = Logger();

  LinkTokenConfiguration? _configuration;
  StreamSubscription<LinkEvent>? _streamEvent;
  StreamSubscription<LinkExit>? _streamExit;
  StreamSubscription<LinkSuccess>? _streamSuccess;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _setupPlaidListeners();
  }

  Future<void> _initializePlaidLink() async {
    setState(() => _isConnecting = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      // First, verify we have a valid user ID and token
      final userId = storageService.getUserId();
      final token = await storageService.getToken();

      if (userId == null || token == null) {
        _logger.e('User not properly authenticated');
        _showErrorDialog('Authentication required. Please log in again.');
        return;
      }

      _logger.i('Initializing Plaid Link for user: $userId');

      // 1. Create link token
      final linkToken = await authService.createLinkToken(userId);
      if (linkToken.isEmpty) {
        throw Exception('Invalid link token received from server');
      }
      _logger.i('Link token received: ${linkToken.substring(0, 10)}...');

      // 2. Configure Plaid Link
      _configuration = LinkTokenConfiguration(
        token: linkToken,
        // Add any additional configuration options here
        // For example, you can customize the institution selection screen
        // or add webhook configurations
      );

      // 3. Create the Plaid Link instance
      await PlaidLink.create(configuration: _configuration!);
      _logger.i('Plaid Link instance created successfully');

      // 4. Open Plaid Link
      await PlaidLink.open();
      _logger.i('Plaid Link opened successfully');
    } catch (e) {
      _logger.e('Error initializing PlaidLink', error: e);
      if (mounted) {
        String errorMessage = 'Failed to initialize Plaid Link. ';
        if (e.toString().contains('network')) {
          errorMessage +=
              'Please check your internet connection and try again.';
        } else if (e.toString().contains('token')) {
          errorMessage += 'Authentication error. Please try logging in again.';
        } else if (e.toString().contains('configuration')) {
          errorMessage += 'Error configuring Plaid. Please try again later.';
        } else {
          errorMessage += e.toString();
        }
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  void dispose() {
    _streamEvent?.cancel();
    _streamExit?.cancel();
    _streamSuccess?.cancel();
    super.dispose();
  }

  void _setupPlaidListeners() {
    // Listen for Plaid Link events
    _streamEvent = PlaidLink.onEvent.listen((event) {
      _logger.i('Plaid Event: ${event.name} - ${event.metadata.description()}');
    });

    // Listen for Plaid Link exit
    _streamExit = PlaidLink.onExit.listen((exit) {
      _logger.i('Plaid Exit: ${exit.metadata.description()}');
      if (exit.error != null) {
        _logger.e('Plaid Error: ${exit.error?.displayMessage}');
        if (mounted) {
          String errorMessage =
              exit.error?.displayMessage ?? 'Connection failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    });

    // Listen for Plaid Link success
    _streamSuccess = PlaidLink.onSuccess.listen((success) async {
      _logger.i('Plaid Success: Public token received');

      try {
        if (!mounted) return;

        setState(() => _isConnecting = true);

        final authService = Provider.of<AuthService>(context, listen: false);
        final storageService =
            Provider.of<StorageService>(context, listen: false);

        final userId = storageService.getUserId();
        if (userId == null) {
          throw Exception('User ID not found');
        }

        // Step 1: Exchange public token
        _logger.i('Exchanging public token...');
        final exchangeResponse = await authService.exchangePublicToken(
          success.publicToken,
          userId,
        );

        if (!exchangeResponse['success'] ||
            exchangeResponse['access_token'] == null) {
          throw Exception('Failed to exchange public token');
        }
        _logger.i('Public token exchanged successfully');

        final accessToken = exchangeResponse['access_token'];
        _logger.i('Access token received successfully');

        if (!mounted) return;

        // Step 2: Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF061535),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/blink_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFF60A5FA)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Text(
                        'Bank Account Linked!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You\'ve successfully linked your bank account.\nWe\'re now analyzing your financial data...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'Onest',
                        height: 1.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2196F3), Color(0xFF60A5FA)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Step 3: Create asset report
        _logger.i('Creating asset report...');
        final assetReportResponse = await authService.createAssetReport(
          accessTokens: [accessToken],
          daysRequested: 30,
        );

        if (assetReportResponse['asset_report_token'] == null) {
          throw Exception(
              'Failed to create asset report: No asset report token received');
        }

        // Step 4: Wait for report to be ready and retrieve it
        _logger.i('Retrieving asset report...');
        Map<String, dynamic>? report;
        int attempts = 0;
        const maxAttempts = 5;
        const delaySeconds = 2;

        while (attempts < maxAttempts) {
          try {
            report = await authService.getAssetReport(
              assetReportToken: assetReportResponse['asset_report_token'],
              includeInsights: true,
            );
            _logger.i('Asset report retrieved successfully');
            break;
          } catch (e) {
            _logger.w(
                'Asset report not ready yet, retrying in $delaySeconds seconds...');
            attempts++;
            if (attempts < maxAttempts) {
              await Future.delayed(Duration(seconds: delaySeconds));
            }
          }
        }

        if (report == null) {
          _logger
              .w('Could not retrieve asset report after $maxAttempts attempts');
        }

        // Step 5: Navigate to home screen
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      } catch (e) {
        _logger.e('Error in success handler:', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().contains('retrieve access token')
                  ? 'Error retrieving bank access token. Please try again.'
                  : e.toString().contains('exchange public token')
                      ? 'Error connecting to bank. Please try again.'
                      : e.toString().contains('asset report')
                          ? 'Error analyzing bank data. Please try again.'
                          : 'An error occurred while processing your bank information'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isConnecting = false);
        }
      }
    });
  }

  Widget _buildSecurityFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Onest',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankLogo(String assetPath) {
    double padding = assetPath.contains('wells_fargo') ? 8.0 : 12.0;
    return Container(
      width: 80,
      height: 80,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (BuildContext context) => Container(
          padding: const EdgeInsets.all(12),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(_plaidPrivacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch Privacy Policy'),
        ),
      );
    }
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: FadeInUp(
        duration: const Duration(milliseconds: 800),
        delay: const Duration(milliseconds: 600),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF60A5FA)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isConnecting ? null : _initializePlaidLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isConnecting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9)),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Connect Bank Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.lock_outline,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserName() async {
    setState(() {});
  }

  Future<void> _handleBackPress() async {
    try {
      setState(() => _isConnecting = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      try {
        // Try to logout properly first
        await authService.logout();
      } catch (e) {
        _logger.e('Error during logout API call:', error: e);
        // If logout API fails, still clear local storage
        await storageService.clearAll();
      }

      if (!mounted) return;

      // Always navigate back to auth screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
        (route) => false, // This removes all routes from the stack
      );
    } catch (e) {
      _logger.e('Error in _handleBackPress:', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Error during logout. Your session may have expired.'),
            backgroundColor: Colors.orange,
          ),
        );
        // Still try to navigate back to auth screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _handleBackPress,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      if (_isConnecting)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9),
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Lottie.asset(
                              'assets/animations/link_bank.json',
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                _logger.e(
                                    'Error loading Lottie animation: $error');
                                return Container(
                                  height: 180,
                                  color: Colors.white.withOpacity(0.1),
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 800),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFF60A5FA)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            'Link Your Bank Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'Securely Connect to Your Bank to Enable Cash',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Security features section
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildSecurityFeature(
                                icon: Icons.lock_outline,
                                title: 'Bank-level Security',
                                description:
                                    '256-bit encryption to protect your data',
                              ),
                              const SizedBox(height: 20),
                              _buildSecurityFeature(
                                icon: Icons.visibility_off_outlined,
                                title: 'Privacy First',
                                description:
                                    'We never store your login credentials',
                              ),
                              const SizedBox(height: 20),
                              _buildSecurityFeature(
                                icon: Icons.verified_user_outlined,
                                title: 'Verified by Plaid',
                                description:
                                    'Trusted by millions of users worldwide',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Supported banks section
                      Center(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 400),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Supported Banks',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildBankLogo(
                                        'assets/images/bank_of_america.svg'),
                                    _buildBankLogo('assets/images/chase.svg'),
                                    _buildBankLogo(
                                        'assets/images/wells_fargo.svg'),
                                    _buildBankLogo('assets/images/citi.svg'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Privacy policy section
                      Center(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 600),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'Onest',
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                    text: 'By continuing, you agree to the '),
                                TextSpan(
                                  text: 'Plaid privacy policy',
                                  style: const TextStyle(
                                    color: Color(0xFF60A5FA),
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _launchPrivacyPolicy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildContinueButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF061535),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connection Failed',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.redAccent.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
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
        );
      },
    );
  }
}
