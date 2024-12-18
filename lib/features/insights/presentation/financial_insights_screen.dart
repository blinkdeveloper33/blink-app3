import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/providers/financial_data_provider.dart';
import 'package:blink_app/features/insights/presentation/cash_flow_chart.dart';
import 'package:blink_app/features/insights/presentation/expense_analysis.dart';

class FinancialInsightsScreen extends StatefulWidget {
  const FinancialInsightsScreen({Key? key}) : super(key: key);

  @override
  _FinancialInsightsScreenState createState() =>
      _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen> {
  String _selectedTimeFrame = 'YTD';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FinancialDataProvider>(context, listen: false);
    await provider.loadFinancialData(_selectedTimeFrame);
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
            return _buildErrorWidget(provider.error);
          } else if (provider.state == DataState.loaded) {
            return _buildContent(provider);
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

  Widget _buildErrorWidget(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error ?? 'An error occurred',
            style: const TextStyle(color: Colors.red, fontFamily: 'Onest'),
          ),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry', style: TextStyle(fontFamily: 'Onest')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FinancialDataProvider provider) {
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
    return SingleChildScrollView(
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
