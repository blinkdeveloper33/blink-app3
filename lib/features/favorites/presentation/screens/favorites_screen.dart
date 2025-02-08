import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/services/auth_service.dart' as auth;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _iconController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  bool _isDarkMode = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _topMerchants = [];
  List<Map<String, dynamic>> _inflowProviders = [];
  Map<String, dynamic>? _mostExpensiveCategory;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.i('Initializing FavoritesScreen');
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _loadTransactionAnalysis();
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionAnalysis() async {
    _logger.i('Loading transaction analysis...');
    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      _logger.d('AuthService provider obtained');

      final analysis = await authService.getTransactionAnalysis();
      _logger.d('Transaction analysis response: ${analysis.toString()}');

      if (!mounted) {
        _logger.w('Widget no longer mounted, skipping setState');
        return;
      }

      setState(() {
        _topMerchants =
            List<Map<String, dynamic>>.from(analysis['topMerchants']);
        _inflowProviders =
            List<Map<String, dynamic>>.from(analysis['inflowProviders']);
        _mostExpensiveCategory = analysis['mostExpensiveCategory'];
        _isLoading = false;
      });

      _logger.i('Transaction analysis loaded successfully');
    } catch (e, stackTrace) {
      _logger.e('Error loading transaction analysis',
          error: e, stackTrace: stackTrace);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load transaction analysis: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadTransactionAnalysis();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF4A90E2), // Professional blue
      const Color(0xFF9B51E0), // Royal purple
      const Color(0xFF43A047), // Forest green
      const Color(0xFFE67E22), // Warm orange
      const Color(0xFF26A69A), // Teal
      const Color(0xFFEC407A), // Rose
    ];
    return colors[index % colors.length];
  }

  Widget _buildMerchantCard(Map<String, dynamic> merchant, int index) {
    final color = _getColorForIndex(index);
    final frequency = merchant['frequency'];
    final merchantName = merchant['merchant_name'] as String;

    return FadeInUp(
      duration: Duration(milliseconds: 200 + (index * 50)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.black12 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        merchantName[0].toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          merchantName,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monthly visits',
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white60 : Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      frequency.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInflowProviderCard(Map<String, dynamic> provider, int index) {
    final color = _getColorForIndex(index);
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final amount = provider['total_amount'] as num;
    final providerName = provider['provider'] as String;

    return FadeInUp(
      duration: Duration(milliseconds: 200 + (index * 50)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.black12 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bounceAnimation.value),
                          child: Icon(
                            Icons.arrow_circle_down_rounded,
                            color: color,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          providerName,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monthly income',
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white60 : Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostExpensiveCategoryCard() {
    if (_mostExpensiveCategory == null) return const SizedBox.shrink();

    final color = Colors.redAccent;
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final amount = _mostExpensiveCategory!['total_amount'] as num;
    final category = _mostExpensiveCategory!['category'] as String;

    return FadeInUp(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.black12 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            color: color,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Top Category',
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white60 : Colors.black45,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currencyFormatter.format(amount),
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;
    final screenSize = MediaQuery.of(context).size;

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
              child: Container(
                width: screenSize.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.8,
                  maxWidth: 500,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Highlights',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              haptics.Haptics.vibrate(
                                  haptics.HapticsType.light);
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color:
                                  _isDarkMode ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMostExpensiveCategoryCard(),
                              Text(
                                'Most Frequent',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._topMerchants.asMap().entries.map(
                                    (entry) => _buildMerchantCard(
                                        entry.value, entry.key),
                                  ),
                              const SizedBox(height: 20),
                              Text(
                                'Income',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._inflowProviders.asMap().entries.map(
                                    (entry) => _buildInflowProviderCard(
                                        entry.value, entry.key),
                                  ),
                            ],
                          ),
                        ),
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
