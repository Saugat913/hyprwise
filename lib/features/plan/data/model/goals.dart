import 'package:finance_tracker/core/utils/dates.dart';

/// Priority influences how prominently a goal is surfaced in advice.
enum GoalPriority {
  low('low', 'Low'),
  normal('normal', 'Normal'),
  high('high', 'High');

  const GoalPriority(this.value, this.label);

  final String value;
  final String label;

  static GoalPriority fromValue(String value) => GoalPriority.values.firstWhere(
    (priority) => priority.value == value,
    orElse: () => GoalPriority.normal,
  );
}

/// The measurable state of a goal at a point in time.
class GoalProgress {
  const GoalProgress({
    required this.targetMinor,
    required this.savedMinor,
    required this.targetDate,
    required this.now,
  });

  final int targetMinor;
  final int savedMinor;
  final DateTime? targetDate;
  final DateTime now;

  double get fraction => targetMinor <= 0 ? 0 : savedMinor / targetMinor;

  int get remainingMinor {
    final remaining = targetMinor - savedMinor;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isComplete => savedMinor >= targetMinor;

  int? get daysLeft => targetDate?.difference(AppDate.dateOnly(now)).inDays;

  /// The monthly saving needed from today to reach the target on time.
  int? get requiredMonthlyMinor {
    final days = daysLeft;
    if (days == null || days <= 0) return null;
    final months = days / 30.44;
    if (months <= 0) return remainingMinor;
    return (remainingMinor / months).round();
  }
}
