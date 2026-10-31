import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/goals/data/forecast_engine.dart';
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
    final tr = AppStrings.current();
    final alerts = <FinanceAlert>[];
    for (final goalForecast in forecast.goalForecasts) {
      final goal = goalForecast.goal;
      if (goalForecast.onTrack) {
        continue;
      }
      final shortfall = goalForecast.shortfallMinor;
      final requiredMonthly = goalForecast.progress.requiredMonthlyMinor;
      final reqFmt = requiredMonthly != null
          ? MoneyFormatter.format(requiredMonthly, goal.currencyCode)
          : '';
      final suggestion =
          requiredMonthly == null
              ? tr.t(
                  'Add contributions regularly to close the gap.',
                  ne: 'अपुग रकम पूरा गर्न नियमित रूपमा बचत थप्नुहोस्।',
                  es: 'Añade aportes regularmente para cerrar la brecha.',
                  fr: 'Ajoutez des contributions régulières pour combler l\'écart.',
                  de: 'Fügen Sie regelmäßig Beiträge hinzu, um die Lücke zu schließen.',
                  ja: '定期的に積み立てて不足分を補いましょう。',
                  zh: '请定期存入资金以缩小差距。',
                  it: 'Aggiungi contributi regolarmente per colmare il divario.',
                )
              : tr.t(
                  'Saving about $reqFmt a month would put you back on track.',
                  ne: 'महिनामा करिब $reqFmt बचत गर्दा लक्ष्य समयमै पूरा हुनेछ।',
                  es: 'Ahorrar unos $reqFmt al mes te pondría de nuevo en camino.',
                  fr: 'Épargner environ $reqFmt par mois vous remettrait sur la bonne voie.',
                  de: 'Etwa $reqFmt pro Monat zu sparen bringt Sie wieder auf Kurs.',
                  ja: '毎月約 $reqFmt 貯金すると目標達成ペースに戻れます。',
                  zh: '每月大约存入 $reqFmt 即可重回正轨。',
                  it: 'Risparmiare circa $reqFmt al mese ti rimetterebbe in carreggiata.',
                );
      final projFmt = MoneyFormatter.format(goalForecast.projectedMinor, goal.currencyCode);
      final targetFmt = MoneyFormatter.format(goal.targetAmountMinor, goal.currencyCode);
      final shortFmt = MoneyFormatter.format(shortfall, goal.currencyCode);
      alerts.add(
        FinanceAlert(
          severity: AlertSeverity.critical,
          title: tr.alertGoalMayFallShort(goal.name),
          message: tr.t(
            'Projected $projFmt against a $targetFmt target — roughly $shortFmt short. $suggestion',
            ne: '$targetFmt लक्ष्यको तुलनामा अनुमानित $projFmt — करिब $shortFmt कम। $suggestion',
            es: 'Proyectado $projFmt frente a la meta de $targetFmt — faltan unos $shortFmt. $suggestion',
            fr: 'Projeté $projFmt sur un objectif de $targetFmt — environ $shortFmt manquant. $suggestion',
            de: 'Prognose $projFmt bei $targetFmt Ziel — ca. $shortFmt fehlen. $suggestion',
            ja: '目標 $targetFmt に対し予測 $projFmt（約 $shortFmt 不足）。$suggestion',
            zh: '目标 $targetFmt，预计达成 $projFmt（差约 $shortFmt）。$suggestion',
            it: 'Previsti $projFmt su un obiettivo di $targetFmt — mancano circa $shortFmt. $suggestion',
          ),
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
    final tr = AppStrings.current();
    final alerts = <FinanceAlert>[];
    for (final point in forecast.points) {
      if (point.balanceMinor < 0) {
        final dateStr = DateFormatter.numeric(point.date);
        alerts.add(
          FinanceAlert(
            severity: AlertSeverity.critical,
            title: tr.alertBalanceNegativeTitle,
            message: tr.t(
              'At the current pace you run out around $dateStr. Shift a bill, slow spending, or plan an extra shift.',
              ne: 'हालको गतिमा $dateStr तिर मौज्दात सकिन सक्छ। खर्च घटाउनुहोस् वा अतिरिक्त सिफ्ट योजना गर्नुहोस्।',
              es: 'Al ritmo actual te quedarás sin fondos hacia el $dateStr. Ajusta gastos o planea un turno extra.',
              fr: 'Au rythme actuel, vous serez à découvert vers le $dateStr. Réduisez les dépenses ou planifiez un quart.',
              de: 'Beim aktuellen Tempo reicht das Guthaben bis ca. $dateStr. Ausgaben senken oder Extraschicht planen.',
              ja: '現在のペースでは $dateStr 頃に残高不足になります。支出を抑えるか追加シフトを検討してください。',
              zh: '按目前的速度，预计在 $dateStr 左右余额不足。请适当节流或安排额外班次。',
              it: 'Al ritmo attuale finirai i fondi intorno al $dateStr. Riduci le spese o pianifica un turno extra.',
            ),
            currencyCode: snapshot.baseCurrency,
          ),
        );
        break;
      }
    }
    return alerts;
  }

  List<FinanceAlert> _upcomingPayments(FinanceSnapshot snapshot) {
    final tr = AppStrings.current();
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
      final relStr = DateFormatter.relative(due, now: snapshot.now).toLowerCase();
      final amtStr = MoneyFormatter.format(rule.amountMinor, rule.currencyCode);
      final dueStr = DateFormatter.numeric(due);
      alerts.add(
        FinanceAlert(
          severity: AlertSeverity.info,
          title: tr.alertBillDueTitle(rule.name, relStr),
          message: tr.t(
            '$amtStr leaves your account on $dueStr.',
            ne: '$dueStr मा तपाईंको खाताबाट $amtStr भुक्तानी हुनेछ।',
            es: '$amtStr saldrá de tu cuenta el $dueStr.',
            fr: '$amtStr sera débité de votre compte le $dueStr.',
            de: '$amtStr wird am $dueStr von Ihrem Konto abgebucht.',
            ja: '$dueStr に口座から $amtStr が引き落とされます。',
            zh: '$amtStr 将于 $dueStr 从您的账户扣除。',
            it: '$amtStr verrà addebitato sul tuo conto il $dueStr.',
          ),
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
