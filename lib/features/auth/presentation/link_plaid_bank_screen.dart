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
import 'package:myapp/features/home/presentation/home_screen.dart';

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
    _initializePlaidLink();
  }

  Future<void> _initializePlaidLink() async {
    setState(() => _isConnecting = true);
    try {
      await _createLinkTokenConfiguration();
      setState(() => _isConnecting = false);
    } catch (e) {
      _logger.e('Error initializing PlaidLink', error: e);
      setState(() => _isConnecting = false);
      if (mounted) {
        _showErrorDialog('Failed to initialize Plaid Link');
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

    final linkToken = await authService.createLinkToken(userId);
    _configuration = LinkTokenConfiguration(token: linkToken);

    await PlaidLink.create(configuration: _configuration!);
  }

  Future<void> _onSuccess(LinkSuccess event) async {
    if (!mounted) return;

    _logger.i("onSuccess: ${event.publicToken}");

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

      // Exchange the public token for an access token using AuthService
      final response =
          await authService.exchangePublicToken(publicToken, userId);

      if (!mounted) return;

      if (response['success'] == true) {
        _logger.i('Bank account linked successfully: ${response['message']}');

        // Store the bank account ID
        final bankAccountId = response['bankAccountId'] as String?;
        if (bankAccountId != null) {
          await storageService.setBankAccountId(bankAccountId);
          _logger.i('Bank account ID stored: $bankAccountId');
        } else {
          _logger.w('Bank account ID not received from the server');
        }

        if (response['bankAccountName'] != null) {
          await storageService.setBankAccountName(response['bankAccountName']);
          _logger.i('Bank account name stored: ${response['bankAccountName']}');
        } else {
          _logger.w('Bank account name not received from the server');
        }

        // Fetch and store detailed bank accounts
        final detailedBankAccounts =
            await authService.getDetailedBankAccounts();
        if (mounted) {
          await storageService.setDetailedBankAccounts(detailedBankAccounts);
        }

        if (mounted) {
          _showSuccessDialog(bankAccountId);
        }

        // Perform background tasks without blocking the UI
        _performBackgroundTasks(userId);
      } else {
        if (mounted) {
          _showErrorDialog(
              'Failed to link bank account: ${response['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        _showErrorDialog('Failed to link bank account: ${e.toString()}');
      }
      _logger.e('Error exchanging public token',
          error: e, stackTrace: stackTrace);
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
                Image.asset(
                  'assets/animations/success-1--unscreen.gif',
                  height: 150,
                  width: 150,
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
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomeScreen(), // Removed parameters
                        ),
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
        return AlertDialog(
          backgroundColor: const Color(0xFF061535),
          title: const Text(
            'Connection Failed',
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
      child: ElevatedButton(
        onPressed: _isConnecting ? null : () => PlaidLink.open(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isConnecting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Connect Bank Account',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
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
      backgroundColor: const Color(0xFF061535),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Link Your Bank Account\nVia Plaid',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Securely Connect to Your Bank to Enable Cash',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Image.asset(
                    'assets/images/link_bank.png',
                    height: MediaQuery.of(context).size.height * 0.3,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                _buildSecurityFeature(
                  icon: Icons.lock_outline,
                  title: 'Bank-level Security',
                  description: '256-bit encryption to protect your data',
                ),
                const SizedBox(height: 16),
                _buildSecurityFeature(
                  icon: Icons.visibility_off_outlined,
                  title: 'Privacy First',
                  description: 'We never store your login credentials',
                ),
                const SizedBox(height: 16),
                _buildSecurityFeature(
                  icon: Icons.verified_user_outlined,
                  title: 'Verified by Plaid',
                  description: 'Trusted by millions of users worldwide',
                ),
                const SizedBox(height: 40),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontFamily: 'Onest',
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'We use ',
                        ),
                        TextSpan(
                          text: 'Plaid',
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' to securely link your bank\naccount. Your credentials are never stored.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildBankLogo('assets/images/bank_of_america.svg'),
                      _buildBankLogo('assets/images/chase.svg'),
                      _buildBankLogo('assets/images/wells_fargo.svg'),
                      _buildBankLogo('assets/images/citi.svg'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                    children: [
                      const TextSpan(
                        text: 'By selecting "Continue" you agree to the ',
                      ),
                      TextSpan(
                        text: 'Plaid privacy policy',
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _launchPrivacyPolicy,
                      ),
                    ],
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
    );
  }
}
