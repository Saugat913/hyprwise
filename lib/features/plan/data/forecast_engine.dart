import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/plan/data/model/goals.dart';
import 'package:finance_tracker/features/money/data/model/recurring.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

enum ForecastEventKind { income, expense, bill, subscription, shift }

/// A single scheduled money movement in the projection.
class ForecastEvent {
  const ForecastEvent({
    required this.date,
    required this.label,
    required this.deltaMinor,
    required this.kind,
    this.rateFormatted,
  });

  final DateTime date;
  final String label;
  final int deltaMinor;
  final ForecastEventKind kind;
  final String? rateFormatted;

  bool get isIncome => deltaMinor >= 0;
}

/// One sampled point of the projected balance curve.
class ForecastPoint {
  const ForecastPoint(this.date, this.balanceMinor);

  final DateTime date;
  final int balanceMinor;
}

/// How a goal looks against the projection.
class GoalForecast {
  const GoalForecast({
    required this.goal,
    required this.progress,
    required this.projectedMinor,
    required this.shortfallMinor,
    required this.onTrack,
  });

  final Goal goal;
  final GoalProgress progress;
  final int projectedMinor;
  final int shortfallMinor;
  final bool onTrack;
}

class ForecastResult {
  const ForecastResult({
    required this.horizonDays,
    required this.startMinor,
    required this.endMinor,
    required this.points,
    required this.events,
    required this.goalForecasts,
    required this.expectedIncomeMinor,
    required this.plannedExpenseMinor,
    required this.shiftIncomeMinor,
    required this.currencyCode,
  });

  final int horizonDays;
  final int startMinor;
  final int endMinor;
  final List<ForecastPoint> points;
  final List<ForecastEvent> events;
  final List<GoalForecast> goalForecasts;
  final int expectedIncomeMinor;
  final int plannedExpenseMinor;
  final int shiftIncomeMinor;
  final String currencyCode;

  int get finalBalanceMinor => endMinor;

  int get netChangeMinor => endMinor - startMinor;

  /// Events falling within the next seven days.
  List<ForecastEvent> upcomingWithin(int days, DateTime now) {
    final limit = now.add(Duration(days: days));
    return events
        .where((event) => !event.date.isAfter(limit))
        .toList(growable: false);
  }

  int balanceAt(DateTime date) {
    if (points.isEmpty) return startMinor;
    if (!date.isAfter(points.last.date)) {
      for (final point in points) {
        if (!point.date.isBefore(date)) return point.balanceMinor;
      }
      return points.first.balanceMinor;
    }
    return points.last.balanceMinor;
  }
}

/// Deterministic financial forecasting.
///
/// The engine expands recurring rules and scheduled shifts into future events,
/// walks them day by day from the current position, and reports both the
/// projected balance and each goal's safety margin. No randomness, no network:
/// the same snapshot always produces the same result, which is what lets the
/// assistant explain the numbers honestly.
class ForecastEngine {
  const ForecastEngine();

  ForecastResult project(
    FinanceSnapshot snapshot, {
    int horizonDays = 90,
    List<ForecastEvent> extraEvents = const [],
  }) {
    final start = AppDate.dateOnly(snapshot.now);
    final horizonEnd = start.add(Duration(days: horizonDays));

    final events = <ForecastEvent>[
      ..._expandRecurring(snapshot, start, horizonEnd),
      ..._scheduledShifts(snapshot, start, horizonEnd),
      ...extraEvents,
    ]..sort((a, b) => a.date.compareTo(b.date));

    final startMinor = snapshot.netWorthMinor;
    final points = <ForecastPoint>[];
    var balance = startMinor;
    var eventIndex = 0;

    for (var day = 0; day <= horizonDays; day++) {
      final date = start.add(Duration(days: day));
      while (eventIndex < events.length &&
          !events[eventIndex].date.isAfter(date)) {
        balance += events[eventIndex].deltaMinor;
        eventIndex++;
      }
      points.add(ForecastPoint(date, balance));
    }

    final expectedIncome = events
        .where(
          (event) =>
              event.deltaMinor >= 0 && event.kind == ForecastEventKind.income,
        )
        .fold(0, (sum, event) => sum + event.deltaMinor);
    final plannedExpense = events
        .where((event) => event.deltaMinor < 0)
        .fold(0, (sum, event) => sum + event.deltaMinor.abs());
    final shiftIncome = events
        .where((event) => event.kind == ForecastEventKind.shift)
        .fold(0, (sum, event) => sum + event.deltaMinor);

    final goalForecasts = _goalForecasts(snapshot, points, start, horizonEnd);

    return ForecastResult(
      horizonDays: horizonDays,
      startMinor: startMinor,
      endMinor: balance,
      points: points,
      events: events,
      goalForecasts: goalForecasts,
      expectedIncomeMinor: expectedIncome,
      plannedExpenseMinor: plannedExpense,
      shiftIncomeMinor: shiftIncome,
      currencyCode: snapshot.baseCurrency,
    );
  }

  List<ForecastEvent> _expandRecurring(
    FinanceSnapshot snapshot,
    DateTime start,
    DateTime horizonEnd,
  ) {
    final events = <ForecastEvent>[];
    for (final rule in snapshot.recurring) {
      if (!rule.isActive) continue;
      final kind = RecurringKind.fromValue(rule.kind);
      var due = DateTime.fromMillisecondsSinceEpoch(rule.nextDueAt);
      var guard = 0;
      while (due.isBefore(start) && guard < 400) {
        due = RecurrenceFrequency.fromValue(
          rule.frequency,
        ).advance(due, rule.intervalCount);
        guard++;
      }
      while (!due.isAfter(horizonEnd) && guard < 800) {
        if (rule.endAt != null &&
            due.isAfter(DateTime.fromMillisecondsSinceEpoch(rule.endAt!))) {
          break;
        }
        final base = snapshot.convert(rule.amountMinor, rule.currencyCode);
        events.add(
          ForecastEvent(
            date: AppDate.dateOnly(due),
            label: rule.name,
            deltaMinor: kind.isOutgoing ? -base : base,
            kind: switch (kind) {
              RecurringKind.income => ForecastEventKind.income,
              RecurringKind.expense => ForecastEventKind.expense,
              RecurringKind.bill => ForecastEventKind.bill,
              RecurringKind.subscription => ForecastEventKind.subscription,
            },
          ),
        );
        due = RecurrenceFrequency.fromValue(
          rule.frequency,
        ).advance(due, rule.intervalCount);
        guard++;
      }
    }
    return events;
  }

  List<ForecastEvent> _scheduledShifts(
    FinanceSnapshot snapshot,
    DateTime start,
    DateTime horizonEnd,
  ) {
    final jobsById = {for (final job in snapshot.jobs) job.id: job};
    final events = <ForecastEvent>[];
    for (final shift in snapshot.shifts) {
      if (shift.status != ShiftStatus.scheduled.value) continue;
      if (shift.endAt == null) continue;
      final end = DateTime.fromMillisecondsSinceEpoch(shift.endAt!);
      if (end.isBefore(start) || end.isAfter(horizonEnd)) continue;
      final job = jobsById[shift.jobId];
      if (job == null) continue;
      final earnings = ShiftEarnings.forShift(shift, job);
      final rateStr =
          '${job.currencyCode} ${(job.hourlyRateMinor / 100).toStringAsFixed(job.hourlyRateMinor % 100 == 0 ? 0 : 2)}/h';
      events.add(
        ForecastEvent(
          date: AppDate.dateOnly(end),
          label: '${job.name} shift',
          deltaMinor: snapshot.convert(
            earnings.earningsMinor,
            job.currencyCode,
          ),
          kind: ForecastEventKind.shift,
          rateFormatted: rateStr,
        ),
      );
    }
    return events;
  }

  List<GoalForecast> _goalForecasts(
    FinanceSnapshot snapshot,
    List<ForecastPoint> points,
    DateTime start,
    DateTime horizonEnd,
  ) {
    final activeGoals =
        snapshot.goals.where((goal) => !goal.isArchived).toList();
    final priorityOrder = {'high': 0, 'normal': 1, 'low': 2};
    activeGoals.sort((a, b) {
      final pA = priorityOrder[a.priority] ?? 1;
      final pB = priorityOrder[b.priority] ?? 1;
      final cmp = pA.compareTo(pB);
      if (cmp != 0) return cmp;
      return (a.targetDate ?? 9999999999999).compareTo(b.targetDate ?? 9999999999999);
    });

    final results = <GoalForecast>[];

    for (final goal in activeGoals) {
      final contributions = snapshot.contributions
          .where((contribution) => contribution.goalId == goal.id)
          .fold(0, (sum, contribution) => sum + contribution.amountMinor);
      final linkedBalance =
          goal.accountId != null ? snapshot.balanceOf(goal.accountId!) : 0;
      final effectiveSavedMinor =
          goal.accountId != null
              ? (linkedBalance > 0 ? linkedBalance : contributions)
              : contributions;
      final saved = snapshot.convert(
        effectiveSavedMinor,
        goal.currencyCode,
      );
      final targetDate =
          goal.targetDate == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(goal.targetDate!);
      final progress = GoalProgress(
        targetMinor: goal.targetAmountMinor,
        savedMinor: saved,
        targetDate: targetDate,
        now: snapshot.now,
      );

      final projectionDate =
          targetDate == null || targetDate.isAfter(horizonEnd)
              ? horizonEnd
              : targetDate;
      final projectedBase = _balanceAt(points, projectionDate);
      final projected = snapshot.convert(projectedBase, snapshot.baseCurrency);

      // Reserve the targets of other goals that are due no later than this one.
      var reserved = 0;
      for (final other in activeGoals) {
        if (other.id == goal.id || other.targetDate == null) continue;
        final otherDate = DateTime.fromMillisecondsSinceEpoch(
          other.targetDate!,
        );
        if (!otherDate.isAfter(projectionDate)) {
          reserved += snapshot.convert(
            other.targetAmountMinor,
            other.currencyCode,
          );
        }
      }

      final available = projected - reserved;
      final shortfall = goal.targetAmountMinor - available;
      results.add(
        GoalForecast(
          goal: goal,
          progress: progress,
          projectedMinor: available,
          shortfallMinor: shortfall > 0 ? shortfall : 0,
          onTrack: shortfall <= 0,
        ),
      );
    }
    return results;
  }

  int _balanceAt(List<ForecastPoint> points, DateTime date) {
    if (points.isEmpty) return 0;
    if (!date.isAfter(points.last.date)) {
      for (final point in points) {
        if (!point.date.isBefore(date)) return point.balanceMinor;
      }
    }
    return points.last.balanceMinor;
  }
}

/// Convenience for building a one-off scenario event (e.g. "add a
/// subscription") that can be fed into [ForecastEngine.project].
ForecastEvent scenarioEvent({
  required DateTime date,
  required String label,
  required int deltaMinor,
  ForecastEventKind kind = ForecastEventKind.subscription,
}) => ForecastEvent(
  date: AppDate.dateOnly(date),
  label: label,
  deltaMinor: deltaMinor,
  kind: kind,
);
