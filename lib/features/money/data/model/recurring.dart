import 'package:finance_tracker/core/database/app_database.dart';

/// The four kinds of recurring money movement.
enum RecurringKind {
  income('income', 'Income'),
  expense('expense', 'Expense'),
  bill('bill', 'Bill'),
  subscription('subscription', 'Subscription');

  const RecurringKind(this.value, this.label);

  final String value;
  final String label;

  bool get isOutgoing => this != RecurringKind.income;

  static RecurringKind fromValue(String value) =>
      RecurringKind.values.firstWhere(
        (kind) => kind.value == value,
        orElse: () => RecurringKind.bill,
      );
}

/// Recurrence cadence. [advance] moves a date forward by one interval.
enum RecurrenceFrequency {
  daily('daily', 'Daily', 'day'),
  weekly('weekly', 'Weekly', 'week'),
  monthly('monthly', 'Monthly', 'month'),
  yearly('yearly', 'Yearly', 'year');

  const RecurrenceFrequency(this.value, this.label, this.unit);

  final String value;
  final String label;
  final String unit;

  static RecurrenceFrequency fromValue(String value) =>
      RecurrenceFrequency.values.firstWhere(
        (frequency) => frequency.value == value,
        orElse: () => RecurrenceFrequency.monthly,
      );

  DateTime advance(DateTime date, int count) {
    switch (this) {
      case RecurrenceFrequency.daily:
        return date.add(Duration(days: count));
      case RecurrenceFrequency.weekly:
        return date.add(Duration(days: 7 * count));
      case RecurrenceFrequency.monthly:
        return DateTime(date.year, date.month + count, date.day);
      case RecurrenceFrequency.yearly:
        return DateTime(date.year + count, date.month, date.day);
    }
  }
}

extension RecurringRuleX on RecurringRule {
  int get monthlyEquivalentMinor {
    final freq = RecurrenceFrequency.fromValue(frequency);
    final count = intervalCount <= 0 ? 1 : intervalCount;
    final amt = amountMinor;
    switch (freq) {
      case RecurrenceFrequency.daily:
        return (amt * 30.44 / count).round();
      case RecurrenceFrequency.weekly:
        return (amt * 4.345 / count).round();
      case RecurrenceFrequency.monthly:
        return (amt / count).round();
      case RecurrenceFrequency.yearly:
        return (amt / 12 / count).round();
    }
  }
}
