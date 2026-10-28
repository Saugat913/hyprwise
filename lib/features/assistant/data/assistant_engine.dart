import 'package:finance_tracker/features/alerts/data/advice_engine.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

/// A structured response from the assistant. Calculations are deterministic;
/// the wording is assembled from the numbers the engines produced.
class AssistantAnswer {
  const AssistantAnswer({
    String? headline,
    String? title,
    required this.body,
    this.explanation,
    this.suggestions = const [],
    this.followUps = const [],
  }) : headline = headline ?? title ?? '';

  final String headline;
  final String body;
  final String? explanation;
  final List<String> suggestions;
  final List<String> followUps;
}

/// A local, privacy-first financial assistant.
///
/// It never calls a network or an LLM. It classifies the question, runs the
/// same deterministic engines that power the rest of the app, and explains the
/// result. This keeps advice honest and reproducible.
class AssistantEngine {
  const AssistantEngine({
    this.forecast = const ForecastEngine(),
    this.advice = const AdviceEngine(),
  });

  final ForecastEngine forecast;
  final AdviceEngine advice;

  static const starterPrompts = <String>[
    'Can I afford a 400 dollar purchase?',
    'Why am I not reaching my savings goal?',
    'Where am I overspending?',
    'What happens if I work 5 more hours a week?',
    'How much money do I have right now?',
  ];

  AssistantAnswer answer(FinanceSnapshot snapshot, String query) {
    final text = query.toLowerCase().trim();
    if (text.isEmpty) return _overview(snapshot);

    // Greetings & assistant identity
    if (_hasAny(text, [
      'hello',
      'hi',
      'hey',
      'namaste',
      'good morning',
      'good evening',
      'who are you',
      'what can you do',
    ])) {
      return _greeting(snapshot);
    }

    // Specific category or merchant spending query (e.g. "how much did I spend on groceries")
    if (_hasAny(text, [
      'spend on',
      'spent on',
      'spent at',
      'spend at',
      'for groceries',
      'on food',
      'on groceries',
      'on dining',
      'on transport',
      'on shopping',
      'on utilities',
      'on entertainment',
      'on health',
      'how much for',
    ])) {
      return _spendingOn(snapshot, text);
    }

    if (_hasAny(text, ['afford', 'can i buy', 'should i buy'])) {
      return _affordability(snapshot, text);
    }
    if (_hasAny(text, ['goal', 'saving', 'save', 'target', 'tuition'])) {
      return _goalGap(snapshot);
    }
    if (_hasAny(text, [
      'overspend',
      'overspending',
      'spending too much',
      'where is my money',
      'wasting',
      'spend this month',
      'expenses this month',
    ])) {
      return _overspending(snapshot);
    }
    if (_hasAny(text, [
      'upcoming shift',
      'next shift',
      'my shift',
      'work shift',
      'schedule',
      'when do i work',
      'shifts this week',
    ])) {
      return _shiftsSummary(snapshot);
    }
    if (_hasAny(text, [
      'more hours',
      'extra shift',
      'work more',
      'overtime',
      'work 5',
    ])) {
      return _moreHours(snapshot, text);
    }
    if (_hasAny(text, [
      'how much',
      'balance',
      'net worth',
      'money do i have',
      'position',
      'my money',
    ])) {
      return _position(snapshot);
    }

    // Strict boundary: if outside domain or unknown, decline with honest "I don't know that"
    return _unknownResponse();
  }

  AssistantAnswer _greeting(FinanceSnapshot snapshot) {
    return const AssistantAnswer(
      headline: 'Hello!',
      body:
          'I am Hypr AI, your personal finance and shift management assistant. I can check your account balances, summarize your spending, track upcoming shifts, or record transactions.',
      suggestions: [
        'How much money do I have right now?',
        'Where am I overspending?',
        'What are my upcoming shifts?',
      ],
    );
  }

  AssistantAnswer _spendingOn(FinanceSnapshot snapshot, String text) {
    final categories = [
      'groceries',
      'dining',
      'transport',
      'utilities',
      'shopping',
      'health',
      'entertainment',
      'food',
      'bills',
      'rent',
    ];
    String? matchedCategory;
    for (final cat in categories) {
      if (text.contains(cat)) {
        matchedCategory = cat;
        break;
      }
    }

    final matchingTxs =
        snapshot.transactions.where((t) {
          if (t.type != TransactionType.expense.value) return false;
          final cat = t.category.toLowerCase();
          final note = (t.note ?? '').toLowerCase();
          if (matchedCategory != null &&
              (cat.contains(matchedCategory) ||
                  (matchedCategory == 'food' &&
                      (cat.contains('dining') || cat.contains('groceries'))))) {
            return true;
          }
          return text.contains(cat) || (note.isNotEmpty && text.contains(note));
        }).toList();

    final label =
        matchedCategory != null ? _pretty(matchedCategory) : 'that category';

    if (matchingTxs.isEmpty) {
      return AssistantAnswer(
        headline: 'No records found',
        body:
            "I don't have any recorded transactions for '$label' in your accounts.",
        suggestions: const [
          'How much do I have right now?',
          'Where am I overspending?',
        ],
      );
    }

    final totalMinor = matchingTxs.fold<int>(
      0,
      (sum, t) =>
          sum +
          snapshot.convert(t.amountMinor, snapshot.currencyOf(t.accountId)),
    );
    final formattedTotal = MoneyFormatter.format(
      totalMinor,
      snapshot.baseCurrency,
    );

    return AssistantAnswer(
      headline: 'Spending on $label',
      body:
          'You have spent $formattedTotal on $label across ${matchingTxs.length} recorded transaction${matchingTxs.length == 1 ? "" : "s"}.',
      suggestions: const [
        'Where am I overspending?',
        'Can I afford a purchase?',
      ],
    );
  }

  AssistantAnswer _shiftsSummary(FinanceSnapshot snapshot) {
    final now = snapshot.now;
    final upcoming =
        snapshot.shifts.where((s) {
          final st = DateTime.fromMillisecondsSinceEpoch(s.startAt);
          return st.isAfter(now.subtract(const Duration(hours: 2))) &&
              s.status != ShiftStatus.cancelled.value;
        }).toList();

    if (upcoming.isEmpty) {
      return const AssistantAnswer(
        headline: 'No upcoming shifts',
        body: 'You have no upcoming shifts scheduled in your shift planner.',
        suggestions: ['How much money do I have right now?'],
      );
    }

    final jobsById = {for (final j in snapshot.jobs) j.id: j};
    final items = upcoming
        .take(3)
        .map((s) {
          final job = jobsById[s.jobId];
          final st = DateTime.fromMillisecondsSinceEpoch(s.startAt);
          return '${job?.name ?? "Work"}: ${DateFormatter.numeric(st)} at ${st.hour}:${st.minute.toString().padLeft(2, '0')}';
        })
        .join('; ');

    return AssistantAnswer(
      headline: 'Upcoming Work Shifts',
      body:
          'You have ${upcoming.length} upcoming shift${upcoming.length == 1 ? "" : "s"}: $items.',
      suggestions: ['What happens if I work 5 more hours a week?'],
    );
  }

  AssistantAnswer _unknownResponse() {
    return const AssistantAnswer(
      headline: "I don't know that",
      body:
          "I don't know that. I am Hyprwise, your personal finance and shift management assistant. I only have access to your personal financial records, accounts, and shift planner.",
      suggestions: [
        'How much do I have right now?',
        'Where am I overspending?',
        'What are my upcoming shifts?',
      ],
    );
  }

  AssistantAnswer _affordability(FinanceSnapshot snapshot, String text) {
    final amount = _extractAmountMinor(text);
    final projection = forecast.project(snapshot);
    final currency = snapshot.baseCurrency;
    if (amount == null) {
      return AssistantAnswer(
        headline: 'How much is it?',
        body:
            'I can check any purchase against your projected balance. For example, '
            '"Can I afford ${MoneyFormatter.format(40000, currency)}?" — I will compare it '
            'with your balance and upcoming bills.',
        followUps: const [
          'Can I afford a 300 purchase?',
          'What are my upcoming bills?',
        ],
      );
    }

    final balanceNow = snapshot.netWorthMinor;
    final inThirty = projection.balanceAt(
      snapshot.now.add(const Duration(days: 30)),
    );
    final afterPurchase = balanceNow - amount;
    final affordable = afterPurchase >= 0 && inThirty - amount >= 0;

    final suggestions = <String>[];
    if (!affordable) {
      suggestions.add('Delay it until after your next payday or shift payout.');
      suggestions.add(
        'Trim a subscription for a month to free the same amount.',
      );
    } else {
      suggestions.add(
        'You can still cover this and stay positive for 30 days.',
      );
    }

    return AssistantAnswer(
      headline:
          affordable
              ? 'Yes — you can likely afford this.'
              : 'This would stretch you thin.',
      body:
          'Spending ${MoneyFormatter.format(amount, currency)} now would leave '
          '${MoneyFormatter.format(afterPurchase, currency)}. In 30 days you are projected to hold '
          '${MoneyFormatter.format(inThirty, currency)}, so this purchase would leave '
          '${MoneyFormatter.format(inThirty - amount, currency)}. '
          '${affordable ? 'It fits, but keep upcoming bills in mind.' : 'That is too close to your upcoming obligations.'}',
      suggestions: suggestions,
      followUps: const [
        'Where am I overspending?',
        'What are my upcoming bills?',
      ],
    );
  }

  AssistantAnswer _goalGap(FinanceSnapshot snapshot) {
    final projection = forecast.project(snapshot);
    final atRisk = projection.goalForecasts.where((g) => !g.onTrack).toList();
    if (atRisk.isEmpty) {
      final goals = projection.goalForecasts;
      if (goals.isEmpty) {
        return AssistantAnswer(
          headline: 'You have no goals yet',
          body:
              'Create a goal — like a tuition target — and I will track whether you are on pace and why.',
          followUps: const ['How much money do I have right now?'],
        );
      }
      final goal = goals.first;
      return AssistantAnswer(
        headline: '${goal.goal.name} is on track',
        body:
            'You are projected to hold ${MoneyFormatter.format(goal.projectedMinor, goal.goal.currencyCode)} '
            'by the target, against ${MoneyFormatter.format(goal.goal.targetAmountMinor, goal.goal.currencyCode)} needed. '
            'Keep the current pace and you are set.',
        followUps: const [
          'Where am I overspending?',
          'What happens if I work 5 more hours a week?',
        ],
      );
    }

    final goal = atRisk.first;
    final requiredMonthly = goal.progress.requiredMonthlyMinor;
    return AssistantAnswer(
      headline: '${goal.goal.name} is trending short',
      body:
          'At your current pace you are projected to have '
          '${MoneyFormatter.format(goal.projectedMinor, goal.goal.currencyCode)} by '
          '${goal.goal.targetDate == null ? 'the target' : DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(goal.goal.targetDate!))}, '
          'about ${MoneyFormatter.format(goal.shortfallMinor, goal.goal.currencyCode)} short. '
          '${requiredMonthly == null ? '' : 'Saving roughly ${MoneyFormatter.format(requiredMonthly, goal.goal.currencyCode)} a month closes the gap.'}',
      suggestions: [
        'Move the shortfall to a monthly transfer you will not touch.',
        'Cut the fastest-growing expense category for the next 60 days.',
        'Add one extra shift a week until the gap is gone.',
      ],
      followUps: const [
        'Where am I overspending?',
        'What happens if I work 5 more hours a week?',
      ],
    );
  }

  AssistantAnswer _overspending(FinanceSnapshot snapshot) {
    final month = snapshot.now;
    final spend = <String, int>{};
    for (final transaction in snapshot.transactions) {
      if (transaction.type != TransactionType.expense.value) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
      if (!snapshot.isInMonth(date, month)) continue;
      final amount = snapshot.convert(
        transaction.amountMinor,
        snapshot.currencyOf(transaction.accountId),
      );
      spend.update(
        transaction.category,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    final top =
        spend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final lines =
        top
            .take(3)
            .map(
              (entry) =>
                  '${_pretty(entry.key)}: ${MoneyFormatter.format(entry.value, snapshot.baseCurrency)}',
            )
            .toList();

    if (lines.isEmpty) {
      return AssistantAnswer(
        headline: 'Nothing stands out yet',
        body:
            'You have not recorded enough spending this month for me to spot a pattern.',
        followUps: const ['How much money do I have right now?'],
      );
    }

    return AssistantAnswer(
      headline: 'Your biggest categories this month',
      body: 'Largest spend: ${lines.join(', ')}.',
      suggestions: const [
        'Pause one subscription and redirect it to your goal.',
        'Cut the biggest category by 10% for the next month.',
      ],
      followUps: const ['Why am I not reaching my savings goal?'],
    );
  }

  AssistantAnswer _moreHours(FinanceSnapshot snapshot, String text) {
    final extraHours = _extractNumber(text) ?? 5;
    final job = snapshot.jobs.where((job) => job.isActive).firstOrNull;
    if (job == null) {
      return AssistantAnswer(
        headline: 'Add a job first',
        body:
            'Create a job with an hourly rate and I can model extra hours for you.',
        followUps: const ['How much money do I have right now?'],
      );
    }
    final hourly = job.hourlyRateMinor;
    final weeklyExtra = (hourly * extraHours).round();
    final monthlyExtra = snapshot.convert(
      (weeklyExtra * 4.345).round(),
      job.currencyCode,
    );
    final fourMonth = monthlyExtra * 4;

    return AssistantAnswer(
      headline:
          'About ${MoneyFormatter.format(weeklyExtra, job.currencyCode)} more per week',
      body:
          'Working ${_trim(extraHours)} extra hours a week at ${MoneyFormatter.format(hourly, job.currencyCode)}/hour '
          'adds roughly ${MoneyFormatter.format(monthlyExtra, snapshot.baseCurrency)} a month — '
          'about ${MoneyFormatter.format(fourMonth, snapshot.baseCurrency)} over four months. '
          'That is real progress against your goal.',
      suggestions: [
        'Block the extra hours as scheduled shifts so the forecast includes them.',
        'Route the extra income straight to your goal.',
      ],
      followUps: const ['Why am I not reaching my savings goal?'],
    );
  }

  AssistantAnswer _position(FinanceSnapshot snapshot) {
    final parts = <String>[];
    for (final currency in snapshot.activeCurrencies) {
      final total = snapshot.activeAccounts
          .where((account) => account.currencyCode == currency)
          .fold(0, (sum, account) => sum + snapshot.balanceOf(account.id));
      parts.add(MoneyFormatter.format(total, currency));
    }
    final net = snapshot.netWorthMinor;
    return AssistantAnswer(
      headline:
          'You hold ${MoneyFormatter.format(net, snapshot.baseCurrency)} in total',
      body:
          parts.isEmpty
              ? 'Add an account to see your position.'
              : 'Across your accounts: ${parts.join(', ')}. '
                  'That total is expressed in ${snapshot.baseCurrency} using your stored rates.',
      followUps: const [
        'Can I afford a 200 purchase?',
        'Where am I overspending?',
      ],
    );
  }

  AssistantAnswer _overview(FinanceSnapshot snapshot) {
    final projection = forecast.project(snapshot);
    final alerts = advice.generate(snapshot, forecast: projection);
    final lead = alerts.isNotEmpty ? alerts.first : null;
    final work = _completedHoursThisWeek(snapshot);

    return AssistantAnswer(
      headline: 'Here is where you stand',
      body: [
        'You hold ${MoneyFormatter.format(snapshot.netWorthMinor, snapshot.baseCurrency)} today.',
        'In 90 days you are projected to hold ${MoneyFormatter.format(projection.endMinor, snapshot.baseCurrency)}.',
        if (work > 0)
          'You have worked ${work.toStringAsFixed(1)} hours this week.',
        if (lead != null) '${lead.title}: ${lead.message}',
      ].join(' '),
      suggestions: const [
        'Ask me if you can afford a purchase.',
        'Ask where you are overspending.',
        'Ask what extra hours would change.',
      ],
      followUps: starterPrompts.sublist(1, 4),
    );
  }

  double _completedHoursThisWeek(FinanceSnapshot snapshot) {
    final jobsById = {for (final job in snapshot.jobs) job.id: job};
    final (start, end) = InsightsPeriodRange.week(snapshot.now);
    var minutes = 0;
    for (final shift in snapshot.shifts) {
      if (shift.status != ShiftStatus.completed.value) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
      if (date.isBefore(start) || date.isAfter(end)) continue;
      final job = jobsById[shift.jobId];
      if (job == null) continue;
      minutes += ShiftEarnings.forShift(shift, job).workedMinutes;
    }
    return minutes / 60;
  }

  static bool _hasAny(String text, List<String> needles) =>
      needles.any(text.contains);

  static int? _extractAmountMinor(String text) {
    final match = RegExp(r'(\d[\d,]*\.?\d*)').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
    if (value == null) return null;
    return (value * 100).round();
  }

  static double? _extractNumber(String text) {
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(text);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  static String _trim(double value) =>
      value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();

  static String _pretty(String key) {
    final spaced = key.replaceAll('_', ' ');
    return spaced.isEmpty ? key : spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// Small helper so the assistant can ask the insights engine for a week range
/// without importing the whole feature.
abstract final class InsightsPeriodRange {
  static (DateTime, DateTime) week(DateTime now) {
    final end = AppDate.dateOnly(now);
    final start = end.subtract(Duration(days: end.weekday - DateTime.monday));
    return (start, end);
  }
}
