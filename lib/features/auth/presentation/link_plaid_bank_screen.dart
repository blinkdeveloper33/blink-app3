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
      await _createLinkTokenConfiguration();
      await PlaidLink.open();
    } catch (e) {
      _logger.e('Error initializing PlaidLink', error: e);
      if (mounted) {
        _showErrorDialog(
            'Failed to initialize Plaid Link. Please ensure you\'re connected to the internet and try again.');
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
    _streamEvent = PlaidLink.onEvent.listen(_onEvent);
    _streamExit = PlaidLink.onExit.listen((event) {
      _onExit(event);
      if (event.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(event.error?.displayMessage ?? 'Connection failed'),
          ),
        );
      }
    });
    _streamSuccess = PlaidLink.onSuccess.listen(_onSuccess);
  }

  Future<void> _createLinkTokenConfiguration() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    final userId = storageService.getUserId();
    if (userId == null) {
      throw Exception('User ID missing. Please log in again.');
    }

    _logger.i('Creating link token for user: $userId');
    final linkToken = await authService.createLinkToken(userId);

    if (linkToken.isEmpty) {
      throw Exception('Failed to obtain link token from server');
    }

    _logger.i('Link token created successfully');
    _configuration = LinkTokenConfiguration(token: linkToken);
    await PlaidLink.create(configuration: _configuration!);
  }

  Future<void> _onSuccess(LinkSuccess event) async {
    if (!mounted) return;

    _logger.i("Plaid Link Success: ${event.publicToken}");
    final publicToken = event.publicToken;

    try {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      final userId = storageService.getUserId();
      if (userId == null) {
        _showErrorDialog('User ID missing. Please log in again.');
        return;
      }

      setState(() => _isConnecting = true);
      _logger.i('Exchanging public token for user: $userId');

      // Exchange the public token for an access token
      final response =
          await authService.exchangePublicToken(publicToken, userId);

      if (!mounted) return;

      if (response['success'] == true) {
        _logger.i('Bank account linked successfully: ${response['message']}');

        // Store the bank account information
        if (response['accounts'] != null && response['accounts'].isNotEmpty) {
          final firstAccount = response['accounts'][0];
          await storageService.setBankAccountId(firstAccount['account_id']);
          await storageService.setBankAccountName(firstAccount['name']);
          _logger.i('Bank account info stored: ${firstAccount['name']}');
        }

        // Show success dialog
        if (mounted) {
          _showSuccessDialog(
              response['accounts']?[0]?['name'] ?? 'Your bank account');
        }

        // Start background sync
        _performBackgroundTasks(userId);
      } else {
        if (mounted) {
          _showErrorDialog(
              'Failed to link bank account: ${response['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Error exchanging public token',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        _showErrorDialog('Failed to link bank account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _performBackgroundTasks(String userId) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Sync transactions
      await authService.syncTransactions(userId);
      _logger.i('Transactions synced successfully');

      // Get transactions (you might want to specify date range and other parameters)
      final transactions = await authService.getTransactions(
        userId: userId,
        bankAccountId: 'all',
        startDate:
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        endDate: DateTime.now().toIso8601String(),
      );
      _logger.i(
          'Transactions retrieved successfully: ${transactions.length} transactions');

      // Sync balances
      await authService.syncBalances(userId);
      _logger.i('Balances synced successfully');
    } catch (e) {
      _logger.e('Error performing background tasks', error: e);
    }
  }

  void _onExit(LinkExit event) {
    if (!mounted) return;

    _logger.i("onExit metadata: ${event.metadata.description()}");
    if (event.error != null) {
      final errorCode = event.error?.displayMessage ?? 'Unknown error';
      final errorDetails = event.error?.description() ?? '';

      _logger.e('Plaid Link Error: $errorCode - $errorDetails');
      _showErrorDialog('Connection cancelled: $errorCode');
    } else {
      _logger.i('Plaid Link exited without error');
    }
  }

  void _onEvent(LinkEvent event) {
    _logger
        .i("onEvent: ${event.name}, metadata: ${event.metadata.description()}");
  }

  void _showSuccessDialog(String? bankAccountId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF061535),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/success.json',
                  height: 150,
                  width: 150,
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bank Account Linked Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your bank account has been linked. You can now start using our services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Continue',
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
    Provider.of<StorageService>(context, listen: false);
    setState(() {});
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
            child: Padding(
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
                            _logger.e('Error loading Lottie animation: $error');
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
                                _buildBankLogo('assets/images/wells_fargo.svg'),
                                _buildBankLogo('assets/images/citi.svg'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
          ),
        ),
      ),
    );
  }
}
