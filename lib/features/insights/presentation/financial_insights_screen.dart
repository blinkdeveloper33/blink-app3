import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String bankAccountId;
  final String transactionId;
  final double amount;
  final DateTime date;
  final String description;
  final String? originalDescription;
  final String category;
  final String? categoryDetailed;
  final String? merchantName;
  final bool pending;
  final DateTime createdAt;
  final String accountId;
  final String? userId;

  Transaction({
    required this.id,
    required this.bankAccountId,
    required this.transactionId,
    required this.amount,
    required this.date,
    required this.description,
    this.originalDescription,
    required this.category,
    this.categoryDetailed,
    this.merchantName,
    required this.pending,
    required this.createdAt,
    required this.accountId,
    this.userId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? Uuid().v4(),
      bankAccountId: json['bank_account_id'],
      transactionId: json['transaction_id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      originalDescription: json['original_description'],
      category: json['category'] ?? 'Uncategorized',
      categoryDetailed: json['category_detailed'],
      merchantName: json['merchant_name'],
      pending: json['pending'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      accountId: json['account_id'],
      userId: json['user_id'],
    );
  }
}

class FinancialInsightsScreen extends StatefulWidget {
  final String? period;
  final String? startDate;
  final String? endDate;

  const FinancialInsightsScreen(
      {super.key, this.period, this.startDate, this.endDate});

  @override
  State<FinancialInsightsScreen> createState() =>
      _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen> {
  String _selectedCashflowPeriod = 'Yearly';
  String _selectedExpensePeriod = 'Monthly';
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  bool _isLoading = true;
  String? _error;
  List<Transaction> _transactions = [];
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.period != null) {
      setState(() {
        _selectedCashflowPeriod = widget.period!;
        _selectedExpensePeriod = widget.period!;
      });
    }
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (!_hasMoreData) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.getAllTransactions();

      if (response['success'] == true) {
        final newTransactions = (response['transactions'] as List)
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _transactions = newTransactions;
          _isLoading = false;
          _error = null;
        });
      } else {
        throw Exception('Failed to fetch transactions: ${response['error']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load transactions. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Financial Insights',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Onest',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Financial Insights Info'),
                    content: const Text(
                        'This screen displays your financial insights based on your transaction history.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _fetchTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCashflowAnalysis(),
                          const SizedBox(height: 24),
                          _buildExpenseAllocation(),
                          const SizedBox(height: 24),
                          _buildTransactionCards(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildCashflowAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cashflow Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Onest',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedCashflowPeriod,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 800,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = [
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'May',
                        'Jun',
                        'Jul'
                      ];
                      return Text(
                        months[value.toInt()],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Onest',
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Onest',
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 200,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                _generateBarGroup(0, 650, 450),
                _generateBarGroup(1, 750, 600),
                _generateBarGroup(2, 650, 550),
                _generateBarGroup(3, 700, 500),
                _generateBarGroup(4, 600, 450),
                _generateBarGroup(5, 700, 600),
                _generateBarGroup(6, 750, 400),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cash Inflow 💰',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(_totalInflow),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${_inflowChange.toStringAsFixed(0)}% vs Last Year',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cash Outflow 💸',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(_totalOutflow),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_outflowChange.toStringAsFixed(0)}% vs Last Year',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseAllocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expense Allocation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Onest',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedExpensePeriod,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: _expenseCategories.entries.map((entry) {
                return PieChartSectionData(
                  color: entry.value['color'],
                  value: entry.value['percentage'].toDouble(),
                  title: '${entry.value['percentage']}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Onest',
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _expenseCategories.entries.map((entry) {
            return _buildExpenseCard(
              entry.key,
              entry.value['amount'],
              '${entry.value['percentage']}% of the total value for ${entry.key}',
              entry.value['backgroundColor'],
              entry.value['color'],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(
    String title,
    double amount,
    String subtitle,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
              fontFamily: 'Onest',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaction Cards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Onest',
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement see all functionality
              },
              child: const Text(
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            return _buildTransactionCard(transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                transaction.merchantName?.substring(0, 1).toUpperCase() ?? '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchantName ?? 'Unknown Merchant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${transaction.category}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Onest',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(transaction.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.amount < 0 ? Colors.red : Colors.green,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM, yyyy').format(transaction.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Onest',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _generateBarGroup(
    int x,
    double inflow,
    double outflow,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: inflow,
          color: Colors.green,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: outflow,
          color: Colors.pink,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  // Cashflow data
  final double _totalInflow = 22245.40;
  final double _totalOutflow = 4165.80;
  final double _inflowChange = 10.0;
  final double _outflowChange = -5.0;

  // Expense allocation data
  final Map<String, Map<String, dynamic>> _expenseCategories = {
    'Food & Groceries 🛒': {
      'amount': 1240.50,
      'percentage': 40,
      'color': Colors.blue,
      'backgroundColor': Colors.blue[50]!,
    },
    'Utilities ⚡': {
      'amount': 460.70,
      'percentage': 15,
      'color': Colors.orange,
      'backgroundColor': Colors.orange[50]!,
    },
    'Entertainment 🎮': {
      'amount': 560.70,
      'percentage': 25,
      'color': Colors.purple,
      'backgroundColor': Colors.purple[50]!,
    },
    'Others': {
      'amount': 530.50,
      'percentage': 20,
      'color': Colors.pink,
      'backgroundColor': Colors.pink[50]!,
    },
  };
}
