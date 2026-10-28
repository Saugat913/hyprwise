import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/plan/data/model/goals.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

enum InsightsPeriod {
  week('This week', 7),
  month('This month', 31),
  quarter('Last 90 days', 90);

  const InsightsPeriod(this.label, this.days);

  final String label;
  final int days;

  (DateTime, DateTime) range(DateTime now) {
    final end = AppDate.dateOnly(now);
    if (this == InsightsPeriod.week) {
      final start = end.subtract(Duration(days: end.weekday - DateTime.monday));
      return (start, end);
    }
    if (this == InsightsPeriod.month) {
      return (AppDate.startOfMonth(now), AppDate.endOfMonth(now));
    }
    return (end.subtract(const Duration(days: 89)), end);
  }
}

class CategorySpend {
  const CategorySpend({
    required this.categoryKey,
    required this.label,
    required this.amountMinor,
  });

  final String categoryKey;
  final String label;
  final int amountMinor;
}

class WorkSummary {
  const WorkSummary({
    required this.shiftCount,
    required this.workedMinutes,
    required this.earningsMinor,
  });

  final int shiftCount;
  final int workedMinutes;
  final int earningsMinor;

  double get hours => workedMinutes / 60;
}

class InsightsReport {
  const InsightsReport({
    required this.period,
    required this.start,
    required this.end,
    required this.currencyCode,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.previousIncomeMinor,
    required this.previousExpenseMinor,
    required this.categoryBreakdown,
    required this.dailyExpense,
    required this.dailyLabels,
    required this.work,
    required this.goals,
  });

  final InsightsPeriod period;
  final DateTime start;
  final DateTime end;
  final String currencyCode;
  final int incomeMinor;
  final int expenseMinor;
  final int previousIncomeMinor;
  final int previousExpenseMinor;
  final List<CategorySpend> categoryBreakdown;
  final List<double> dailyExpense;
  final List<String> dailyLabels;
  final WorkSummary work;
  final List<GoalProgress> goals;

  int get netMinor => incomeMinor - expenseMinor;

  double get savingsRate => incomeMinor <= 0 ? 0 : netMinor / incomeMinor;

  double get expenseChange {
    if (previousExpenseMinor <= 0) return expenseMinor > 0 ? 1 : 0;
    return (expenseMinor - previousExpenseMinor) / previousExpenseMinor;
  }

  bool get hasSpending => expenseMinor > 0;
}

/// Aggregates recorded activity into a weekly, monthly or quarterly report.
class InsightsEngine {
  const InsightsEngine();

  InsightsReport report(FinanceSnapshot snapshot, InsightsPeriod period) {
    final (start, end) = period.range(snapshot.now);
    final previousStart = start.subtract(Duration(days: period.days));

    var income = 0;
    var expense = 0;
    var previousIncome = 0;
    var previousExpense = 0;
    final categoryTotals = <String, int>{};
    final dayBuckets = <int>{};
    final perDay = <int, double>{};

    for (final transaction in snapshot.transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
      final amount = snapshot.convert(
        transaction.amountMinor,
        snapshot.currencyOf(transaction.accountId),
      );
      final isIncome = transaction.type == TransactionType.income.value;

      if (!date.isBefore(start) && !date.isAfter(end)) {
        if (isIncome) {
          income += amount;
        } else {
          expense += amount;
          categoryTotals.update(
            transaction.category,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
          final key = AppDate.dateOnly(date).millisecondsSinceEpoch;
          dayBuckets.add(key);
          perDay.update(
            key,
            (value) => value + amount,
            ifAbsent: () => amount.toDouble(),
          );
        }
      } else if (!date.isBefore(previousStart) && date.isBefore(start)) {
        if (isIncome) {
          previousIncome += amount;
        } else {
          previousExpense += amount;
        }
      }
    }

    final breakdown =
        categoryTotals.entries
            .map(
              (entry) => CategorySpend(
                categoryKey: entry.key,
                label:
                    TransactionCategories.fromValue(
                      entry.key,
                      TransactionType.expense,
                    ).label,
                amountMinor: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

    final labels = <String>[];
    final values = <double>[];
    final detail =
        period == InsightsPeriod.week || period == InsightsPeriod.month;
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final key = AppDate.dateOnly(day).millisecondsSinceEpoch;
      if (detail) {
        labels.add(DateFormatter.day(day));
        values.add(perDay[key] ?? 0);
      }
    }
    if (!detail) {
      // For long windows, bucket by week for a readable chart.
      var weekStart = start;
      var index = 0;
      while (!weekStart.isAfter(end)) {
        final weekEnd = weekStart.add(const Duration(days: 6));
        var sum = 0.0;
        for (
          var day = weekStart;
          !day.isAfter(weekEnd) && !day.isAfter(end);
          day = day.add(const Duration(days: 1))
        ) {
          sum += perDay[AppDate.dateOnly(day).millisecondsSinceEpoch] ?? 0;
        }
        labels.add('W${index + 1}');
        values.add(sum);
        weekStart = weekEnd.add(const Duration(days: 1));
        index++;
      }
    }

    final work = _workSummary(snapshot, start, end);
    final goals = _goalProgress(snapshot, start, end);

    return InsightsReport(
      period: period,
      start: start,
      end: end,
      currencyCode: snapshot.baseCurrency,
      incomeMinor: income,
      expenseMinor: expense,
      previousIncomeMinor: previousIncome,
      previousExpenseMinor: previousExpense,
      categoryBreakdown: breakdown,
      dailyExpense: values,
      dailyLabels: labels,
      work: work,
      goals: goals,
    );
  }

  WorkSummary _workSummary(
    FinanceSnapshot snapshot,
    DateTime start,
    DateTime end,
  ) {
    final jobsById = {for (final job in snapshot.jobs) job.id: job};
    var shifts = 0;
    var minutes = 0;
    var earnings = 0;
    for (final shift in snapshot.shifts) {
      if (shift.status != ShiftStatus.completed.value) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
      if (date.isBefore(start) || date.isAfter(end)) continue;
      final job = jobsById[shift.jobId];
      if (job == null) continue;
      final result = ShiftEarnings.forShift(shift, job);
      shifts++;
      minutes += result.workedMinutes;
      earnings += snapshot.convert(result.earningsMinor, job.currencyCode);
    }
    return WorkSummary(
      shiftCount: shifts,
      workedMinutes: minutes,
      earningsMinor: earnings,
    );
  }

  List<GoalProgress> _goalProgress(
    FinanceSnapshot snapshot,
    DateTime start,
    DateTime end,
  ) {
    final progresses = <GoalProgress>[];
    for (final goal in snapshot.goals.where((goal) => !goal.isArchived)) {
      final contributions = snapshot.contributions
          .where((contribution) => contribution.goalId == goal.id)
          .fold(0, (sum, contribution) => sum + contribution.amountMinor);
      final linked =
          goal.accountId != null ? snapshot.balanceOf(goal.accountId!) : 0;
      final saved = snapshot.convert(contributions + linked, goal.currencyCode);
      progresses.add(
        GoalProgress(
          targetMinor: goal.targetAmountMinor,
          savedMinor: saved,
          targetDate:
              goal.targetDate == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(goal.targetDate!),
          now: snapshot.now,
        ),
      );
    }
    return progresses;
  }
}
