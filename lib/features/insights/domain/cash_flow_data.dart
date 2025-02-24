import 'dart:math' as math;
import 'package:intl/intl.dart';

class CashFlowData {
  final String timeFrame;
  final double totalInflow;
  final double totalOutflow;
  final List<CashFlowTrend> trends;

  CashFlowData({
    required this.timeFrame,
    required this.totalInflow,
    required this.totalOutflow,
    required this.trends,
  });

  double get netCashFlow => totalInflow - totalOutflow;
  double get cashFlowRatio => totalOutflow > 0 ? totalInflow / totalOutflow : 0;
  double get growthRate {
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

    return CashFlowData(
      timeFrame: json['timeframe']?.toString() ?? 'Last Year',
      totalInflow: (json['totalInflow'] as num?)?.toDouble() ?? 0.0,
      totalOutflow: (json['totalOutflow'] as num?)?.toDouble() ?? 0.0,
      trends: trends,
    );
  }

  @override
  String toString() {
    return 'CashFlowData(timeFrame: $timeFrame, totalInflow: $totalInflow, totalOutflow: $totalOutflow, trendsCount: ${trends.length})';
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
    if (!json.containsKey('period')) {
      throw FormatException('Missing required field: period');
    }

    final period = json['period'] as String;
    DateTime date;
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

    return CashFlowTrend(
      date: date,
      period: period,
      inflow: (json['inflow'] as num?)?.toDouble() ?? 0.0,
      outflow: (json['outflow'] as num?)?.toDouble() ?? 0.0,
    );
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
