import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/services/auth_service.dart' as auth;
import 'package:intl/intl.dart';
import 'package:blink_app/services/storage_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isDarkMode = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  List<auth.Transaction> _searchResults = [];

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

    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
      if (_searchController.text.isNotEmpty) {
        _performSearch();
      }
    });
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      final userId = storageService.getUserId();
      if (userId == null) throw Exception('User ID not found');

      final transactions =
          await authService.getRecentTransactions(userId: userId);

      final searchQuery = _searchController.text.toLowerCase();
      final filteredTransactions = transactions.where((transaction) {
        final matchesQuery =
            transaction.merchantName?.toLowerCase().contains(searchQuery) ??
                false;
        final matchesDate = _selectedStartDate == null ||
                _selectedEndDate == null
            ? true
            : (transaction.date.isAfter(_selectedStartDate!) &&
                transaction.date
                    .isBefore(_selectedEndDate!.add(const Duration(days: 1))));
        return matchesQuery && matchesDate;
      }).toList();

      setState(() {
        _searchResults = filteredTransactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = DateTimeRange(
      start: _selectedStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
      end: _selectedEndDate ?? DateTime.now(),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: _isDarkMode ? const Color(0xFF1A2942) : Colors.white,
              onSurface: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        _selectedStartDate = pickedDateRange.start;
        _selectedEndDate = pickedDateRange.end;
      });
      _performSearch();
    }
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color:
                _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
              fontFamily: 'Onest',
            ),
            decoration: InputDecoration(
              hintText: 'Search transactions by name...',
              hintStyle: TextStyle(
                color: _isDarkMode ? Colors.white60 : Colors.black45,
                fontSize: 16,
                fontFamily: 'Onest',
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _isDarkMode ? Colors.white60 : Colors.black45,
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: _isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                      onPressed: () {
                        haptics.Haptics.vibrate(haptics.HapticsType.light);
                        _searchController.clear();
                        setState(() => _searchResults.clear());
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[300]!,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _isDarkMode ? Colors.white60 : Colors.black45,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedStartDate == null
                          ? 'Select date range'
                          : '${DateFormat('MMM d, y').format(_selectedStartDate!)} - ${DateFormat('MMM d, y').format(_selectedEndDate!)}',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ),
                  if (_selectedStartDate != null)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: _isDarkMode ? Colors.white60 : Colors.black45,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedStartDate = null;
                          _selectedEndDate = null;
                        });
                        _performSearch();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(auth.Transaction transaction) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final dateFormatter = DateFormat('MMM d, y');
    final color = transaction.amount >= 0 ? Colors.green : Colors.red;

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  transaction.amount >= 0
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchantName ?? 'Unknown',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(transaction.date),
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormatter.format(transaction.amount.abs()),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Search Transactions',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 24,
                                  fontFamily: 'Onest',
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
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_searchResults.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(_searchResults[index]);
                          },
                        ),
                      )
                    else if (_isSearching)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 16,
                              fontFamily: 'Onest',
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 48,
                                color: _isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Search for transactions by name or date',
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 16,
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
            ),
          );
        },
      ),
    );
  }
}
