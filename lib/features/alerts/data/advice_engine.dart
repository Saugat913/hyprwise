import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/alerts/data/model/alerts.dart';
import 'package:finance_tracker/features/money/data/model/recurring.dart';

/// Turns raw financial state into explained, consequence-aware advice.
///
/// Every recommendation states what changed and what it costs, in the user's
/// own goals and currency — never just that a rule was broken.
class AdviceEngine {
  const AdviceEngine({this.engine = const ForecastEngine()});

  final ForecastEngine engine;

  List<FinanceAlert> generate(
    FinanceSnapshot snapshot, {
    ForecastResult? forecast,
  }) {
    final projection = forecast ?? engine.project(snapshot);
    final alerts = <FinanceAlert>[
      ..._goalAdvice(snapshot, projection),
      ..._cashflowAdvice(snapshot, projection),
      ..._upcomingPayments(snapshot),
    ];
    alerts.sort((a, b) => _rank(b.severity).compareTo(_rank(a.severity)));
    return alerts;
  }

  List<FinanceAlert> _goalAdvice(
    FinanceSnapshot snapshot,
    ForecastResult forecast,
  ) {
    final alerts = <FinanceAlert>[];
    for (final goalForecast in forecast.goalForecasts) {
      final goal = goalForecast.goal;
      if (goalForecast.onTrack) {
        continue;
      }
      final shortfall = goalForecast.shortfallMinor;
      final requiredMonthly = goalForecast.progress.requiredMonthlyMinor;
      final suggestion =
          requiredMonthly == null
              ? 'Add contributions regularly to close the gap.'
              : 'Saving about ${MoneyFormatter.format(requiredMonthly, goal.currencyCode)} '
                  'a month would put you back on track.';
      alerts.add(
        FinanceAlert(
          severity: AlertSeverity.critical,
          title: '${goal.name} may fall short',
          message:
              'Projected ${MoneyFormatter.format(goalForecast.projectedMinor, goal.currencyCode)} '
              'against a ${MoneyFormatter.format(goal.targetAmountMinor, goal.currencyCode)} target — '
              'roughly ${MoneyFormatter.format(shortfall, goal.currencyCode)} short. $suggestion',
          impactMinor: shortfall,
          currencyCode: goal.currencyCode,
        ),
      );
    }
    return alerts;
  }

  List<FinanceAlert> _cashflowAdvice(
    FinanceSnapshot snapshot,
    ForecastResult forecast,
  ) {
    final alerts = <FinanceAlert>[];
    for (final point in forecast.points) {
      if (point.balanceMinor < 0) {
        alerts.add(
          FinanceAlert(
            severity: AlertSeverity.critical,
            title: 'Projected balance goes negative',
            message:
                'At the current pace you run out around ${DateFormatter.numeric(point.date)}. '
                'Shift a bill, slow spending, or plan an extra shift.',
            currencyCode: snapshot.baseCurrency,
          ),
        );
        break;
      }
    }
    return alerts;
  }

  List<FinanceAlert> _upcomingPayments(FinanceSnapshot snapshot) {
    final alerts = <FinanceAlert>[];
    final horizon = snapshot.now.add(const Duration(days: 7));
    for (final rule in snapshot.recurring) {
      if (!rule.isActive) continue;
      final kind = RecurringKind.fromValue(rule.kind);
      if (!kind.isOutgoing) continue;
      final due = DateTime.fromMillisecondsSinceEpoch(rule.nextDueAt);
      if (due.isBefore(AppDate.dateOnly(snapshot.now)) ||
          due.isAfter(horizon)) {
        continue;
      }
      alerts.add(
        FinanceAlert(
          severity: AlertSeverity.info,
          title:
              '${rule.name} due ${DateFormatter.relative(due, now: snapshot.now).toLowerCase()}',
          message:
              '${MoneyFormatter.format(rule.amountMinor, rule.currencyCode)} leaves your account '
              'on ${DateFormatter.numeric(due)}.',
          category: rule.category,
          currencyCode: rule.currencyCode,
        ),
      );
    }
    return alerts;
  }

  /// The change in a goal's projected safety margin caused by a recurring
  /// monthly change of [monthlyDeltaMinor] (negative for new spending).
  int? marginImpactOnGoal(
    FinanceSnapshot snapshot,
    int goalId,
    int monthlyDeltaMinor,
  ) {
    final goal = snapshot.goals.firstWhere(
      (candidate) => candidate.id == goalId,
      orElse: () => snapshot.goals.first,
    );
    final targetDate =
        goal.targetDate == null
            ? snapshot.now.add(const Duration(days: 90))
            : DateTime.fromMillisecondsSinceEpoch(goal.targetDate!);
    final horizon =
        targetDate.difference(AppDate.dateOnly(snapshot.now)).inDays;
    if (horizon <= 0) return null;

    final extra = <ForecastEvent>[];
    var date = AppDate.dateOnly(snapshot.now);
    while (date.isBefore(targetDate)) {
      extra.add(
        ForecastEvent(
          date: date,
          label: 'Scenario',
          deltaMinor: monthlyDeltaMinor,
          kind: ForecastEventKind.expense,
        ),
      );
      date = DateTime(date.year, date.month + 1, date.day);
    }

    final base = engine.project(snapshot, horizonDays: horizon);
    final scenario = engine.project(
      snapshot,
      horizonDays: horizon,
      extraEvents: extra,
    );
    final baseGoal = _forecastForGoal(base, goalId);
    final scenarioGoal = _forecastForGoal(scenario, goalId);
    if (baseGoal == null || scenarioGoal == null) return null;
    return scenarioGoal.projectedMinor - baseGoal.projectedMinor;
  }

  GoalForecast? _forecastForGoal(ForecastResult forecast, int goalId) {
    for (final goalForecast in forecast.goalForecasts) {
      if (goalForecast.goal.id == goalId) return goalForecast;
    }
    return null;
  }

  static int _rank(AlertSeverity severity) => switch (severity) {
    AlertSeverity.critical => 3,
    AlertSeverity.warning => 2,
    AlertSeverity.info => 1,
    AlertSeverity.success => 0,
  };
}
