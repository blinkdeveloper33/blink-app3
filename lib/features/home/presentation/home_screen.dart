import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart' show AuthService, Transaction;
import 'package:myapp/services/storage_service.dart';
import 'dart:async';
import 'package:myapp/features/account/presentation/account_screen.dart';
import 'package:logger/logger.dart';
import 'package:myapp/features/blink_advance/presentation/blink_advance_screen.dart';
import 'package:myapp/utils/custom_page_route.dart';
import 'package:flutter/animation.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String bankAccountId;

  const HomeScreen(
      {super.key, required this.userName, required this.bankAccountId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _logger = Logger();
  bool _isDarkMode = true;
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  List<Transaction> _recentTransactions = [];
  Map<String, dynamic> _balances = {};
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _userName = '';
  String _bankAccountId = '';
  String? _primaryAccountName;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _bankAccountId = widget.bankAccountId;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.reset();
    _loadData();
    _loadBankAccountName();
    _fetchAndStoreDetailedBankAccounts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([
      _loadRecentTransactions(),
      _loadCurrentBalances(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRecentTransactions() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    try {
      final userId = storageService.getUserId();
      if (userId != null) {
        final transactions = await authService.getRecentTransactions(userId);
        setState(() {
          _recentTransactions = transactions;
        });
      } else {
        throw Exception('User ID not found');
      }
    } catch (e) {
      _logger.e('Error loading recent transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load recent transactions. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCurrentBalances() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final balances = await authService.getCurrentBalances();
      if (mounted) {
        setState(() {
          _balances = balances;
          _isLoading = false;
          _primaryAccountName = balances['primaryAccountName'] as String?;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      _logger.e('Error loading current balances: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load current balances. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBankAccountName() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    final userId = storageService.getUserId();
    if (userId != null) {
      final primaryAccountName =
          await authService.getPrimaryAccountName(userId);
      if (primaryAccountName != null) {
        await storageService.setPrimaryAccountName(primaryAccountName);
      }
    }

    if (mounted) {
      setState(() {
        _primaryAccountName =
            storageService.getPrimaryAccountName() ?? 'Primary Account';
      });
    }
  }

  Future<void> _fetchAndStoreDetailedBankAccounts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    try {
      final detailedBankAccounts = await authService.getDetailedBankAccounts();
      await storageService.setDetailedBankAccounts(detailedBankAccounts);
      _logger.i('Detailed bank accounts fetched and stored successfully');
    } catch (e) {
      _logger.e('Error fetching detailed bank accounts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to fetch bank account details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getDayContext() {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    return "How's your $dayName going so far?";
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AccountScreen()),
            );
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDarkMode ? Colors.white24 : Colors.grey[300],
                ),
                child: Icon(
                  Icons.person,
                  color: _isDarkMode ? Colors.white : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_getGreeting()}, ',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                          fontFamily: 'Onest',
                        ),
                      ),
                      Text(
                        _userName,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _getDayContext(),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isDarkMode ? Colors.white24 : Colors.grey[300],
            ),
            child: Icon(
              _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: _isDarkMode ? Colors.white : Colors.black54,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    final dynamic rawBalance = _balances['totalBalance'];
    final double totalBalance = rawBalance == null
        ? 0.0
        : (rawBalance is int ? rawBalance.toDouble() : rawBalance as double);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Blink Financial Summary",
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
              fontSize: 20,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Total Balance',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final animatedBalance = totalBalance * _animation.value;
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '\$',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 32,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${currencyFormatter.format(animatedBalance).split('.')[0].substring(1)}.',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 32,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${currencyFormatter.format(animatedBalance).split('.')[1]}',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 22,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Primary Account:',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _primaryAccountName ?? 'Not Available',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _handleBlinkAdvanceTap,
              child: Hero(
                tag: 'blinkAdvanceCard',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Color(0xFF2196F3),
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Blink Advance',
                        style: TextStyle(
                          color: Color(0xFF1A1F36),
                          fontSize: 24,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Eligibility for Blink',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontFamily: 'Onest',
                        ),
                      ),
                      const Text(
                        'Advance: On Review!',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'Know more',
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 14,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Color(0xFF2196F3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Color(0xFF2196F3),
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Repayment',
                          style: TextStyle(
                            color: Color(0xFF1A1F36),
                            fontSize: 18,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Repayment Calendar',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.insights,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Review Insights',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBlinkAdvanceTap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BlinkAdvanceScreen(bankAccountId: _bankAccountId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'transportation':
        return Icons.directions_car;
      case 'finance':
        return Icons.account_balance;
      case 'dining':
        return Icons.restaurant;
      case 'utilities':
        return Icons.power;
      default:
        return Icons.attach_money;
    }
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final formattedAmount = currencyFormatter.format(transaction.amount.abs());
    final formattedDate = DateFormat('dd MMM, yyyy').format(transaction.date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isDarkMode ? Colors.white24 : Colors.grey[200],
            ),
            child: Icon(
              _getCategoryIcon(transaction.category ?? ''),
              color: _isDarkMode ? Colors.white : Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchantName,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category ?? 'Uncategorized',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                    fontFamily: 'Onest',
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.isOutflow ? '-$formattedAmount' : '+$formattedAmount',
            style: TextStyle(
              color: transaction.isOutflow ? Colors.red : Colors.green,
              fontSize: 16,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See all',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recentTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No recent transactions',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                        fontFamily: 'Onest',
                      ),
                    ),
                  )
                : Column(
                    children: _recentTransactions
                        .map(
                            (transaction) => _buildTransactionItem(transaction))
                        .toList(),
                  ),
      ],
    );
  }

  Widget _buildNewsAndUpdates() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'News & Updates',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See all',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDarkMode ? Colors.white24 : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  'assets/images/roth_ira_vs_401k.png',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roth IRA vs. 401(k): What\'s the Difference?',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Both Roth IRAs and 401(k)s are popular tax-advantaged retirement savings accounts that allow your savings to g...',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF061535) : Colors.grey[100],
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) {
            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildFinancialSummary(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 32),
                      _buildRecentTransactions(),
                      const SizedBox(height: 32),
                      _buildNewsAndUpdates(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
