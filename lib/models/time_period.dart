import 'package:flutter/material.dart';

enum TimePeriod {
  lastWeek,
  lastMonth,
  lastQuarter,
  lastYear;

  String get label {
    switch (this) {
      case TimePeriod.lastWeek:
        return 'Last Week';
      case TimePeriod.lastMonth:
        return 'Last Month';
      case TimePeriod.lastQuarter:
        return 'Last Quarter';
      case TimePeriod.lastYear:
        return 'Last Year';
    }
  }

  String get apiValue {
    switch (this) {
      case TimePeriod.lastWeek:
        return 'LAST_WEEK';
      case TimePeriod.lastMonth:
        return 'LAST_MONTH';
      case TimePeriod.lastQuarter:
        return 'LAST_QUARTER';
      case TimePeriod.lastYear:
        return 'LAST_YEAR';
    }
  }

  IconData get icon {
    switch (this) {
      case TimePeriod.lastWeek:
        return Icons.view_week_rounded;
      case TimePeriod.lastMonth:
        return Icons.calendar_month_rounded;
      case TimePeriod.lastQuarter:
        return Icons.calendar_today_rounded;
      case TimePeriod.lastYear:
        return Icons.date_range_rounded;
    }
  }

  @override
  String toString() => apiValue;

  static TimePeriod fromString(String value) {
    switch (value) {
      case 'LAST_WEEK':
        return TimePeriod.lastWeek;
      case 'LAST_MONTH':
        return TimePeriod.lastMonth;
      case 'LAST_QUARTER':
        return TimePeriod.lastQuarter;
      case 'LAST_YEAR':
        return TimePeriod.lastYear;
      default:
        return TimePeriod.lastMonth;
    }
  }
}
