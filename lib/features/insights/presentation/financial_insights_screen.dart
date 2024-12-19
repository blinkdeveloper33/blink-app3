import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/financial_data_provider.dart';
import 'package:blink_app/features/insights/presentation/cash_flow_chart.dart';
import 'package:blink_app/features/insights/presentation/expense_analysis.dart';

class FinancialInsightsScreen extends StatefulWidget {
  const FinancialInsightsScreen({super.key});

  @override
  State<FinancialInsightsScreen> createState() =>
      _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen> {
  String _cashFlowTimeFrame = 'YTD';
  String _expenseTimeFrame = 'YTD';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FinancialDataProvider>(context, listen: false);
    await provider.loadFinancialData(_cashFlowTimeFrame, _expenseTimeFrame);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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
      ),
      body: Consumer<FinancialDataProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSectionContainer(
                    height: screenSize.width * 1.4, // Increased from 0.9 to 1.2
                    child: _buildCashFlowSection(provider),
                    color: const Color(0xFF1C2A4D),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionContainer(
                    height: screenSize.width * 1.5, // Increased from 1.1 to 1.4
                    child: _buildExpenseSection(provider),
                    color: const Color(0xFF2C3E50),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContainer({
    required Widget child,
    required Color color,
    required double height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _buildCashFlowSection(FinancialDataProvider provider) {
    return Stack(
      children: [
        if (provider.cashFlowState == DataState.loaded &&
            provider.cashFlowAnalysis != null)
          CashFlowChart(
            cashFlowData: provider.cashFlowAnalysis!,
            timeFrame: _cashFlowTimeFrame,
            onTimeFrameChanged: (String newTimeFrame) {
              setState(() {
                _cashFlowTimeFrame = newTimeFrame;
              });
              provider.loadCashFlowData(newTimeFrame);
            },
          ),
        if (provider.cashFlowState == DataState.loading)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (provider.cashFlowState == DataState.error)
          Center(
            child: _buildErrorWidget(
              provider.cashFlowError,
              () => provider.loadCashFlowData(_cashFlowTimeFrame),
            ),
          ),
        if (provider.cashFlowState == DataState.initial)
          const Center(
            child: Text(
              'No cash flow data available',
              style: TextStyle(color: Colors.white, fontFamily: 'Onest'),
            ),
          ),
      ],
    );
  }

  Widget _buildExpenseSection(FinancialDataProvider provider) {
    return Stack(
      children: [
        if (provider.expenseState == DataState.loaded &&
            provider.categoryAnalysis != null)
          ExpenseAnalysis(
            expenseData: provider.categoryAnalysis!,
            timeFrame: _expenseTimeFrame,
            onTimeFrameChanged: (String newTimeFrame) {
              setState(() {
                _expenseTimeFrame = newTimeFrame;
              });
              provider.loadExpenseData(newTimeFrame);
            },
          ),
        if (provider.expenseState == DataState.loading)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (provider.expenseState == DataState.error)
          Center(
            child: _buildErrorWidget(
              provider.expenseError,
              () => provider.loadExpenseData(_expenseTimeFrame),
            ),
          ),
        if (provider.expenseState == DataState.initial)
          const Center(
            child: Text(
              'No expense data available',
              style: TextStyle(color: Colors.white, fontFamily: 'Onest'),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget(String? error, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error ?? 'An error occurred',
            style: const TextStyle(
              color: Colors.red,
              fontFamily: 'Onest',
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontFamily: 'Onest'),
            ),
          ),
        ],
      ),
    );
  }
}
