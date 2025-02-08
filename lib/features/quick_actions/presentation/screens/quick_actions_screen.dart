import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/blink_advance/presentation/blink_advance_screen.dart';
import 'package:blink_app/features/transactions/presentation/screens/all_transactions_screen.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/services/auth_service.dart' as auth;
import 'package:blink_app/services/storage_service.dart';

class QuickActionsScreen extends StatefulWidget {
  const QuickActionsScreen({Key? key}) : super(key: key);

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isDarkMode = false;
  bool _isBlinkAdvanceApproved = false;
  bool _hasActiveAdvance = false;
  String _bankAccountId = '';
  bool _isCheckingEligibility = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  void _handleQuickAction(String action) async {
    haptics.Haptics.vibrate(haptics.HapticsType.medium);

    switch (action) {
      case 'instant_cash':
        setState(() => _isCheckingEligibility = true);

        try {
          final authService =
              Provider.of<auth.AuthService>(context, listen: false);
          final storageService =
              Provider.of<StorageService>(context, listen: false);

          final status = await authService.getBlinkAdvanceApprovalStatus();
          final activeAdvanceResponse =
              await authService.getActiveBlinkAdvance();
          final bankAccountId = storageService.getBankAccountId();

          _isBlinkAdvanceApproved = status['isApproved'] ?? false;
          _hasActiveAdvance =
              activeAdvanceResponse['hasActiveAdvance'] ?? false;
          _bankAccountId = bankAccountId ?? '';

          if (_hasActiveAdvance || _isBlinkAdvanceApproved) {
            if (mounted) {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FadeTransition(
                    opacity: animation,
                    child: BlinkAdvanceScreen(bankAccountId: _bankAccountId),
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              final String message = status['status']?.toLowerCase() ==
                      'on review'
                  ? 'Your Blink Advance application is currently under review. This typically takes 1-2 business days. We\'ll notify you once a decision has been made.'
                  : 'You are not currently eligible for Blink Advance. Our system will automatically notify you when you become eligible.';

              final BuildContext currentContext = context;
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        status['status']?.toLowerCase() == 'on review'
                            ? Icons.pending_outlined
                            : Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontFamily: 'Onest',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor:
                      status['status']?.toLowerCase() == 'on review'
                          ? Colors.orange[700]
                          : Colors.red[700],
                  duration: const Duration(seconds: 6),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  action: status['status']?.toLowerCase() == 'on review'
                      ? SnackBarAction(
                          label: 'Got it',
                          textColor: Colors.white,
                          onPressed: () {
                            if (mounted) {
                              ScaffoldMessenger.of(currentContext)
                                  .hideCurrentSnackBar();
                            }
                          },
                        )
                      : null,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            final BuildContext currentContext = context;
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Unable to check eligibility. Please try again later.',
                        style: TextStyle(
                          fontFamily: 'Onest',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isCheckingEligibility = false);
          }
        }
        break;

      case 'view_transactions':
        Navigator.of(context).pop();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FadeTransition(
              opacity: animation,
              child: const AllTransactionsScreen(),
            ),
          ),
        );
        break;
    }
  }

  Widget _buildQuickActionButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int index,
  }) {
    final bool isInstantCash = title == 'Instant Cash';
    final bool isLoading = isInstantCash && _isCheckingEligibility;

    return FadeInUp(
      duration: Duration(milliseconds: 200 + (index * 100)),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoading ? 'Checking eligibility...' : description,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: _isDarkMode
                  ? const Color(0xFF1A2942).withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 24,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            haptics.Haptics.vibrate(haptics.HapticsType.light);
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color:
                                _isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildQuickActionButton(
                      title: 'Instant Cash',
                      description: 'Get instant cash advance',
                      icon: Icons.bolt_rounded,
                      color: Colors.blue,
                      onTap: () => _handleQuickAction('instant_cash'),
                      index: 0,
                    ),
                    _buildQuickActionButton(
                      title: 'View Transactions',
                      description: 'See all your transactions',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.orange,
                      onTap: () => _handleQuickAction('view_transactions'),
                      index: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
