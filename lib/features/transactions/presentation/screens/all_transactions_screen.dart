import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
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
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
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

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.getAllTransactionsPaginated(
        page: _currentPage,
        limit: 50,
      );

      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final transactions = (response['data']['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();

        if (!mounted) return;

        setState(() {
          _transactions = transactions;
          _hasMoreData = transactions.length == 50;
          _groupTransactions();
        });
      }
    } catch (e) {
      // TODO: Handle error
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreData || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.getAllTransactionsPaginated(
        page: _currentPage + 1,
        limit: 50,
      );

      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final newTransactions = (response['data']['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();

        if (!mounted) return;

        setState(() {
          _transactions.addAll(newTransactions);
          _currentPage++;
          _hasMoreData = newTransactions.length == 50;
          _groupTransactions();
        });
      }
    } catch (e) {
      // TODO: Handle error
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
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
                                    _loadTransactions();
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
            if (_isSearchExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchExpanded = false;
                      _searchController.clear();
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
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
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
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
                      suffixIcon: _isSearching
                          ? _buildSearchingIndicator()
                          : const SizedBox.shrink(),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
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
                });
                _loadTransactions();
              },
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
            color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
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
                    _buildCategoryIcon(transaction),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.merchantName ?? 'Unknown Merchant',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  transaction.category ?? 'Uncategorized',
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 12,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormatter.format(transaction.amount),
                          style: TextStyle(
                            color: transaction.isOutflow
                                ? (_isDarkMode
                                    ? Colors.red[300]
                                    : Colors.red[700])
                                : (_isDarkMode
                                    ? Colors.green[300]
                                    : Colors.green[700]),
                            fontSize: 16,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(transaction.date),
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
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

  Widget _buildCategoryIcon(Transaction transaction) {
    IconData iconData;
    Color iconColor;

    switch (transaction.category?.toLowerCase() ?? 'uncategorized') {
      case 'groceries':
        iconData = Icons.shopping_cart;
        iconColor = Colors.green;
        break;
      case 'transportation':
        iconData = Icons.directions_car;
        iconColor = Colors.blue;
        break;
      case 'entertainment':
        iconData = Icons.movie;
        iconColor = Colors.purple;
        break;
      case 'dining':
        iconData = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case 'utilities':
        iconData = Icons.power;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.category_outlined;
        iconColor = _isDarkMode ? Colors.white70 : Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
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
                        'Reset',
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
                      _buildFilterOptionsSection(
                        title: 'Date Range',
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDateSelector(
                                label: 'Start Date',
                                value: _startDate,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
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
                                label: 'End Date',
                                value: _endDate,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: _startDate ?? DateTime(2020),
                                    lastDate: DateTime.now(),
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
                      _buildFilterOptionsSection(
                        title: 'Amount Range',
                        child: Column(
                          children: [
                            RangeSlider(
                              values:
                                  _amountRange ?? const RangeValues(0, 1000),
                              min: 0,
                              max: 1000,
                              divisions: 20,
                              labels: RangeLabels(
                                '\$${(_amountRange?.start ?? 0).toStringAsFixed(0)}',
                                '\$${(_amountRange?.end ?? 1000).toStringAsFixed(0)}',
                              ),
                              onChanged: (values) {
                                setState(() => _amountRange = values);
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${(_amountRange?.start ?? 0).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                Text(
                                  '\$${(_amountRange?.end ?? 1000).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFilterOptionsSection(
                        title: 'Sort By',
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _buildSortChip('Date', 'date'),
                            _buildSortChip('Amount', 'amount'),
                            _buildSortChip('Category', 'category'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildFilterOptionsSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
            Text(
              value != null
                  ? DateFormat('MMM d, y').format(value)
                  : 'Select Date',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
      },
      backgroundColor:
          _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100]!,
      selectedColor: _isDarkMode ? Colors.white : Colors.blue[700],
      checkmarkColor: _isDarkMode ? Colors.black87 : Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? (_isDarkMode ? Colors.black87 : Colors.white)
            : (_isDarkMode ? Colors.white : Colors.black87),
        fontFamily: 'Onest',
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

  void _showTransactionDetails(Transaction transaction) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final details = await authService.getTransactionDetails(transaction.id);

      // Convert response to TransactionDetail
      final transactionDetail = TransactionDetail.fromJson(details['data']);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => TransactionDetailsSheet(
            transaction: transaction,
            details: transactionDetail,
            isDarkMode: _isDarkMode,
            onCategoryChanged: (category) async {
              try {
                await authService.updateTransactionCategory(
                  transactionId: transaction.id,
                  category: category.id,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category updated to ${category.name}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Refresh the transactions list
                _loadTransactions();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update category'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load transaction details'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    setState(() {
      _isSearching = query.isNotEmpty;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        _loadTransactions();
        return;
      }

      if (query == _lastSearchQuery) return;
      _lastSearchQuery = query;

      setState(() {
        _isLoading = true;
      });

      final lowercaseQuery = query.toLowerCase();
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

      setState(() {
        _transactions = filteredTransactions;
        _groupTransactions();
        _isLoading = false;
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
    // TODO: Implement filter application with API call
    _loadTransactions();
  }
}

class TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;
  final TransactionDetail details;
  final bool isDarkMode;
  final Function(TransactionCategory) onCategoryChanged;

  const TransactionDetailsSheet({
    Key? key,
    required this.transaction,
    required this.details,
    required this.isDarkMode,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDetailsSection(),
                  const SizedBox(height: 24),
                  _buildMetadataSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    return Column(
      children: [
        Text(
          transaction.merchantName ?? 'Unknown Merchant',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 24,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          currencyFormatter.format(transaction.amount),
          style: TextStyle(
            color: transaction.isOutflow ? Colors.red[400] : Colors.green[400],
            fontSize: 32,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (transaction.isOutflow ? Colors.red : Colors.green)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                transaction.isOutflow
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
                color:
                    transaction.isOutflow ? Colors.red[400] : Colors.green[400],
              ),
              const SizedBox(width: 4),
              Text(
                transaction.isOutflow ? 'Outflow' : 'Inflow',
                style: TextStyle(
                  color: transaction.isOutflow
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

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transaction Details'),
        const SizedBox(height: 16),
        _buildDetailRow('Date', DateFormat('MMMM d, y').format(details.date)),
        _buildDetailRow('Category', details.category ?? 'Uncategorized'),
        if (details.metadata?['description'] != null)
          _buildDetailRow('Description', details.metadata!['description']),
        if (details.metadata?['pending'] == true)
          _buildDetailRow('Status', 'Pending'),
      ],
    );
  }

  Widget _buildMetadataSection() {
    if (details.metadata == null || details.metadata!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Information'),
        const SizedBox(height: 16),
        ...details.metadata!.entries
            .where((entry) =>
                entry.value != null &&
                !['description', 'pending'].contains(entry.key))
            .map((entry) => _buildDetailRow(
                entry.key.split('_').map((word) => word.capitalize()).join(' '),
                entry.value.toString()))
            .toList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 18,
        fontFamily: 'Onest',
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
