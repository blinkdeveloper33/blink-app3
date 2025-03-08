import 'dart:math' as math;
import 'package:intl/intl.dart';

class CashFlowData {
  final double totalInflow;
  final double totalOutflow;
  final double netCashFlow;
  final double avgInflow;
  final double avgOutflow;
  final bool isPositiveNetFlow;
  final String timeFrame;
  final String period;
  final List<CashFlowTrend> trends;
  final double? _growthRate;
  final Map<String, dynamic>? detailedAnalysis;

  CashFlowData({
    required this.totalInflow,
    required this.totalOutflow,
    required this.netCashFlow,
    required this.avgInflow,
    required this.avgOutflow,
    required this.isPositiveNetFlow,
    required this.timeFrame,
    required this.period,
    required this.trends,
    double? growthRate,
    this.detailedAnalysis,
  }) : _growthRate = growthRate;

  double get cashFlowRatio => totalOutflow > 0 ? totalInflow / totalOutflow : 0;

  // Use API growth rate if provided, otherwise calculate from trends
  double get growthRate {
    if (_growthRate != null) return _growthRate!;

    if (trends.length < 2) return 0;
    final firstFlow = trends.first.netFlow;
    final lastFlow = trends.last.netFlow;
    if (firstFlow == 0) return 0;
    return (lastFlow - firstFlow) / firstFlow.abs();
  }

  double get volatility {
    if (trends.isEmpty) return 0;
    final mean =
        trends.map((t) => t.netFlow).reduce((a, b) => a + b) / trends.length;
    final squaredDiffs = trends.map((t) => math.pow(t.netFlow - mean, 2));
    return math.sqrt(squaredDiffs.reduce((a, b) => a + b) / trends.length);
  }

  factory CashFlowData.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('segments')) {
      throw FormatException('Missing required field: segments');
    }

    final segments = json['segments'] as List<dynamic>;
    if (segments.isEmpty) {
      throw FormatException('Segments list is empty');
    }

    // Validate first segment to ensure correct format
    final firstSegment = segments.first as Map<String, dynamic>;
    if (!firstSegment.containsKey('period') ||
        !firstSegment.containsKey('inflow') ||
        !firstSegment.containsKey('outflow')) {
      throw FormatException(
          'Invalid segment format. Required fields: period, inflow, outflow');
    }

    final trends = segments.map((segment) {
      if (segment is! Map<String, dynamic>) {
        throw FormatException('Invalid segment format: $segment');
      }
      return CashFlowTrend.fromJson(segment);
    }).toList();

    // Extract growth rate if provided by API
    final growthRate = json.containsKey('growthRate')
        ? (json['growthRate'] as num?)?.toDouble() ?? 0.0
        : null;

    // Extract detailed analysis if provided
    final detailedAnalysis = json.containsKey('detailedAnalysis')
        ? json['detailedAnalysis'] as Map<String, dynamic>?
        : null;

    // Handle period field - extract from date_range if not directly provided
    String period;
    if (json.containsKey('period')) {
      period = json['period'].toString();
    } else if (json.containsKey('date_range')) {
      // Extract period from date_range
      final dateRange = json['date_range'] as Map<String, dynamic>;
      final startDate = dateRange['start_date']?.toString() ?? '';
      final endDate = dateRange['end_date']?.toString() ?? '';
      period = startDate.isNotEmpty && endDate.isNotEmpty
          ? '$startDate to $endDate'
          : 'Unknown Period';
    } else {
      // Default period based on timeframe
      final timeFrame =
          json['timeframe']?.toString()?.toUpperCase() ?? 'UNKNOWN';
      switch (timeFrame) {
        case 'LAST_WEEK':
        case 'WEEK':
          period = 'Last 7 Days';
          break;
        case 'LAST_MONTH':
        case 'MONTH':
          period = 'Last 30 Days';
          break;
        case 'LAST_QUARTER':
        case 'QUARTER':
          period = 'Last 3 Months';
          break;
        case 'LAST_YEAR':
        case 'YEAR':
          period = 'Last 12 Months';
          break;
        default:
          period = 'Current Period';
      }
    }

    return CashFlowData(
      totalInflow: (json['totalInflow'] as num?)?.toDouble() ?? 0.0,
      totalOutflow: (json['totalOutflow'] as num?)?.toDouble() ?? 0.0,
      netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0.0,
      avgInflow: (json['avgInflow'] as num?)?.toDouble() ?? 0.0,
      avgOutflow: (json['avgOutflow'] as num?)?.toDouble() ?? 0.0,
      isPositiveNetFlow: (json['isPositiveNetFlow'] as bool?) ?? false,
      timeFrame: json['timeframe']?.toString() ?? 'Last Year',
      period: period,
      trends: trends,
      growthRate: growthRate,
      detailedAnalysis: detailedAnalysis,
    );
  }

  @override
  String toString() {
    return 'CashFlowData(timeFrame: $timeFrame, totalInflow: $totalInflow, totalOutflow: $totalOutflow, trendsCount: ${trends.length}, hasDetailedAnalysis: ${detailedAnalysis != null})';
  }
}

class CashFlowTrend {
  final DateTime date;
  final double inflow;
  final double outflow;
  final String period;

  CashFlowTrend({
    required this.date,
    required this.inflow,
    required this.outflow,
    required this.period,
  });

  double get netFlow => inflow - outflow;
  double get runningBalance => netFlow;

  factory CashFlowTrend.fromJson(Map<String, dynamic> json) {
    // If we have a date field directly, use it
    DateTime date;
    if (json.containsKey('date') && json['date'] is DateTime) {
      date = json['date'] as DateTime;
    } else if (json.containsKey('start_date') && json['start_date'] is String) {
      // Use start_date if available (from detailed analysis)
      try {
        date = DateTime.parse(json['start_date']);
      } catch (e) {
        throw FormatException(
            'Invalid date format in start_date: ${json['start_date']}');
      }
    } else if (!json.containsKey('period')) {
      throw FormatException(
          'Missing required fields: period, date, or start_date');
    } else {
      final period = json['period'] as String;
      try {
        // Try parsing yyyy-MM-dd format first
        date = DateTime.tryParse(period) ??
            // Try parsing MMMM yyyy format
            DateFormat('MMMM yyyy').tryParse(period) ??
            // Handle weekly format (e.g., "Week 1", "Week 2")
            _parseWeeklyPeriod(period);
      } catch (e) {
        throw FormatException('Invalid date format in period: $period');
      }
    }

    // Get net_flow from JSON if available, otherwise calculate from inflow and outflow
    final double inflow = (json['inflow'] as num?)?.toDouble() ?? 0.0;
    final double outflow = (json['outflow'] as num?)?.toDouble() ?? 0.0;
    final String periodLabel = json['period'] as String? ??
        (json['start_date'] != null
            ? _formatPeriodFromStartDate(json['start_date'].toString())
            : '');

    return CashFlowTrend(
      date: date,
      period: periodLabel,
      inflow: inflow,
      outflow: outflow,
    );
  }

  // Helper method to format period labels from start_date
  static String _formatPeriodFromStartDate(String startDate) {
    try {
      final date = DateTime.parse(startDate);
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return startDate;
    }
  }

  static DateTime _parseWeeklyPeriod(String period) {
    final weekMatch = RegExp(r'Week (\d+)').firstMatch(period);
    if (weekMatch == null) {
      throw FormatException('Invalid weekly period format: $period');
    }

    final weekNumber = int.parse(weekMatch.group(1)!);
    // Start from the beginning of the current month and add weeks
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return startOfMonth.add(Duration(days: (weekNumber - 1) * 7));
  }

  @override
  String toString() {
    return 'CashFlowTrend(period: $period, inflow: $inflow, outflow: $outflow, netFlow: $netFlow)';
  }
}
