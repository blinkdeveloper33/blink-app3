// lib/features/auth/presentation/link_plaid_bank_screen.dart

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import '/services/auth_service.dart';
import '/services/storage_service.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'package:animate_do/animate_do.dart'; // Import animate_do
import 'package:lottie/lottie.dart'; // Import lottie
import 'package:flutter/rendering.dart';
import 'package:blink_app/features/auth/presentation/auth_screen.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;

// IMPORTANT: To fully implement OAuth for Plaid on mobile platforms, you must:
//
// 1. For iOS:
//    - Configure universal links using an Apple App Association file
//    - Set up deep link handling using the uni_links package or Apple's native APIs
//    - Your redirect URI must be a universal link (not a custom URI scheme)
//
// 2. For Android:
//    - Add your app's package name to the Plaid Dashboard
//    - Configure Android App Links with assetlinks.json
//    - Set up an IntentFilter in your AndroidManifest.xml
//    - Use the android_package_name parameter instead of redirect_uri
//
// 3. For App-to-App authentication (like Chase):
//    - Make sure your app handles the return to your app after authentication
//    - On iOS, you MUST configure universal links correctly
//    - On Android, you MUST configure App Links properly

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
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _setupPlaidListeners();

    _initDeepLinkListener();
  }

  Future<void> _initDeepLinkListener() async {
    try {
      final initialLink = await getInitialUri();
      if (initialLink != null) {
        _logger.i('App opened from link: $initialLink');
        _handleIncomingLink(initialLink);
      }
    } catch (e) {
      _logger.e('Error getting initial link: $e');
    }

    _deepLinkSubscription = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _logger.i('Received link while app was running: $uri');
        _handleIncomingLink(uri);
      }
    }, onError: (error) {
      _logger.e('Error in deep link stream: $error');
    });
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.path.contains('plaid-callback')) {
      _logger.i('Received Plaid callback with params: ${uri.queryParameters}');

      final oauthStateId = uri.queryParameters['oauth_state_id'];
      if (oauthStateId != null) {
        _logger.i('OAuth state ID found: $oauthStateId');

        _initializePlaidLink(receivedRedirectUri: uri.toString());
      }
    }
  }

  @override
  void dispose() {
    _streamEvent?.cancel();
    _streamExit?.cancel();
    _streamSuccess?.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePlaidLink({String? receivedRedirectUri}) async {
    setState(() => _isConnecting = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      final userId = storageService.getUserId();
      final token = await storageService.getToken();

      _logger.i(
          'Auth check - userId: ${userId != null ? "exists" : "missing"}, token: ${token != null ? "exists" : "missing"}');

      String? userIdToUse = userId;
      if (userId == null && token != null) {
        _logger.i(
            'Token exists but userId is missing. Attempting to fetch user profile...');
        try {
          final userProfile = await authService.getUserProfile();
          if (userProfile != null && userProfile['id'] != null) {
            userIdToUse = userProfile['id'];
            await storageService.setUserId(userIdToUse!);
            _logger.i('Recovered userId from profile: $userIdToUse');
          }
        } catch (e) {
          _logger.e('Failed to recover userId: $e');
        }
      }

      if (userIdToUse == null || token == null) {
        _logger.e(
            'User not properly authenticated. userId: $userIdToUse, token: ${token != null ? "exists" : "null"}');

        if (mounted) {
          _showErrorDialog(
              'Your session appears to have expired. Please try logging in again to securely connect your bank account.');
        }
        return;
      }

      _logger.i('Initializing Plaid Link for user: $userIdToUse');

      final linkToken = await authService.createLinkToken(
        userIdToUse,
        redirectUri: 'https://blinkfinances.com/plaid-callback',
        androidPackageName: null,
      );

      if (linkToken.isEmpty) {
        throw Exception('Invalid link token received from server');
      }
      _logger.i('Link token received: ${linkToken.substring(0, 10)}...');

      bool isOAuthRedirect = receivedRedirectUri != null;

      _logger.i(
          'OAuth redirect check: $isOAuthRedirect, URI: ${receivedRedirectUri ?? "none"}');

      final configuration = LinkTokenConfiguration(
        token: linkToken,
        receivedRedirectUri: receivedRedirectUri,
      );

      _configuration = configuration;

      await PlaidLink.create(configuration: _configuration!);
      _logger.i('Plaid Link instance created successfully');

      await PlaidLink.open();
      _logger.i('Plaid Link opened successfully');
    } catch (e) {
      _logger.e('Error initializing Plaid Link: $e');
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing Plaid: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          // Use the description string to identify institution registration errors
          final metadataDesc = exit.metadata.description();
          final errorMessage = exit.error?.displayMessage ?? '';

          // Check for institution registration errors in the metadata description or error message
          bool isInstitutionRegistrationError =
              metadataDesc.contains('institution_not_found') ||
                  metadataDesc.contains('INSTITUTION_REGISTRATION_REQUIRED') ||
                  errorMessage.contains('register') ||
                  errorMessage.contains('not yet registered');

          if (isInstitutionRegistrationError) {
            // Extract the institution name from metadata description
            String institutionName = 'this institution';

            // Try to extract institution name from metadata description
            // The log shows format like "institution.name: Chase"
            final institutionNameMatch =
                RegExp(r'institution.name: ([^,<]+)').firstMatch(metadataDesc);
            if (institutionNameMatch != null &&
                institutionNameMatch.groupCount >= 1) {
              institutionName =
                  institutionNameMatch.group(1)?.trim() ?? institutionName;
            }

            // Show a specialized error dialog for institution registration issues
            _showInstitutionRegistrationDialog(institutionName);
          } else {
            // Show regular error for other issues
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
                  color: Colors.transparent,
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
          daysRequested: 731,
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
        _logger.e('Error in success handler: $e');
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          haptics.Haptics.vibrate(haptics.HapticsType.light);
                          Navigator.pop(context);
                        },
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

  void _showInstitutionRegistrationDialog(String institutionName) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF061535),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bank Not Yet Available',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$institutionName is not yet available for connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'re working on adding support for this bank. Please try connecting a different bank account or check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .pop(); // Return to previous screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Re-initialize the Plaid Link to try with a different bank
                          _initializePlaidLink();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.amber.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Try Another Bank',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
