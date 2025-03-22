import 'dart:ui';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/transactions/domain/models/transaction_category.dart';
import 'package:animate_do/animate_do.dart';
import 'package:blink_app/features/transactions/presentation/widgets/category_selector_sheet.dart';
import 'package:logger/logger.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:blink_app/features/transactions/domain/services/category_service.dart';
import 'package:blink_app/features/transactions/domain/services/merchant_logo_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:blink_app/features/transactions/domain/models/transaction_converter.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  bool _isDarkMode = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchExpanded = false;
  double _scrollOffset = 0;
  double _blurIntensity = 0;
  List<Transaction> _transactions = [];
  Map<String, List<Transaction>> _groupedTransactions = {};
  final DateFormat _dateFormatter = DateFormat('MMMM dd, yyyy');
  final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '\$');

  // Filter states
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedAccount;
  String? _selectedCategory;
  RangeValues? _amountRange;
  String _sortBy = 'date';
  bool _sortAscending = false;

  Timer? _searchDebounce;
  bool _isSearching = false;
  String _lastSearchQuery = '';

  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _blurIntensity = (_scrollOffset / 100).clamp(0, 15);
    });
  }

  Future<void> _loadTransactions() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final transactions = await authService.getAllTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _groupTransactions();
        _isLoading = false;
      });

      // Preload logos in the background for better user experience
      // This won't block the UI since we're not awaiting it
      // Convert transactions to the expected type
      final convertedTransactions = transactions
          .map((t) => TransactionConverter.convertToFeatureTransaction(t))
          .toList();

      MerchantLogoService.preloadLogos(convertedTransactions, _isDarkMode)
          .then((_) => _logger.d('Finished preloading merchant logos'))
          .catchError((e) => _logger.e('Error preloading logos: $e'));
    } catch (e) {
      _logger.e('Error loading all transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Could not load transactions. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _groupTransactions() {
    if (!mounted) return;

    final grouped = <String, List<Transaction>>{};

    for (var transaction in _transactions) {
      final date = _getGroupDate(transaction.date);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    if (!mounted) return;
    setState(() {
      _groupedTransactions = grouped;
    });
  }

  String _getGroupDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else if (date.isAfter(now.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date);
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0A1929) : Colors.grey[50],
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 110,
                  toolbarHeight: 60,
                  backgroundColor:
                      _isDarkMode ? const Color(0xFF0A1929) : Colors.grey[50],
                  flexibleSpace: FlexibleSpaceBar(
                    expandedTitleScale: 1.1,
                    titlePadding: EdgeInsets.only(
                      left: 56,
                      bottom: 16,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 16,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Transactions',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 24,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              icon: _isSearchExpanded
                                  ? Icons.close
                                  : Icons.search,
                              onPressed: () {
                                haptics.Haptics.vibrate(
                                    haptics.HapticsType.light);
                                setState(() {
                                  _isSearchExpanded = !_isSearchExpanded;
                                  if (!_isSearchExpanded) {
                                    _searchController.clear();
                                    _isSearching = false;
                                    _lastSearchQuery = '';
                                    // Only reload transactions if there was an active search
                                    if (_isSearching) {
                                      _loadTransactions();
                                    }
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.tune_rounded,
                              onPressed: () {
                                haptics.Haptics.vibrate(
                                    haptics.HapticsType.light);
                                _showFilterBottomSheet();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _isDarkMode
                              ? [
                                  const Color(0xFF1A2942).withOpacity(0.8),
                                  const Color(0xFF0A1929),
                                ]
                              : [
                                  Colors.white.withOpacity(0.9),
                                  Colors.grey[50]!,
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isSearchExpanded) _buildSearchOverlay(),
                _buildFilterSection(),
                _buildTransactionsList(),
                SliverPadding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: IconButton(
            icon: Icon(
              icon,
              color: _isDarkMode ? Colors.white : Colors.black87,
              size: 18,
            ),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return SliverToBoxAdapter(
      child: FadeInDown(
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
            boxShadow: _isDarkMode
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Make search field clickable even when overlay is active
                  IgnorePointer(
                    ignoring: false,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true, // Auto focus when opened
                      cursorColor: _isDarkMode ? Colors.blue[300] : Colors.blue,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: 'Onest',
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Search by merchant, category, amount, or date...',
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.white60 : Colors.black45,
                          fontFamily: 'Onest',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: _isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                        suffixIcon: _buildSearchingIndicator(),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Found ${_transactions.length} results',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isDarkMode ? Colors.white60 : Colors.black45,
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                Icons.close,
                color: _isDarkMode ? Colors.white60 : Colors.black45,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _isSearching = false;
                  _lastSearchQuery = '';
                  _loadTransactions();
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
    );
  }

  Widget _buildFilterSection() {
    if (_startDate == null &&
        _selectedCategory == null &&
        _selectedAccount == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Filters',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 12,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_startDate != null)
                  _buildFilterChip(
                    label: 'Date: ${DateFormat('MMM d').format(_startDate!)}',
                    onDeleted: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadTransactions();
                    },
                  ),
                if (_selectedCategory != null)
                  _buildFilterChip(
                    label: 'Category: $_selectedCategory',
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                      _loadTransactions();
                    },
                  ),
                if (_selectedAccount != null)
                  _buildFilterChip(
                    label: 'Account: $_selectedAccount',
                    onDeleted: () {
                      setState(() {
                        _selectedAccount = null;
                      });
                      _loadTransactions();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return FadeIn(
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.blue[700],
                      fontSize: 12,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      haptics.Haptics.vibrate(haptics.HapticsType.light);
                      onDeleted();
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: _isDarkMode ? Colors.white70 : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: _buildShimmerLoading(),
      );
    }

    if (_transactions.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: _isDarkMode ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontFamily: 'Onest',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final date = _groupedTransactions.keys.elementAt(index);
          final transactions = _groupedTransactions[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  date,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...transactions
                  .map((transaction) => _buildTransactionItem(transaction)),
            ],
          );
        },
        childCount: _groupedTransactions.length,
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final formattedDate = DateFormat('MMM d, yyyy').format(transaction.date);
    final wholeNumber = transaction.amount.floor();
    final decimal = ((transaction.amount - wholeNumber) * 100)
        .toInt()
        .toString()
        .padLeft(2, '0');
    final formattedWholeNumber = NumberFormat('#,###').format(wholeNumber);

    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (_) {
              haptics.Haptics.vibrate(haptics.HapticsType.medium);
              _showCategoryBottomSheet(transaction);
            },
            backgroundColor: _isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            foregroundColor: _isDarkMode ? Colors.white : Colors.orange[700],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_rounded,
                  color: _isDarkMode ? Colors.white : Colors.orange[700],
                ),
                const SizedBox(height: 4),
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Onest',
                    color: _isDarkMode ? Colors.white : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
                _isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: _isDarkMode
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Replace the category icon with our new method that includes merchant logos
                    _buildMerchantLogoOrCategoryIcon(transaction),
                    const SizedBox(width: 16),

                    // Transaction Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.merchantName ?? 'Unknown Merchant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                              fontFamily: 'Onest',
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CategoryService.getCategoryColor(
                                          transaction.category, _isDarkMode)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  CategoryService.formatDisplayCategory(
                                      transaction.category),
                                  style: TextStyle(
                                    color: CategoryService.getCategoryColor(
                                        transaction.category, _isDarkMode),
                                    fontSize: 12,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: _isDarkMode
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
                                  color: _isDarkMode
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
                                  _isDarkMode
                                      ? Colors.green[400]!
                                      : Colors.green[700]!,
                                  _isDarkMode
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
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantLogoOrCategoryIcon(Transaction transaction) {
    // Temporarily disabled merchant logo fetching for enhancement
    return CategoryService.buildEnhancedCategoryIcon(
        transaction.category, _isDarkMode);

    /* Original implementation:
    // Check if we should attempt to show a logo
    if (!MerchantLogoService.shouldAttemptLogo(transaction.merchantName)) {
      return CategoryService.buildEnhancedCategoryIcon(
          transaction.category, _isDarkMode);
    }

    // Use FutureBuilder to handle async logo URL fetching
    return FutureBuilder<String>(
      // Use the new backend API method
      future: MerchantLogoService.getLogoUrlFromBackend(
        merchantName: transaction.merchantName!,
        type: 'icon',
        width: 60,
        height: 60,
        isDarkMode: _isDarkMode,
      ),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        // If we got a valid URL, show the logo
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.isNotEmpty) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // Add a gradient background that works with both light and dark logos
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isDarkMode
                    ? [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.08)
                      ]
                    : [
                        Colors.grey.withOpacity(0.08),
                        Colors.grey.withOpacity(0.15)
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: snapshot.data!,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    CategoryService.buildEnhancedCategoryIcon(
                        transaction.category, _isDarkMode),
                errorWidget: (context, error, stackTrace) {
                  // Mark as failed to avoid future attempts
                  MerchantLogoService.markDomainAsFailed(
                      transaction.merchantName!);
                  _logger.w(
                      'Failed to load logo for ${transaction.merchantName}: $error');
                  return CategoryService.buildEnhancedCategoryIcon(
                      transaction.category, _isDarkMode);
                },
              ),
            ),
          );
        }

        // While loading or if the URL is empty, show the category icon
        return CategoryService.buildEnhancedCategoryIcon(
            transaction.category, _isDarkMode);
      },
    );
    */
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor:
          _isDarkMode ? Colors.white.withOpacity(0.04) : Colors.grey[300]!,
      highlightColor:
          _isDarkMode ? Colors.white.withOpacity(0.06) : Colors.grey[100]!,
      child: Column(
        children: List.generate(
          8,
          (index) => Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1A2942) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Transactions',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        haptics.Haptics.vibrate(haptics.HapticsType.light);
                        Navigator.pop(context);
                        _resetFilters();
                      },
                      child: Text(
                        'Reset All',
                        style: TextStyle(
                          color:
                              _isDarkMode ? Colors.white70 : Colors.blue[700],
                          fontSize: 16,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Range Filter
                      _buildFilterOptionsSection(
                        title: 'Date Range',
                        icon: Icons.calendar_today,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDateSelector(
                                label: 'From',
                                value: _startDate,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.blue[700]!,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setState(() => _startDate = date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateSelector(
                                label: 'To',
                                value: _endDate,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: _startDate ?? DateTime(2020),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: Colors.blue[700]!,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setState(() => _endDate = date);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Amount Range Filter
                      _buildFilterOptionsSection(
                        title: 'Amount Range',
                        icon: Icons.attach_money,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Min',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  labelStyle: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Onest',
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final min = double.tryParse(value) ?? 0;
                                    final max = _amountRange?.end ?? 1000;
                                    setState(() {
                                      _amountRange = RangeValues(min, max);
                                    });
                                  }
                                },
                                initialValue: _amountRange?.start.toString(),
                                cursorColor: _isDarkMode
                                    ? Colors.blue[300]
                                    : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Max',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  labelStyle: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Onest',
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final min = _amountRange?.start ?? 0;
                                    final max = double.tryParse(value) ?? 1000;
                                    setState(() {
                                      _amountRange = RangeValues(min, max);
                                    });
                                  }
                                },
                                initialValue: _amountRange?.end.toString(),
                                cursorColor: _isDarkMode
                                    ? Colors.blue[300]
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Filter
                      _buildFilterOptionsSection(
                        title: 'Category',
                        icon: Icons.category,
                        child: InkWell(
                          onTap: () {
                            // Show category selection dialog
                            _showCategorySelectionDialog(context, setState);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedCategory ?? 'Select Category',
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontFamily: 'Onest',
                                    fontWeight: _selectedCategory != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: _isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sort By Options
                      _buildFilterOptionsSection(
                        title: 'Sort By',
                        icon: Icons.sort,
                        child: Column(
                          children: [
                            _buildSortOption(
                              label: 'Date',
                              value: 'date',
                              setState: setState,
                            ),
                            const Divider(height: 1),
                            _buildSortOption(
                              label: 'Category',
                              value: 'category',
                              setState: setState,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            haptics.Haptics.vibrate(haptics.HapticsType.medium);
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isDarkMode ? Colors.white : Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply Filters',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.black87 : Colors.white,
                              fontSize: 16,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
  }

  void _showCategorySelectionDialog(
      BuildContext context, StateSetter setState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Select Category',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _isDarkMode ? const Color(0xFF1A2942) : Colors.white,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildCategoryListTile('Groceries', setState),
                _buildCategoryListTile('Restaurants', setState),
                _buildCategoryListTile('Fast Food', setState),
                _buildCategoryListTile('Coffee Shop', setState),
                _buildCategoryListTile('Transportation', setState),
                _buildCategoryListTile('Entertainment', setState),
                _buildCategoryListTile('Airlines', setState),
                _buildCategoryListTile('Utilities', setState),
                _buildCategoryListTile('Shopping', setState),
                _buildCategoryListTile('Dining', setState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontFamily: 'Onest',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryListTile(String category, StateSetter setState) {
    final isSelected = _selectedCategory == category;
    return ListTile(
      title: Text(
        category,
        style: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.black87,
          fontFamily: 'Onest',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Colors.blue[700],
            )
          : null,
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterOptionsSection({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: _isDarkMode ? Colors.white70 : Colors.blue[700],
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 12,
                fontFamily: 'Onest',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null
                      ? DateFormat('MMM d, yyyy').format(value)
                      : 'Select Date',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: _isDarkMode ? Colors.white60 : Colors.blue[700],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String label,
    required String value,
    required StateSetter setState,
  }) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontFamily: 'Onest',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Row(
              children: [
                Text(
                  isSelected
                      ? (_sortAscending ? 'Ascending' : 'Descending')
                      : '',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(width: 4),
                if (isSelected)
                  Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: Colors.blue[700],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1A2942) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CategorySelectorSheet(
            initialCategory: TransactionCategory(
              id: transaction.category ?? 'uncategorized',
              name: transaction.category ?? 'Uncategorized',
              color: Colors.grey,
              icon: Icons.category,
            ),
            onCategorySelected: (category) async {
              Navigator.pop(context);
              // TODO: Implement category update
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category updated to ${category.name}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    try {
      // Get actual transaction information from the transaction itself
      final transactionDate = transaction.date;
      final formattedDate = DateFormat('MMM d, yyyy').format(transactionDate);
      final formattedTime = DateFormat('h:mm a').format(transactionDate);

      // Fetch location data from the database for this transaction
      // Pass the transactionId field instead of id
      _fetchTransactionLocation(transaction.transactionId).then((locationData) {
        if (!mounted) return;

        // Create a TransactionDetail object with useful metadata
        final transactionDetail = TransactionDetail(
          id: transaction.id,
          merchantName: transaction.merchantName,
          amount: transaction.amount,
          date: transaction.date,
          category:
              null, // Set category to null as the expected type is incompatible
          metadata: {
            'pending': false,
            'transaction_id':
                transaction.transactionId, // Store the correct ID here
            'payment_method': 'credit_card', // Default value
            'account_number':
                'xxxx-xxxx-xxxx-${transaction.id}', // Create a masked account number
            'description': transaction.merchantName,
            'category':
                transaction.category, // Store category in metadata instead
            'date': formattedDate,
            'time': formattedTime,
            'status': transaction.isOutflow ? 'Outflow' : 'Inflow',
            'type': transaction.isOutflow ? 'Purchase' : 'Deposit',
            'location': locationData,
          },
        );

        // Navigate to detailed transaction page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsPage(
              transaction: transaction,
              details: transactionDetail,
            ),
          ),
        );
      }).catchError((error) {
        _logger.e('Error fetching transaction location: $error');

        // If we can't get location data, still show the details without it
        final transactionDetail = TransactionDetail(
          id: transaction.id,
          merchantName: transaction.merchantName,
          amount: transaction.amount,
          date: transaction.date,
          category: null,
          metadata: {
            'pending': false,
            'transaction_id':
                transaction.transactionId, // Store the correct ID here too
            'payment_method': 'credit_card',
            'account_number': 'xxxx-xxxx-xxxx-${transaction.id}',
            'description': transaction.merchantName,
            'category': transaction.category,
            'date': formattedDate,
            'time': formattedTime,
            'status': transaction.isOutflow ? 'Outflow' : 'Inflow',
            'type': transaction.isOutflow ? 'Purchase' : 'Deposit',
          },
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsPage(
              transaction: transaction,
              details: transactionDetail,
            ),
          ),
        );
      });
    } catch (e) {
      _logger.e('Error showing transaction details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load transaction details: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchTransactionLocation(
      String transactionId) async {
    // Validate transaction ID format before making the API call
    if (transactionId.isEmpty || transactionId.length < 10) {
      _logger.w('Invalid transaction ID format: $transactionId');
      return _getFallbackLocation();
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // Log the transaction ID being used
      _logger.i('Fetching location for transaction ID: $transactionId');

      // Use the dedicated endpoint for transaction location
      final results =
          await authService.getTransactionLocationFromEndpoint(transactionId);

      _logger.d(
          'Location data retrieved for transaction $transactionId: $results');

      // If we have valid location data, return it
      if (results != null) {
        // The API may return the location data directly or nested in a 'location' key
        if (results.containsKey('location')) {
          _logger.i(
              'Found location data in response for transaction $transactionId');
          return results['location'] as Map<String, dynamic>;
        }
        return results;
      }

      _logger.w(
          'No location data available for transaction $transactionId, using fallback');
      return _getFallbackLocation();
    } catch (e) {
      _logger.e('Error fetching transaction location: $e');
      // Return fallback location if there's an error
      return _getFallbackLocation();
    }
  }

  // Extract fallback location logic to separate method
  Map<String, dynamic> _getFallbackLocation() {
    return {
      'lat': 25.7617,
      'lon': -80.1918,
      'city': 'Miami',
      'region': 'FL',
      'address': '1100 Biscayne Blvd',
      'country': 'US',
      'postal_code': '33132',
    };
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    setState(() {
      _isSearching = query.isNotEmpty;
      if (!_isSearching) {
        _lastSearchQuery = '';
      }
    });

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        setState(() {
          // Reset to showing all transactions
          _loadTransactions();
        });
        return;
      }

      if (query == _lastSearchQuery) return;
      _lastSearchQuery = query;

      setState(() {
        _isLoading = true;
      });

      // Run the search in a separate microtask to avoid UI blocking
      Future.microtask(() {
        // Filter transactions in memory rather than making API calls
        final lowercaseQuery = query.toLowerCase();
        final allTransactions = List<Transaction>.from(_transactions);
        final filteredTransactions = _transactions.where((transaction) {
          // Search in merchant name
          final merchantName = (transaction.merchantName ?? '').toLowerCase();
          if (merchantName.contains(lowercaseQuery)) return true;

          // Search in category
          final category = (transaction.category ?? '').toLowerCase();
          if (category.contains(lowercaseQuery)) return true;

          // Search in amount (both exact and formatted)
          final amount = transaction.amount.toString();
          final formattedAmount =
              _currencyFormatter.format(transaction.amount).toLowerCase();
          if (amount.contains(lowercaseQuery) ||
              formattedAmount.contains(lowercaseQuery)) return true;

          // Search in date (various formats)
          final date = transaction.date;
          final fullDate = DateFormat('MMMM d, y').format(date).toLowerCase();
          final shortDate = DateFormat('MMM d').format(date).toLowerCase();
          final monthYear = DateFormat('MMMM y').format(date).toLowerCase();
          if (fullDate.contains(lowercaseQuery) ||
              shortDate.contains(lowercaseQuery) ||
              monthYear.contains(lowercaseQuery)) return true;

          // Search in relative dates (today, yesterday, etc.)
          final relativeDate = _getGroupDate(date).toLowerCase();
          if (relativeDate.contains(lowercaseQuery)) return true;

          return false;
        }).toList();

        if (mounted) {
          setState(() {
            _transactions = filteredTransactions;
            _groupTransactions();
            _isLoading = false;
          });
        }
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedAccount = null;
      _selectedCategory = null;
      _amountRange = null;
      _sortBy = 'date';
      _sortAscending = false;
    });
    _loadTransactions();
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    // Store all transactions before filtering
    final allTransactions = List<Transaction>.from(_transactions);

    // Apply filters to transactions in memory
    List<Transaction> filteredTransactions = allTransactions;

    // Filter by date range
    if (_startDate != null) {
      filteredTransactions = filteredTransactions.where((t) {
        return t.date.isAfter(_startDate!) ||
            t.date.isAtSameMomentAs(_startDate!);
      }).toList();
    }

    if (_endDate != null) {
      filteredTransactions = filteredTransactions.where((t) {
        return t.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filteredTransactions = filteredTransactions.where((t) {
        return t.category
                ?.toLowerCase()
                .contains(_selectedCategory!.toLowerCase()) ??
            false;
      }).toList();
    }

    // Filter by amount range
    if (_amountRange != null) {
      filteredTransactions = filteredTransactions.where((t) {
        return t.amount >= _amountRange!.start && t.amount <= _amountRange!.end;
      }).toList();
    }

    // Sort the transactions
    if (_sortBy == 'date') {
      filteredTransactions.sort((a, b) =>
          _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    } else if (_sortBy == 'amount') {
      filteredTransactions.sort((a, b) => _sortAscending
          ? a.amount.compareTo(b.amount)
          : b.amount.compareTo(a.amount));
    } else if (_sortBy == 'category') {
      filteredTransactions.sort((a, b) {
        final categoryA = a.category?.toLowerCase() ?? '';
        final categoryB = b.category?.toLowerCase() ?? '';
        return _sortAscending
            ? categoryA.compareTo(categoryB)
            : categoryB.compareTo(categoryA);
      });
    }

    setState(() {
      _transactions = filteredTransactions;
      _groupTransactions();
      _isLoading = false;
    });
  }
}

class TransactionDetailsPage extends StatefulWidget {
  final Transaction transaction;
  final TransactionDetail details;

  const TransactionDetailsPage({
    Key? key,
    required this.transaction,
    required this.details,
  }) : super(key: key);

  @override
  State<TransactionDetailsPage> createState() => _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  MapboxMap? _mapboxMap;
  bool _mapInitialized = false;
  final Logger _logger = Logger(); // Add logger

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A1929) : Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor:
                  isDarkMode ? const Color(0xFF0A1929) : Colors.grey[50],
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => _showOptionsBottomSheet(context, isDarkMode),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with merchant and amount
                    _buildHeader(context, isDarkMode),
                    const SizedBox(height: 32),

                    // Transaction card
                    _buildTransactionCard(context, isDarkMode),
                    const SizedBox(height: 32),

                    // Transaction details section
                    _buildDetailsSection(isDarkMode),
                    const SizedBox(height: 24),

                    // Map view (if location data is available)
                    if (_hasLocationData()) _buildMapSection(isDarkMode),

                    // Additional information
                    if (widget.details.metadata != null &&
                        widget.details.metadata!.isNotEmpty)
                      _buildMetadataSection(isDarkMode),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, isDarkMode),
    );
  }

  bool _hasLocationData() {
    final locationData = widget.details.metadata?['location'];
    return locationData != null &&
        locationData['lat'] != null &&
        locationData['lon'] != null;
  }

  Widget _buildMapSection(bool isDarkMode) {
    final locationData = widget.details.metadata?['location'];
    if (locationData == null) return const SizedBox.shrink();

    final lat = locationData['lat'] as double;
    final lon = locationData['lon'] as double;
    final address = locationData['address'] as String?;
    final city = locationData['city'] as String?;
    final region = locationData['region'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Location',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (address != null)
          Text(
            address,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Onest',
            ),
          ),
        if (city != null && region != null)
          Text(
            '$city, $region',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Onest',
            ),
          ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildMapView(lat, lon),

              // Fallback overlay in case map doesn't load
              if (!_mapInitialized)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black12 : Colors.white70,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 32,
                            color: CategoryService.getCategoryColor(
                                widget.transaction.category, isDarkMode),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Location: $lat, $lon',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 14,
                              fontFamily: 'Onest',
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMapView(double lat, double lon) {
    // Create a simpler map configuration to avoid platform view issues
    return MapWidget(
      key: ValueKey('transaction_map_${widget.transaction.id}'),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(lon, lat),
        ),
        zoom: 15.0,
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Add a slight delay before adding the marker to ensure the map is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMarkerToMap(mapboxMap);
    });
  }

  Future<void> _addMarkerToMap(MapboxMap mapboxMap) async {
    final locationData = widget.details.metadata?['location'];
    if (locationData == null) {
      _logger.w('No location data available for map display');
      return;
    }

    // Validate location data has required fields
    if (!locationData.containsKey('lat') || !locationData.containsKey('lon')) {
      _logger.w('Location data missing latitude or longitude: $locationData');
      return;
    }

    final lat = locationData['lat'] as double;
    final lon = locationData['lon'] as double;

    // Log the coordinates being used for the marker
    _logger.i('Adding map marker at coordinates: $lat, $lon');

    try {
      // Get category color for styling the marker
      final categoryColor = CategoryService.getCategoryColor(
          widget.transaction.category,
          Provider.of<ThemeProvider>(context, listen: false).isDarkMode);

      // Create a circle annotation manager
      final circleAnnotationManager =
          await mapboxMap.annotations.createCircleAnnotationManager();

      // Create circle annotation for the transaction location
      final circleAnnotationOptions = CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(lon, lat),
        ),
        // Style the circle
        circleRadius: 12.0,
        circleColor: categoryColor.value,
        circleStrokeWidth: 2.0,
        circleStrokeColor: Colors.white.value,
      );

      // Add the annotation to the map
      await circleAnnotationManager.create(circleAnnotationOptions);

      // Add a small pulsing effect circle behind the main marker
      final pulseCircleOptions = CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(lon, lat),
        ),
        // Larger, more transparent circle
        circleRadius: 20.0,
        circleColor: categoryColor.withOpacity(0.3).value,
        circleStrokeWidth: 0.0,
      );

      // Add the pulse circle
      await circleAnnotationManager.create(pulseCircleOptions);

      // Move camera to the point - fix the flyTo call
      mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(lon, lat)),
            zoom: 15.0,
          ),
          null // Second parameter is for animation options, null for default animation
          );

      // Mark map as initialized
      setState(() {
        _mapInitialized = true;
      });

      _logger.i('Map marker successfully added at $lat, $lon');
    } catch (e) {
      _logger.e('Error adding marker to map: $e');

      // Still mark as initialized to hide the fallback UI
      setState(() {
        _mapInitialized = true;
      });
    }
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final merchantName = widget.transaction.merchantName ?? 'Unknown Merchant';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Merchant logo temporarily disabled for enhancement
        /* Original implementation:
        if (MerchantLogoService.shouldAttemptLogo(merchantName))
          Center(
            child: FutureBuilder<String>(
              future: MerchantLogoService.getLogoUrlFromBackend(
                merchantName: merchantName,
                type: 'logo', // Use full logo in details view
                width: 160,
                height: 160,
                isDarkMode: isDarkMode,
              ),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                // If no logo URL yet, show a loading spinner
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      // Use gradient background for better logo visibility
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.08)
                              ]
                            : [
                                Colors.grey.withOpacity(0.08),
                                Colors.grey.withOpacity(0.15)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDarkMode
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white60 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // We have a logo URL, display it
                return Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    // Use gradient background for better logo visibility
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.08)
                            ]
                          : [
                              Colors.grey.withOpacity(0.08),
                              Colors.grey.withOpacity(0.15)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: snapshot.data!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, error, stackTrace) {
                        // Mark domain as failed for future requests
                        MerchantLogoService.markDomainAsFailed(merchantName);
                        // Just return empty space if logo fails to load
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        */

        Text(
          merchantName,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 26,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currencyFormatter.format(widget.transaction.amount),
          style: TextStyle(
            color: widget.transaction.isOutflow
                ? Colors.red[400]
                : Colors.green[400],
            fontSize: 36,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (widget.transaction.isOutflow ? Colors.red : Colors.green)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.transaction.isOutflow
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
                color: widget.transaction.isOutflow
                    ? Colors.red[400]
                    : Colors.green[400],
              ),
              const SizedBox(width: 8),
              Text(
                widget.transaction.isOutflow ? 'Money Out' : 'Money In',
                style: TextStyle(
                  color: widget.transaction.isOutflow
                      ? Colors.red[400]
                      : Colors.green[400],
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, bool isDarkMode) {
    // Use either the stored category in metadata or the transaction category
    final displayCategory =
        widget.details.metadata?['category'] ?? widget.transaction.category;
    final categoryColor =
        CategoryService.getCategoryColor(displayCategory, isDarkMode);
    final categoryIcon = CategoryService.getCategoryIcon(displayCategory);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
            isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor,
                              categoryColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CategoryService.formatDisplayCategory(displayCategory),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.details.metadata?['date'] ??
                        DateFormat('MMM d, yyyy')
                            .format(widget.transaction.date),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Transaction Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.details.metadata?['pending'] == true
                          ? Colors.amber.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.details.metadata?['pending'] == true
                          ? 'Pending'
                          : 'Complete',
                      style: TextStyle(
                        color: widget.details.metadata?['pending'] == true
                            ? Colors.amber[800]
                            : Colors.green[600],
                        fontSize: 12,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Payment Method
              if (widget.details.metadata?['payment_method'] != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                    Text(
                      CategoryService.formatPaymentMethod(
                          widget.details.metadata?['payment_method']),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              // Transaction Type
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Type',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                  Text(
                    widget.details.metadata?['type'] ??
                        (widget.transaction.isOutflow ? 'Purchase' : 'Deposit'),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Display date and time
        _buildDetailRow(
            'Date',
            widget.details.metadata?['date'] ??
                DateFormat('MMMM d, yyyy').format(widget.details.date),
            isDarkMode),
        _buildDetailRow(
            'Time',
            widget.details.metadata?['time'] ??
                DateFormat('h:mm a').format(widget.details.date),
            isDarkMode),

        // Display transaction type and status
        _buildDetailRow(
            'Type',
            widget.details.metadata?['type'] ??
                (widget.transaction.isOutflow ? 'Purchase' : 'Deposit'),
            isDarkMode),
        _buildDetailRow(
            'Status',
            widget.details.metadata?['pending'] == true
                ? 'Pending'
                : 'Completed',
            isDarkMode),

        // Display merchant and description
        if (widget.details.metadata?['description'] != null &&
            widget.details.metadata?['description'] !=
                widget.details.merchantName)
          _buildDetailRow('Description',
              widget.details.metadata!['description'], isDarkMode),

        // Display account and transaction ID
        if (widget.details.metadata?['account_number'] != null)
          _buildDetailRow('Account', widget.details.metadata!['account_number'],
              isDarkMode),

        _buildDetailRow(
            'Transaction ID', '#${widget.transaction.id}', isDarkMode),
      ],
    );
  }

  Widget _buildMetadataSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.details.metadata!.entries
            .where((entry) =>
                entry.value != null &&
                ![
                  'description',
                  'pending',
                  'payment_method',
                  'account_number',
                  'transaction_id'
                ].contains(entry.key))
            .map((entry) => _buildDetailRow(
                entry.key.split('_').map((word) => word.capitalize()).join(' '),
                entry.value.toString(),
                isDarkMode))
            .toList(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _reportIssue(context, isDarkMode),
              icon: Icon(
                Icons.flag_outlined,
                color: isDarkMode ? Colors.white70 : Colors.blue[700],
              ),
              label: Text(
                'Report Issue',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.blue[700],
                  fontFamily: 'Onest',
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.blue[700]!.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _changeCategory(context, isDarkMode),
              icon: const Icon(Icons.category_outlined),
              label: const Text(
                'Change Category',
                style: TextStyle(
                  fontFamily: 'Onest',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white : Colors.blue[700],
                foregroundColor: isDarkMode ? Colors.black87 : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionItem(
              context,
              icon: Icons.add_chart,
              title: 'Add to insights',
              subtitle: 'Include in financial analytics',
              iconColor: Colors.purple,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionItem(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Add receipt',
              subtitle: 'Attach a photo of your receipt',
              iconColor: Colors.green,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionItem(
              context,
              icon: Icons.hide_source_outlined,
              title: 'Hide transaction',
              subtitle: 'Remove from list and insights',
              iconColor: Colors.orange,
              isDarkMode: isDarkMode,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontFamily: 'Onest',
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.white60 : Colors.black54,
          fontFamily: 'Onest',
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  void _reportIssue(BuildContext context, bool isDarkMode) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue reporting feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _changeCategory(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CategorySelectorSheet(
            initialCategory: TransactionCategory(
              id: widget.transaction.category ?? 'uncategorized',
              name: widget.transaction.category ?? 'Uncategorized',
              color: Colors.grey,
              icon: Icons.category,
            ),
            onCategorySelected: (category) {
              Navigator.pop(context);
              _updateCategory(context, category);
            },
          ),
        ),
      ),
    );
  }

  void _updateCategory(BuildContext context, TransactionCategory category) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category updated to ${category.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
