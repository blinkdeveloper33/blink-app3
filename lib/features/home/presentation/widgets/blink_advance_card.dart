import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/services/auth_service.dart' as auth;
import 'package:animated_emoji/animated_emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:blink_app/features/blink_advance/presentation/splash/blink_advance_splash_screen.dart';
import 'package:blink_app/features/transactions/presentation/screens/all_transactions_screen.dart';

class BlinkAdvanceCard extends StatefulWidget {
  final String bankAccountId;
  final bool isDarkMode;
  final Function(Map<String, dynamic>?) onAdvanceDataUpdated;
  final Function(haptics.HapticsType) onHapticFeedback;

  const BlinkAdvanceCard({
    Key? key,
    required this.bankAccountId,
    required this.isDarkMode,
    required this.onAdvanceDataUpdated,
    required this.onHapticFeedback,
  }) : super(key: key);

  @override
  State<BlinkAdvanceCard> createState() => _BlinkAdvanceCardState();
}

class _BlinkAdvanceCardState extends State<BlinkAdvanceCard>
    with SingleTickerProviderStateMixin {
  // State variables moved from HomeScreen
  bool _isBlinkAdvanceApproved = false;
  String _blinkAdvanceStatus = 'On Review';
  bool _isBlinkAdvanceLoading = false;
  bool _isBlinkAdvanceExpanded = false;
  bool _hasActiveAdvance = false;
  Map<String, dynamic>? _activeAdvance;
  Map<String, dynamic>? _activeAdvanceData;
  Timer? _blinkAdvanceStatusTimer;

  // Animation controllers
  late AnimationController _emojiAnimationController;
  late Animation<double> _emojiAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBlinkAdvanceStatus();

    // Set up periodic status check every 30 seconds
    _blinkAdvanceStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadBlinkAdvanceStatus();
    });
  }

  @override
  void dispose() {
    _emojiAnimationController.dispose();
    _blinkAdvanceStatusTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _emojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _emojiAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _emojiAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadBlinkAdvanceStatus() async {
    if (!mounted) return;

    try {
      setState(() {
        _isBlinkAdvanceLoading = true;
      });

      final authService = Provider.of<auth.AuthService>(context, listen: false);

      // Check approval status
      final approvalResponse =
          await authService.getBlinkAdvanceApprovalStatus();

      if (!mounted) return;

      // Handle the approval status response
      if (approvalResponse != null) {
        setState(() {
          try {
            // The response contains: {"userId":"user-id-here","approvalStatus":"approved"}
            final status = approvalResponse['approvalStatus'];

            _isBlinkAdvanceApproved =
                status?.toString().toLowerCase() == 'approved';
            _blinkAdvanceStatus =
                _isBlinkAdvanceApproved ? 'Approved' : 'On Review';
            _hasActiveAdvance = false;
            _activeAdvance = null;
          } catch (e) {
            _isBlinkAdvanceApproved = false;
            _blinkAdvanceStatus = 'Error';
            _hasActiveAdvance = false;
            _activeAdvance = null;
          } finally {
            _isBlinkAdvanceLoading = false;
          }
        });
        return;
      }

      setState(() {
        _isBlinkAdvanceApproved = false;
        _blinkAdvanceStatus = 'On Review';
        _hasActiveAdvance = false;
        _activeAdvance = null;
        _isBlinkAdvanceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isBlinkAdvanceApproved = false;
        _blinkAdvanceStatus = 'Error';
        _hasActiveAdvance = false;
        _activeAdvance = null;
        _isBlinkAdvanceLoading = false;
      });
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;

    final words = text.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalizedWords.join(' ');
  }

  Widget _getStatusEmoji() {
    String emoji;
    if (_hasActiveAdvance) {
      emoji = '✅';
    } else {
      switch (_blinkAdvanceStatus.toLowerCase()) {
        case 'reviewing':
          emoji = '🕒';
          break;
        case 'approved':
          emoji = '✅';
          break;
        case 'rejected':
          emoji = '❌';
          break;
        default:
          emoji = '';
          break;
      }
    }

    // Use a proportional container size based on screen width
    final size = MediaQuery.of(context).size.width * 0.05;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.7),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _handleBlinkAdvanceTap() {
    widget.onHapticFeedback(haptics.HapticsType.medium);

    if (_hasActiveAdvance || _isBlinkAdvanceApproved) {
      Navigator.of(context)
          .push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return BlinkAdvanceSplashScreen(
                bankAccountId: widget.bankAccountId);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      )
          .then((result) {
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _activeAdvanceData = result;

            // Check for has_active_advance flag
            if (result.containsKey('has_active_advance')) {
              _hasActiveAdvance = result['has_active_advance'] == true;
            } else {
              // Default to true if the flag is not present but we have advance data
              _hasActiveAdvance = true;
            }

            // Update the status based on quick_action_status if present
            if (result.containsKey('quick_action_status')) {
              String newStatus = result['quick_action_status'].toString();
              _blinkAdvanceStatus = newStatus.isNotEmpty
                  ? _capitalizeFirstLetter(newStatus.replaceAll('_', ' '))
                  : 'Approved';
            }
          });

          // Inform parent about the updated data
          widget.onAdvanceDataUpdated(_activeAdvanceData);
        }
      });
    }
  }

  Widget _buildCollapsedBlinkAdvanceContent() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;

    // Use relative sizing for better adaptability
    final double emojiSize = screenWidth * 0.12;
    final double logoHeight = screenWidth * 0.075;
    final double fontSize = screenWidth * 0.06;
    final double statusFontSize = screenWidth * 0.035;
    final double iconSize = screenWidth * 0.04;
    final double spacing = screenHeight * 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: AnimatedBuilder(
                    animation: _emojiAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _emojiAnimation.value,
                        child: AnimatedEmoji(
                          AnimatedEmojis.electricity,
                          size: emojiSize,
                          repeat: true,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        const Spacer(),
        // Replace existing logo and text with a 2-row layout
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blink logo from network URL
            Image.network(
              widget.isDarkMode
                  ? 'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/assets//BLINK-03-removebg-preview%202.png'
                  : 'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/assets//blinklogo.png',
              height: logoHeight,
              // Add error and loading placeholder handlers
              errorBuilder: (context, error, stackTrace) {
                return SvgPicture.asset(
                  widget.isDarkMode
                      ? 'assets/images/blink-logo2.svg'
                      : 'assets/images/blink-logo3.svg',
                  height: logoHeight,
                  colorFilter: ColorFilter.mode(
                    widget.isDarkMode ? Colors.white : Colors.blue[800]!,
                    BlendMode.srcIn,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: logoHeight,
                  width: logoHeight * 2.67,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color:
                          widget.isDarkMode ? Colors.white : Colors.blue[800],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: spacing),
            // Just "Advance" text
            Text(
              'Advance',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.blue[800],
                fontSize: fontSize,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status:',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: statusFontSize,
                fontFamily: 'Onest',
              ),
            ),
            SizedBox(height: spacing / 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.025,
                        vertical: screenHeight * 0.005),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.blue.withOpacity(0.25)
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            // If has active advance and the status is 'requested', show 'Requested'
                            // Otherwise, use Active for active advances, or _blinkAdvanceStatus for other states
                            _hasActiveAdvance
                                ? (_blinkAdvanceStatus.toLowerCase() ==
                                        'requested'
                                    ? 'Requested'
                                    : 'Active')
                                : _blinkAdvanceStatus,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.blue[800],
                              fontSize: statusFontSize,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        _getStatusEmoji(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Know more',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: statusFontSize,
                fontFamily: 'Onest',
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    decoration: BoxDecoration(
                      color:
                          widget.isDarkMode ? Colors.white : Colors.blue[800],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward,
                        color: widget.isDarkMode
                            ? const Color(0xFF141B2E)
                            : Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth * 0.035;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Icon(
              _hasActiveAdvance ? Icons.check_circle : Icons.pending,
              color: widget.isDarkMode ? Colors.white : Colors.blue[800],
              size: screenWidth * 0.045,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                    fontSize: fontSize * 0.85,
                    fontFamily: 'Onest',
                  ),
                ),
                SizedBox(height: screenWidth * 0.005),
                Flexible(
                  child: Text(
                    _hasActiveAdvance ? 'Active' : _blinkAdvanceStatus,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                      fontSize: fontSize,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _getStatusEmoji(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth * 0.035;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _hasActiveAdvance ? 'Active Advance' : 'Application Status',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontSize: fontSize,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            _hasActiveAdvance
                ? 'You have an active advance. Make sure to repay on time.'
                : 'Review takes 1-2 business days.',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: fontSize * 0.85,
              fontFamily: 'Onest',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = screenWidth * 0.035;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            widget.onHapticFeedback(haptics.HapticsType.medium);
            if (_hasActiveAdvance || _isBlinkAdvanceApproved) {
              Navigator.of(context)
                  .push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      BlinkAdvanceSplashScreen(
                          bankAccountId: widget.bankAccountId),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  // Disable swipe back gesture
                  settings: const RouteSettings(name: '/blink-advance'),
                  opaque: true,
                  barrierDismissible: false,
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              )
                  .then((result) {
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    _activeAdvanceData = result;

                    // Check for has_active_advance flag
                    if (result.containsKey('has_active_advance')) {
                      _hasActiveAdvance = result['has_active_advance'] == true;
                    } else {
                      // Default to true if the flag is not present but we have advance data
                      _hasActiveAdvance = true;
                    }

                    // Update the status based on quick_action_status if present
                    if (result.containsKey('quick_action_status')) {
                      String newStatus =
                          result['quick_action_status'].toString();
                      _blinkAdvanceStatus = newStatus.isNotEmpty
                          ? _capitalizeFirstLetter(
                              newStatus.replaceAll('_', ' '))
                          : 'Approved';
                    }
                  });

                  // Pass data up to parent
                  widget.onAdvanceDataUpdated(_activeAdvanceData);
                }
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                widget.isDarkMode ? Colors.white : Colors.blue[800],
            foregroundColor:
                widget.isDarkMode ? Colors.blue[800] : Colors.white,
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
          ),
          child: Text(
            _hasActiveAdvance
                ? 'View Details'
                : _isBlinkAdvanceApproved
                    ? 'Apply Now'
                    : 'Check Status',
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        TextButton(
          onPressed: () {
            widget.onHapticFeedback(haptics.HapticsType.light);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllTransactionsScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
          ),
          child: Text(
            'Contact Support',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.blue[800],
              fontSize: fontSize * 0.85,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedBlinkAdvanceContent() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = screenHeight * 0.08;
    final double logoHeight = headerHeight * 0.35;
    final double titleFontSize = screenWidth * 0.045;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with safe area considerations
              SizedBox(
                height: headerHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'blink-logo',
                            child: Image.network(
                              widget.isDarkMode
                                  ? 'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/assets//BLINK-03-removebg-preview%202.png'
                                  : 'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/assets//blinklogo.png',
                              height: logoHeight,
                              // Add error and loading placeholder handlers
                              errorBuilder: (context, error, stackTrace) {
                                return SvgPicture.asset(
                                  widget.isDarkMode
                                      ? 'assets/images/blink-logo2.svg'
                                      : 'assets/images/blink-logo3.svg',
                                  height: logoHeight,
                                  colorFilter: ColorFilter.mode(
                                    widget.isDarkMode
                                        ? Colors.white
                                        : Colors.blue[800]!,
                                    BlendMode.srcIn,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  height: logoHeight,
                                  width: logoHeight * 2.67,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      strokeWidth: 2,
                                      color: widget.isDarkMode
                                          ? Colors.white
                                          : Colors.blue[800],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          Text(
                            'Advance',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.blue[800],
                              fontSize: titleFontSize,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 24,
                      ),
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.blue[800],
                      onPressed: () {
                        widget.onHapticFeedback(haptics.HapticsType.light);
                        setState(() {
                          _isBlinkAdvanceExpanded = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Content section with flexible layout
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      _buildStatusSection(),
                      SizedBox(height: screenHeight * 0.02),
                      _buildInfoSection(),
                      SizedBox(height: screenHeight * 0.02),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Determine card colors
    final cardStartColor = widget.isDarkMode
        ? const Color(0xFF141B2E)
        : const Color(0xFFDBEBFF); // Slightly darker blue in light mode
    final cardEndColor = widget.isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFC2DAFF); // Slightly darker gradient end in light mode

    // Calculate responsive padding
    final double paddingHorizontal = screenWidth * 0.06;
    final double paddingVertical = screenHeight * 0.025;

    // Card content
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardStartColor, cardEndColor],
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(
          width: 0.5,
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.blue.withOpacity(0.15),
            blurRadius: screenWidth * 0.03,
            spreadRadius: 1,
            offset: Offset(0, screenHeight * 0.005),
          ),
          // Secondary inner highlight for more depth
          BoxShadow(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.7),
            blurRadius: 3,
            spreadRadius: 0,
            offset: Offset(0, screenHeight * 0.001),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          onTap: _handleBlinkAdvanceTap,
          splashColor: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.blue.withOpacity(0.05),
          highlightColor: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.blue.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: paddingHorizontal, vertical: paddingVertical),
            child: _isBlinkAdvanceExpanded
                ? _buildExpandedBlinkAdvanceContent()
                : _buildCollapsedBlinkAdvanceContent(),
          ),
        ),
      ),
    );
  }
}
