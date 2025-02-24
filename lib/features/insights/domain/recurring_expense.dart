import 'package:intl/intl.dart';

class RecurringExpensesData {
  final String timeFrame;
  final Period period;
  final Summary summary;
  final FrequencyGroups frequencyGroups;
  final Totals totals;
  final List<RecurringExpense> upcomingExpenses;

  RecurringExpensesData({
    required this.timeFrame,
    required this.period,
    required this.summary,
    required this.frequencyGroups,
    required this.totals,
    required this.upcomingExpenses,
  });

  factory RecurringExpensesData.fromJson(Map<String, dynamic> json) {
    return RecurringExpensesData(
      timeFrame: json['timeFrame'] as String,
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
      summary: Summary.fromJson(json['summary'] as Map<String, dynamic>),
      frequencyGroups: FrequencyGroups.fromJson(
          json['frequencyGroups'] as Map<String, dynamic>),
      totals: Totals.fromJson(json['totals'] as Map<String, dynamic>),
      upcomingExpenses: (json['upcomingExpenses'] as List<dynamic>)
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Period {
  final DateTime start;
  final DateTime end;

  Period({required this.start, required this.end});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  String get formattedDateRange {
    final formatter = DateFormat('MMM d, y');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }
}

class Summary {
  final int totalRecurringExpenses;
  final double totalMonthlyCommitment;
  final int unusualChanges;

  Summary({
    required this.totalRecurringExpenses,
    required this.totalMonthlyCommitment,
    required this.unusualChanges,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalRecurringExpenses: json['totalRecurringExpenses'] as int,
      totalMonthlyCommitment:
          (json['totalMonthlyCommitment'] as num).toDouble(),
      unusualChanges: json['unusualChanges'] as int,
    );
  }
}

class FrequencyGroups {
  final List<RecurringExpense> weekly;
  final List<RecurringExpense> biWeekly;
  final List<RecurringExpense> monthly;
  final List<RecurringExpense> quarterly;
  final List<RecurringExpense> annual;

  FrequencyGroups({
    required this.weekly,
    required this.biWeekly,
    required this.monthly,
    required this.quarterly,
    required this.annual,
  });

  factory FrequencyGroups.fromJson(Map<String, dynamic> json) {
    return FrequencyGroups(
      weekly: (json['weekly'] as List<dynamic>)
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      biWeekly: (json['biWeekly'] as List<dynamic>)
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthly: (json['monthly'] as List<dynamic>)
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      quarterly: (json['quarterly'] as List<dynamic>)
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
      annual: (json['annual'] as List<dynamic>)
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Totals {
  final double weekly;
  final double biWeekly;
  final double monthly;
  final double quarterly;
  final double annual;

  Totals({
    required this.weekly,
    required this.biWeekly,
    required this.monthly,
    required this.quarterly,
    required this.annual,
  });

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      weekly: (json['weekly'] as num).toDouble(),
      biWeekly: (json['biWeekly'] as num).toDouble(),
      monthly: (json['monthly'] as num).toDouble(),
      quarterly: (json['quarterly'] as num).toDouble(),
      annual: (json['annual'] as num).toDouble(),
    );
  }
}

class RecurringExpense {
  final String merchant;
  final String frequency;
  final double averageAmount;
  final double recentAmount;
  final bool hasUnusualChange;
  final double amountChangePercent;
  final DateTime lastDate;
  final DateTime nextExpectedDate;
  final int transactionCount;
  final String category;
  final int confidence;
  final List<Transaction> transactions;

  RecurringExpense({
    required this.merchant,
    required this.frequency,
    required this.averageAmount,
    required this.recentAmount,
    required this.hasUnusualChange,
    required this.amountChangePercent,
    required this.lastDate,
    required this.nextExpectedDate,
    required this.transactionCount,
    required this.category,
    required this.confidence,
    required this.transactions,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      merchant: json['merchant'] as String,
      frequency: json['frequency'] as String,
      averageAmount: (json['averageAmount'] as num).toDouble(),
      recentAmount: (json['recentAmount'] as num).toDouble(),
      hasUnusualChange: json['hasUnusualChange'] as bool,
      amountChangePercent: (json['amountChangePercent'] as num).toDouble(),
      lastDate: DateTime.parse(json['lastDate'] as String),
      nextExpectedDate: DateTime.parse(json['nextExpectedDate'] as String),
      transactionCount: json['transactionCount'] as int,
      category: json['category'] as String,
      confidence: json['confidence'] as int,
      transactions: (json['transactions'] as List<dynamic>)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Transaction {
  final DateTime date;
  final double amount;
  final String description;

  Transaction({
    required this.date,
    required this.amount,
    required this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
    );
  }
}
