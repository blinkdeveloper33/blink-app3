import 'package:flutter/material.dart';
import 'package:blink_app/services/auth_service.dart' as auth;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:blink_app/features/transactions/domain/models/transaction.dart';
import 'package:blink_app/features/transactions/domain/services/category_service.dart';
import 'package:blink_app/features/transactions/presentation/screens/all_transactions_screen.dart';
import 'package:blink_app/utils/temp_localizations.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;

class RecentTransactionsSection extends StatefulWidget {
  final bool isDarkMode;
  final Function(haptics.HapticsType) onHapticFeedback;
  final Function(Transaction) onViewTransactionDetails;

  const RecentTransactionsSection({
    Key? key,
    required this.isDarkMode,
    required this.onHapticFeedback,
    required this.onViewTransactionDetails,
  }) : super(key: key);

  @override
  State<RecentTransactionsSection> createState() =>
      _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState extends State<RecentTransactionsSection> {
  final Logger _logger = Logger();
  bool _isLoading = false;
  List<auth.Transaction> _recentTransactions = [];
  final NumberFormat currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  Future<void> _loadRecentTransactions() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final transactions = await authService.getLatestTransactions();

      if (!mounted) return;

      setState(() {
        _recentTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading recent transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load recent transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Convert auth.Transaction to domain Transaction
  Transaction _convertAuthTransaction(auth.Transaction authTransaction) {
    return Transaction(
      id: authTransaction.id,
      merchantName: authTransaction.merchantName,
      amount: authTransaction.amount,
      date: authTransaction.date,
      category: authTransaction.category,
      isOutflow: authTransaction.isOutflow,
      status: 'Completed', // Default status
      description: null,
      metadata: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isDarkMode ? Colors.white70 : Colors.blue[700]!,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      localizations.recent_transactions,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            Localizations.localeOf(context).languageCode == 'es'
                                ? 20
                                : 24,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    localizations.latest_financial_activities,
                    style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                ],
              ),
            ),
            // Enhanced View All Button
            Container(
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400.withOpacity(0.2),
                    Colors.purple.shade400.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onHapticFeedback(haptics.HapticsType.light);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllTransactionsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          localizations.view_all,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.blue.shade700,
                            fontSize: 14,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.blue.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Enhanced Transaction List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _recentTransactions.length,
          itemBuilder: (context, index) {
            final transaction = _recentTransactions[index];
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: safeOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildEnhancedTransactionItem(transaction, index),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedTransactionItem(
      auth.Transaction transaction, int index) {
    final formattedDate = DateFormat('MMM d, yyyy').format(transaction.date);
    final wholeNumber = transaction.amount.floor();
    final decimal = ((transaction.amount - wholeNumber) * 100)
        .toInt()
        .toString()
        .padLeft(2, '0');
    final formattedWholeNumber = NumberFormat('#,###').format(wholeNumber);
    final domainTransaction = _convertAuthTransaction(transaction);

    return GestureDetector(
      onTapDown: (_) => widget.onHapticFeedback(haptics.HapticsType.light),
      onTap: () => widget.onViewTransactionDetails(domainTransaction),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
              widget.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon with Gradient Border - Using CategoryService
              CategoryService.buildEnhancedCategoryIcon(
                  domainTransaction.category, widget.isDarkMode),
              const SizedBox(width: 16),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchantName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: 'Onest',
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: CategoryService.getCategoryColor(
                                    domainTransaction.category,
                                    widget.isDarkMode)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            CategoryService.formatDisplayCategory(
                                domainTransaction.category),
                            style: TextStyle(
                              color: CategoryService.getCategoryColor(
                                  domainTransaction.category,
                                  widget.isDarkMode),
                              fontSize: 12,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white38
                                  : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode
                                ? Colors.white60
                                : Colors.black54,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount with Gradient Effect
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: transaction.isOutflow
                        ? [Colors.red[400]!, Colors.red[300]!]
                        : [
                            widget.isDarkMode
                                ? Colors.green[400]!
                                : Colors.green[700]!,
                            widget.isDarkMode
                                ? Colors.green[300]!
                                : Colors.green[600]!,
                          ],
                  ).createShader(bounds),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Onest',
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: formattedWholeNumber,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Onest',
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: '.$decimal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Onest',
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to refresh transactions data from outside
  Future<void> refreshTransactions() async {
    return _loadRecentTransactions();
  }
}
