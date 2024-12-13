import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/auth_service.dart' as auth_service;
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/models/transaction.dart';
import 'package:blink_app/providers/financial_data_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FinancialDataProvider>(context, listen: false);
    await provider.loadTransactions();
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
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadData,
          ),
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
      body: Consumer<FinancialDataProvider>(
        builder: (context, provider, child) {
          if (provider.state == DataState.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.state == DataState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error ?? 'An error occurred',
                      style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (provider.state == DataState.loaded) {
            return RefreshIndicator(
              onRefresh: provider.refreshTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCashflowAnalysis(provider),
                      const SizedBox(height: 24),
                      _buildExpenseAllocation(provider),
                      const SizedBox(height: 24),
                      _buildTransactionCards(provider),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildCashflowAnalysis(FinancialDataProvider provider) {
    final transactions = provider.transactions;
    final inflows =
        transactions.where((t) => t.amount > 0).map((t) => t.amount).toList();
    final outflows = transactions
        .where((t) => t.amount < 0)
        .map((t) => t.amount.abs())
        .toList();

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
              maxY: inflows.isEmpty
                  ? 100
                  : inflows.reduce((a, b) => a > b ? a : b),
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
              barGroups: List.generate(
                7,
                (index) => _generateBarGroup(
                  index,
                  index < inflows.length ? inflows[index] : 0,
                  index < outflows.length ? outflows[index] : 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildCashflowCard(
                title: 'Cash Inflow 💰',
                amount: provider.getTotalInflow(),
                change:
                    10.0, // This should be calculated based on historical data
                isPositive: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCashflowCard(
                title: 'Cash Outflow 💸',
                amount: provider.getTotalOutflow(),
                change:
                    5.0, // This should be calculated based on historical data
                isPositive: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashflowCard({
    required String title,
    required double amount,
    required double change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green[50] : Colors.red[50],
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
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Onest',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(amount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}% vs Last Year',
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? Colors.green[700] : Colors.red[700],
              fontFamily: 'Onest',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseAllocation(FinancialDataProvider provider) {
    final categoryTotals = provider.getCategoryTotals();
    final totalExpenses =
        categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    final expenseCategories = categoryTotals.map((category, amount) {
      final percentage =
          totalExpenses > 0 ? (amount / totalExpenses * 100).round() : 0;
      return MapEntry(category, {
        'amount': amount,
        'percentage': percentage,
        'color': _getCategoryColor(category),
        'backgroundColor': _getCategoryColor(category).withOpacity(0.1),
      });
    });

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
              sections: expenseCategories.entries.map((entry) {
                return PieChartSectionData(
                  color: entry.value['color'] as Color,
                  value: entry.value['percentage']?.toDouble(),
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
          children: expenseCategories.entries.map((entry) {
            return _buildExpenseCard(
              entry.key,
              entry.value['amount'] as double,
              '${entry.value['percentage']}% of total expenses',
              entry.value['backgroundColor'] as Color,
              entry.value['color'] as Color,
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

  Widget _buildTransactionCards(FinancialDataProvider provider) {
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
          itemCount: provider.transactions.length > 5
              ? 5
              : provider.transactions.length,
          itemBuilder: (context, index) {
            final transaction = provider.transactions[index];
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

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Groceries': Colors.blue,
      'Utilities': Colors.orange,
      'Entertainment': Colors.purple,
      'Transportation': Colors.green,
      'Shopping': Colors.red,
      'Health': Colors.teal,
      'Education': Colors.indigo,
    };

    return colors[category] ?? Colors.grey;
  }
}

extension on Object? {
  toDouble() {}
}
