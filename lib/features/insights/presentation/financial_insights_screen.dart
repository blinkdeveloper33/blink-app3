import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/providers/financial_data_provider.dart';
import 'package:blink_app/features/insights/presentation/cash_flow_chart.dart';
import 'package:blink_app/features/insights/presentation/expense_analysis.dart';
import 'package:blink_app/features/insights/presentation/summary_card.dart';
import 'package:blink_app/features/insights/presentation/animated_pie_chart.dart';

class FinancialInsightsScreen extends StatefulWidget {
  const FinancialInsightsScreen({Key? key}) : super(key: key);

  @override
  _FinancialInsightsScreenState createState() =>
      _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTimeFrame = 'YTD';
  late AnimationController _animationController;
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FinancialDataProvider>(context, listen: false);
    await provider.loadFinancialData(_selectedTimeFrame);
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Insights',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          _buildTimeFrameSelector(),
        ],
      ),
      body: Consumer<FinancialDataProvider>(
        builder: (context, provider, child) {
          if (provider.state == DataState.loading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          } else if (provider.state == DataState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error ?? 'An error occurred',
                    style:
                        const TextStyle(color: Colors.red, fontFamily: 'Onest'),
                  ),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry',
                        style: TextStyle(fontFamily: 'Onest')),
                  ),
                ],
              ),
            );
          } else if (provider.state == DataState.loaded) {
            final cashFlowAnalysis = provider.cashFlowAnalysis;
            final categoryAnalysis = provider.categoryAnalysis;
            if (cashFlowAnalysis == null || categoryAnalysis == null) {
              return const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.white, fontFamily: 'Onest'),
                ),
              );
            }
            return _buildContent(cashFlowAnalysis, categoryAnalysis);
          } else {
            return const Center(
              child: Text(
                'No data available',
                style: TextStyle(color: Colors.white, fontFamily: 'Onest'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> cashFlowAnalysis,
      Map<String, dynamic> categoryAnalysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CashFlowChart(
            cashFlowData: cashFlowAnalysis,
            timeFrame: _selectedTimeFrame,
            onTimeFrameChanged: (String newTimeFrame) {
              setState(() {
                _selectedTimeFrame = newTimeFrame;
              });
              _loadData();
            },
          ),
          const SizedBox(height: 24),
          ExpenseAnalysis(
            expenseData: categoryAnalysis,
            timeFrame: _selectedTimeFrame,
            onTimeFrameChanged: (String newTimeFrame) {
              setState(() {
                _selectedTimeFrame = newTimeFrame;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeFrame,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontFamily: 'Onest'),
          dropdownColor: const Color(0xFF0A0E21),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTimeFrame = newValue;
              });
              _loadData();
            }
          },
          items: <String>['WTD', 'MTD', 'QTD', 'YTD']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(_formatTimeFrameLabel(value)),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatTimeFrameLabel(String value) {
    switch (value) {
      case 'WTD':
        return 'Week to Date';
      case 'MTD':
        return 'Month to Date';
      case 'QTD':
        return 'Quarter to Date';
      case 'YTD':
        return 'Year to Date';
      default:
        return value;
    }
  }
}
