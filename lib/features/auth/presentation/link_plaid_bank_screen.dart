// lib/features/auth/presentation/link_plaid_bank_screen.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
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
import 'dart:convert';

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

// Custom Pulse Animation Widget
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

// Custom Shimmer Icon Widget
class ShimmerIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const ShimmerIcon({
    Key? key,
    required this.icon,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  State<ShimmerIcon> createState() => _ShimmerIconState();
}

class _ShimmerIconState extends State<ShimmerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Icon(
          widget.icon,
          size: widget.size,
          color: widget.color.withOpacity(_animation.value),
        );
      },
    );
  }
}

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

  // Add new properties for bank carousel
  int _currentBankSet = 0;
  Timer? _bankCarouselTimer;
  final List<List<String>> _bankSets = [
    [
      'bank of america',
      'chase',
      'wells fargo',
      'citibank',
      'capital one',
      'pnc bank'
    ],
    [
      'td bank',
      'american express',
      'amerant bank',
      'usaa',
      'goldman sachs',
      'navy federal'
    ],
  ];

  @override
  void initState() {
    super.initState();
    _setupPlaidListeners();
    _initDeepLinkListener();
    // Initialize bank carousel rotation
    _initBankCarousel();
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
    // Dispose of bank carousel timer
    _bankCarouselTimer?.cancel();
    super.dispose();
  }

  void _initBankCarousel() {
    // Rotate bank sets every 3.5 seconds with smoother transitions
    _bankCarouselTimer =
        Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted) {
        setState(() {
          _currentBankSet = (_currentBankSet + 1) % _bankSets.length;
        });
      }
    });
  }

  // Show next set of banks
  void _nextBankSet() {
    if (mounted) {
      setState(() {
        _currentBankSet = (_currentBankSet + 1) % _bankSets.length;
      });
    }
  }

  // Show previous set of banks
  void _previousBankSet() {
    if (mounted) {
      setState(() {
        _currentBankSet =
            (_currentBankSet - 1 + _bankSets.length) % _bankSets.length;
      });
    }
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
          // First try to get user profile from the server
          final userProfile = await authService.getUserProfile();
          if (userProfile != null && userProfile['id'] != null) {
            userIdToUse = userProfile['id'];
            await storageService.setUserId(userIdToUse!);
            _logger.i('Recovered userId from profile: $userIdToUse');
          } else if (userProfile != null &&
              userProfile['user'] != null &&
              userProfile['user']['id'] != null) {
            // Try user object format
            userIdToUse = userProfile['user']['id'];
            await storageService.setUserId(userIdToUse!);
            _logger.i('Recovered userId from user object: $userIdToUse');
          } else {
            // If that fails, try to extract it from the JWT token
            _logger.i(
                'Could not recover userId from profile API, trying to extract from JWT token...');
            try {
              final extractedUserId = authService.extractUserIdFromToken(token);
              if (extractedUserId != null) {
                userIdToUse = extractedUserId;
                await storageService.setUserId(userIdToUse);
                _logger.i('Recovered userId from JWT token: $userIdToUse');
              }
            } catch (tokenError) {
              _logger.e('Error extracting userId from token: $tokenError');
            }
          }
        } catch (e) {
          _logger.e('Failed to recover userId from profile API: $e');
          // Try JWT extraction as fallback (same code as above)
          try {
            final extractedUserId = authService.extractUserIdFromToken(token);
            if (extractedUserId != null) {
              userIdToUse = extractedUserId;
              await storageService.setUserId(userIdToUse);
              _logger.i(
                  'Recovered userId from JWT token as fallback: $userIdToUse');
            }
          } catch (tokenError) {
            _logger.e('Error extracting userId from token: $tokenError');
          }
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3).withOpacity(0.2),
                  const Color(0xFF64B5F6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
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
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'Onest',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankLogo(String? merchantName, {bool isMoreCard = false}) {
    if (isMoreCard) {
      return Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2196F3).withOpacity(0.3),
              const Color(0xFF64B5F6).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "400+",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (merchantName == null || merchantName.isEmpty) {
      return Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.account_balance,
            color: Colors.white.withOpacity(0.5), size: 30),
      );
    }

    return FutureBuilder<String>(
      future: _getMerchantLogoUrl(merchantName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.isNotEmpty) {
          return Container(
            width: 95,
            height: 95,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                snapshot.data!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  _logger.w('Failed to load bank logo: $error');
                  return _fallbackBankLogo(merchantName);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        return _fallbackBankLogo(merchantName);
      },
    );
  }

  Future<String> _getMerchantLogoUrl(String merchantName) async {
    try {
      const String brandfetchClientId = "1id12_wkWpgV3pKnxQI";
      final Map<String, String> knownBanks = {
        'bank of america': 'bankofamerica.com',
        'chase': 'chase.com',
        'wells fargo': 'wellsfargo.com',
        'citibank': 'citi.com',
        'capital one': 'capitalone.com',
        'td bank': 'td.com',
        'american express': 'americanexpress.com',
        'discover': 'discover.com',
        'pnc bank': 'pnc.com',
        'pnc': 'pnc.com',
        'usaa': 'usaa.com',
        'hsbc': 'hsbc.com',
        'truist': 'truist.com',
        'ally bank': 'ally.com',
        'us bank': 'amerantbank.com',
        'amerant bank': 'amerantbank.com',
        'navy federal': 'navyfederal.org',
        'goldman sachs': 'goldmansachs.com',
        'citizens bank': 'citizensbank.com'
      };

      String domain = knownBanks[merchantName.toLowerCase()] ??
          merchantName.toLowerCase().replaceAll(' ', '') + '.com';

      // URL encoding is handled by the Uri class
      String url =
          'https://cdn.brandfetch.io/$domain/icon/theme/light/fallback/lettermark/w/95/h/95?c=$brandfetchClientId';
      return url;
    } catch (e) {
      _logger.e('Error getting merchant logo URL: $e');
      return '';
    }
  }

  Widget _fallbackBankLogo(String merchantName) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          merchantName.isNotEmpty
              ? merchantName.substring(0, 1).toUpperCase()
              : "B",
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'Onest',
          ),
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

        // Step 3: Create asset report - Just initiate and don't wait for completion
        _logger.i('Initiating asset report creation...');
        try {
          final assetReportResponse = await authService.createAssetReport(
            accessTokens: [accessToken],
            daysRequested: 731, // Maximum history
          );

          if (assetReportResponse['asset_report_token'] != null) {
            // Store the asset report token in user preferences
            final userPreferences =
                await storageService.getUserPreferences() ?? {};
            userPreferences['pending_asset_report_token'] =
                assetReportResponse['asset_report_token'];
            userPreferences['asset_report_created_at'] =
                DateTime.now().toIso8601String();
            await storageService.setUserPreferences(userPreferences);

            _logger.i(
                'Asset report creation initiated successfully. Webhook will notify when ready.');
          } else {
            _logger.w('No asset report token received, but continuing anyway');
          }
        } catch (assetReportError) {
          _logger.e('Error creating asset report: $assetReportError');

          // Check for timeout or 502 errors specifically
          if (assetReportError.toString().contains('502') ||
              assetReportError.toString().contains('timeout') ||
              assetReportError.toString().contains('failed to respond')) {
            // Store information for retry in user preferences
            final userPreferences =
                await storageService.getUserPreferences() ?? {};
            userPreferences['should_retry_asset_report'] = 'true';
            userPreferences['asset_report_retry_access_token'] = accessToken;
            userPreferences['asset_report_retry_attempts'] = '0';
            userPreferences['asset_report_last_retry'] =
                DateTime.now().toIso8601String();
            await storageService.setUserPreferences(userPreferences);

            _logger.i('Stored retry information for asset report');
          }

          // Don't rethrow - allow navigation to continue even if asset report fails
        }

        // Step 5: Navigate to home screen, without waiting for report completion
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
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
          child: Column(
            children: [
              Container(
                color: const Color(0xFF0D47A1).withOpacity(0.95),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 24, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          onPressed: () {
                            haptics.Haptics.vibrate(haptics.HapticsType.light);
                            _showLogoutConfirmation();
                          },
                          tooltip: 'Go Back',
                        ),
                        Expanded(
                          child: Text(
                            'Connect Bank',
                            style: const TextStyle(
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
              Expanded(
                child: Stack(
                  children: [
                    // Scrollable Content
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            FadeInLeft(
                              duration: const Duration(milliseconds: 800),
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
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
                            const SizedBox(height: 32),
                            Center(
                              child: FadeInUp(
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
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.account_balance_outlined,
                                            color: const Color(0xFF64B5F6),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Supported Banks',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
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
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      _buildBankLogosCarousel(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.12),
                                      Colors.white.withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2196F3)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.shield,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Security & Privacy',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontFamily: 'Onest',
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black26,
                                                  blurRadius: 2,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildSecurityFeature(
                                      icon: Icons.lock_outline,
                                      title: 'Bank-level Security',
                                      description:
                                          '256-bit encryption to protect your data',
                                    ),
                                    _buildSecurityFeature(
                                      icon: Icons.visibility_off_outlined,
                                      title: 'Privacy First',
                                      description:
                                          'We never store your login credentials',
                                    ),
                                    _buildSecurityFeature(
                                      icon: Icons.verified_user_outlined,
                                      title: 'Verified by Plaid',
                                      description:
                                          'Trusted by millions of users worldwide',
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF2196F3)
                                                .withOpacity(0.15),
                                            const Color(0xFF64B5F6)
                                                .withOpacity(0.08),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontFamily: 'Onest',
                                            height: 1.5,
                                          ),
                                          children: [
                                            const TextSpan(
                                                text:
                                                    'By continuing, you agree to the '),
                                            TextSpan(
                                              text: 'Plaid privacy policy',
                                              style: const TextStyle(
                                                color: Color(0xFF60A5FA),
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = _launchPrivacyPolicy,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // Fixed button at the bottom
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
                              const Color(0xFF0D47A1).withOpacity(0.9),
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
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 600),
                            child: Container(
                              width: double.infinity,
                              height: 56, // Fixed height for consistency
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2196F3)
                                        .withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _isConnecting
                                      ? null
                                      : _initializePlaidLink,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: _isConnecting
                                          ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  const Color(0xFF2196F3)
                                                      .withOpacity(0.9),
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .account_balance_outlined,
                                                  color:
                                                      const Color(0xFF2196F3),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Connect Bank Account',
                                                  style: TextStyle(
                                                    color: Color(0xFF1976D2),
                                                    fontSize: 16,
                                                    fontFamily: 'Onest',
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

  // Update the bank logo section to show the carousel
  Widget _buildBankLogosCarousel() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeOutQuint,
          switchOutCurve: Curves.easeInQuint,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Padding(
            key: ValueKey<int>(_currentBankSet),
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
            child: Column(
              children: [
                // First row of 3 banks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBankLogo(_getBankNameSafely(_currentBankSet, 0)),
                    _buildBankLogo(_getBankNameSafely(_currentBankSet, 1)),
                    _buildBankLogo(_getBankNameSafely(_currentBankSet, 2)),
                  ],
                ),
                const SizedBox(height: 16),
                // Second row of 3 banks (only if there are enough banks)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBankLogo(_getBankNameSafely(_currentBankSet, 3)),
                    _buildBankLogo(_getBankNameSafely(_currentBankSet, 4)),
                    _buildBankLogo(_getBankNameSafely(_currentBankSet, 5)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Enhanced 400+ banks supported component without animation
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2196F3).withOpacity(0.25),
                const Color(0xFF448AFF).withOpacity(0.35),
              ],
              stops: const [0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerIcon(
                      icon: Icons.account_balance,
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFF90CAF9)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: const Text(
                              "400+ Banks Supported",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Connect to any major financial institution",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Safe method to get bank names without index errors
  String? _getBankNameSafely(int setIndex, int bankIndex) {
    if (setIndex < 0 || setIndex >= _bankSets.length) {
      return null;
    }

    final List<String> currentSet = _bankSets[setIndex];
    if (bankIndex < 0 || bankIndex >= currentSet.length) {
      return null;
    }

    return currentSet[bankIndex];
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0D47A1).withOpacity(0.95),
                    const Color(0xFF1565C0).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
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
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFF90CAF9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFF90CAF9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to log out? You\'ll need to sign in again to connect your bank account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontFamily: 'Onest',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
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
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _logout();
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D47A1),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _logout() async {
    setState(() => _isConnecting = true);

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      _logger.i('Logging out user');

      // Cancel any ongoing Plaid operations
      PlaidLink.close();

      // Clear deep link subscriptions
      _deepLinkSubscription?.cancel();

      // Cancel timers
      _bankCarouselTimer?.cancel();

      // Clear user data from storage
      await storageService.clearAll();

      // Call logout endpoint if available
      try {
        await authService.logout();
        _logger.i('Logout API call successful');
      } catch (e) {
        _logger.w('Error calling logout API: $e');
        // Continue with local logout even if API call fails
      }

      if (mounted) {
        // Navigate to auth screen and clear navigation stack
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      _logger.e('Error during logout: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        // Even if there's an error, try to navigate to auth screen
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }
}
