import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/shared/data/snapshot_stats.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

typedef BalancePoint = ({DateTime date, int minor});

class HeroAccountSlice {
  const HeroAccountSlice({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balanceInBaseMinor,
    required this.balanceMinor,
    required this.isSpendable,
  });

  final int id;
  final String name;
  final String type;
  final String currency;
  final int balanceInBaseMinor;
  final int balanceMinor;
  final bool isSpendable;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.financeStore, required this.settingsRepo}) {
    financeStore.addListener(_onStoreChanged);
    settingsRepo.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final SettingsRepository settingsRepo;

  void _onStoreChanged() {
    _invalidateHeroCaches();
    notifyListeners();
  }

  FinanceSnapshot get snapshot => financeStore.snapshot;
  String get baseCurrency => financeStore.baseCurrency;
  DateTime get now => snapshot.now;

  int get netWorthMinor => snapshot.netWorthMinor;
  int get netPositionMinor => netWorthMinor + netDebtMinor;

  /// Liquid funds that can be actively spent from everyday accounts.
  int get usableBalanceMinor => snapshot.accounts
      .where(
        (a) =>
            !a.isArchived &&
            (a.type == 'bank' ||
                a.type == 'cash' ||
                a.type == 'wallet' ||
                a.name.toLowerCase() == 'everyday'),
      )
      .fold<int>(
        0,
        (sum, a) =>
            sum + snapshot.convert(snapshot.balanceOf(a.id), a.currencyCode),
      );

  /// Non-usable balance representing savings, locked funds, and net debts.
  /// Guarantees usableBalanceMinor + nonUsableBalanceMinor == netPositionMinor.
  int get nonUsableBalanceMinor => netPositionMinor - usableBalanceMinor;

  /// Sum of non-archived savings accounts converted to base currency.
  int get savingsTotalMinor => snapshot.accounts
      .where((a) => !a.isArchived && a.type == 'savings')
      .fold<int>(
        0,
        (sum, a) =>
            sum + snapshot.convert(snapshot.balanceOf(a.id), a.currencyCode),
      );

  /// Clamped ratio of usable balance over positive net position (0.0 .. 1.0).
  double get usableRatio {
    final total = netPositionMinor;
    if (total <= 0 || usableBalanceMinor <= 0) return 0.0;
    return (usableBalanceMinor / total).clamp(0.0, 1.0);
  }

  /// Clamped ratio of non-usable balance over positive net position (0.0 .. 1.0).
  double get nonUsableRatio {
    final total = netPositionMinor;
    if (total <= 0 || nonUsableBalanceMinor <= 0) return 0.0;
    return (nonUsableBalanceMinor / total).clamp(0.0, 1.0);
  }

  bool get hasAccounts => snapshot.accounts.isNotEmpty;
  bool get hasJobs => snapshot.jobs.isNotEmpty;
  bool get hasGoals => snapshot.goals.isNotEmpty;
  bool get hasAlerts =>
      settingsRepo.settings.shiftReminders || settingsRepo.settings.billsDue;

  int get setupCompletedCount {
    var count = 0;
    if (hasAccounts) count++;
    if (hasJobs) count++;
    if (hasGoals) count++;
    if (hasAlerts) count++;
    return count;
  }

  bool get isSetupComplete => setupCompletedCount == 4;

  ForecastResult get forecast => financeStore.forecast(horizonDays: 30);

  List<ForecastEvent> get upcomingEvents {
    final list = <ForecastEvent>[];

    // Priority 1: Shifts occurring today (scheduled or active)
    final today = AppDate.dateOnly(now);
    final jobsById = {for (final j in snapshot.jobs) j.id: j};

    final todayShifts =
        snapshot.shifts.where((s) {
          final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
          return AppDate.dateOnly(start) == today;
        }).toList();

    for (final shift in todayShifts) {
      final job = jobsById[shift.jobId];
      if (job == null) continue;
      final tr = AppStrings.current();
      final earnings = ShiftEarnings.forShift(shift, job);
      final rateStr =
          '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)}/${tr.hourAbbr}';
      list.add(
        ForecastEvent(
          date: today,
          label: tr.jobShiftTitle(job.name),
          deltaMinor: earnings.earningsMinor,
          kind: ForecastEventKind.shift,
          rateFormatted: rateStr,
        ),
      );
    }

    // Priority 2: Forecast events within 7 days
    final forecastList = forecast.upcomingWithin(7, now);
    for (final event in forecastList) {
      if (event.kind == ForecastEventKind.shift &&
          AppDate.dateOnly(event.date) == today &&
          todayShifts.isNotEmpty) {
        // Skip duplicate today shift already added directly from snapshot
        continue;
      }
      list.add(event);
    }

    return list;
  }

  List<Debt> get activeDebts =>
      financeStore.debts.where((d) => !d.isSettled).toList();

  int get totalLentMinor => financeStore.debts
      .where((d) => d.type == DebtType.lent.value && !d.isSettled)
      .fold<int>(0, (sum, d) => sum + d.amountMinor);

  int get totalBorrowedMinor => financeStore.debts
      .where((d) => d.type == DebtType.borrowed.value && !d.isSettled)
      .fold<int>(0, (sum, d) => sum + d.amountMinor);

  int get netDebtMinor => totalLentMinor - totalBorrowedMinor;

  int get everydayBalanceMinor {
    final acc = financeStore.everydayAccount;
    return acc != null ? snapshot.balanceOf(acc.id) : 0;
  }

  int get savingsBalanceMinor {
    final acc = financeStore.savingsAccount;
    return acc != null ? snapshot.balanceOf(acc.id) : 0;
  }

  List<Account> get accounts => financeStore.accounts;
  List<Account> get savingsAccounts =>
      snapshot.accounts
          .where((a) => a.type == AccountType.savings.value)
          .toList();
  int balanceOf(int accountId) => snapshot.balanceOf(accountId);

  List<Transaction> get recentTransactions =>
      snapshot.transactions.take(5).toList();

  int get monthIncome {
    final start = DateTime(now.year, now.month);
    return snapshot.incomeInMonth(start);
  }

  int get monthExpense {
    final start = DateTime(now.year, now.month);
    return snapshot.expenseInMonth(start);
  }

  /// Completed work is distinct from manually recorded income. Home surfaces
  /// it separately so shift workers can understand their verified earnings.
  List<Shift> get completedShiftsThisMonth =>
      snapshot.shifts.where((shift) {
        if (shift.status != ShiftStatus.completed.value) return false;
        final date = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
        return date.year == now.year && date.month == now.month;
      }).toList();

  int get completedShiftCountThisMonth => completedShiftsThisMonth.length;

  int get workedMinutesThisMonth {
    final jobs = {for (final job in snapshot.jobs) job.id: job};
    return completedShiftsThisMonth.fold<int>(0, (sum, shift) {
      final job = jobs[shift.jobId];
      return sum +
          (job == null ? 0 : ShiftEarnings.forShift(shift, job).workedMinutes);
    });
  }

  int get shiftEarningsThisMonth {
    final jobs = {for (final job in snapshot.jobs) job.id: job};
    return completedShiftsThisMonth.fold<int>(0, (sum, shift) {
      final job = jobs[shift.jobId];
      if (job == null) return sum;
      final earnings = ShiftEarnings.forShift(shift, job).earningsMinor;
      return sum + snapshot.convert(earnings, job.currencyCode);
    });
  }

  List<int> get weekIncome => snapshot.dailyTotals(TransactionType.income);
  List<int> get weekExpense => snapshot.dailyTotals(TransactionType.expense);

  /// Share of this month's income that was not spent (0..1).
  double get savingsRate {
    final inc = monthIncome;
    if (inc <= 0) return 0;
    return ((inc - monthExpense) / inc).clamp(0.0, 1.0);
  }

  MapEntry<String, int>? get topCategory {
    final list = snapshot.topSpendCategories;
    return list.isEmpty ? null : list.first;
  }

  /// Top expense categories for this month, ordered by largest spend first.
  List<MapEntry<String, int>> get topSpendingCategories =>
      snapshot.topSpendCategories;

  /// Bills and subscriptions falling due within the next 7 days.
  List<ForecastEvent> get billsDueSoon =>
      forecast
          .upcomingWithin(7, now)
          .where(
            (e) =>
                e.kind == ForecastEventKind.bill ||
                e.kind == ForecastEventKind.subscription,
          )
          .toList();

  List<double> get sparklinePoints {
    if (forecast.points.isEmpty) return const [];
    final pts = forecast.points.map((p) => p.balanceMinor.toDouble()).toList();
    if (pts.length <= 8) return pts;
    final step = pts.length / 8;
    return [for (var i = 0; i < 8; i++) pts[(i * step).floor()]];
  }

  // --- Redesigned Home Hero Series & Data ---

  final Map<int, List<BalancePoint>> _balanceSeriesCache = {};
  List<BalancePoint>? _forecastSeriesCache;
  List<({String label, int income, int expense})>? _monthWeeklyBucketsCache;
  List<HeroAccountSlice>? _accountSlicesCache;

  void _invalidateHeroCaches() {
    _balanceSeriesCache.clear();
    _forecastSeriesCache = null;
    _monthWeeklyBucketsCache = null;
    _accountSlicesCache = null;
  }

  /// Ordered account slices for the hero account stack bar and table.
  List<HeroAccountSlice> get accountSlices {
    if (_accountSlicesCache != null) return _accountSlicesCache!;

    final active = snapshot.accounts.where((a) => !a.isArchived).toList();
    if (active.isEmpty) {
      return _accountSlicesCache = const [];
    }

    final everyday = financeStore.everydayAccount;
    final everydayId = everyday?.id;

    final slices = <HeroAccountSlice>[];
    for (final a in active) {
      final bal = snapshot.balanceOf(a.id);
      final balBase = snapshot.convert(bal, a.currencyCode);
      final isSpendable =
          a.type == 'bank' ||
          a.type == 'cash' ||
          a.type == 'wallet' ||
          a.name.toLowerCase() == 'everyday';
      slices.add(
        HeroAccountSlice(
          id: a.id,
          name: a.name,
          type: a.type,
          currency: a.currencyCode,
          balanceInBaseMinor: balBase,
          balanceMinor: bal,
          isSpendable: isSpendable,
        ),
      );
    }

    slices.sort((a, b) {
      if (a.id == everydayId) return -1;
      if (b.id == everydayId) return 1;
      if (a.isSpendable && !b.isSpendable) return -1;
      if (!a.isSpendable && b.isSpendable) return 1;
      return b.balanceInBaseMinor.compareTo(a.balanceInBaseMinor);
    });

    return _accountSlicesCache = slices;
  }

  /// Daily balance series for the past [pastDays] ending exactly at today's [netPositionMinor].
  List<BalancePoint> balanceSeries(int pastDays) {
    if (_balanceSeriesCache.containsKey(pastDays)) {
      return _balanceSeriesCache[pastDays]!;
    }

    final today = AppDate.dateOnly(now);
    final count = pastDays + 1;
    final dates = List.generate(
      count,
      (i) => today.subtract(Duration(days: pastDays - i)),
    );

    // Group transactions by date
    final dailyNet = <DateTime, int>{};
    for (final t in snapshot.transactions) {
      final tDate = AppDate.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(t.occurredAt),
      );
      final converted = snapshot.convert(
        t.amountMinor,
        snapshot.currencyOf(t.accountId),
      );
      final delta =
          t.type == TransactionType.income.value ? converted : -converted;
      dailyNet.update(tDate, (v) => v + delta, ifAbsent: () => delta);
    }

    // Work backwards from today's netPositionMinor
    final points = List<BalancePoint>.filled(count, (
      date: today,
      minor: netPositionMinor,
    ));
    var running = netPositionMinor;
    points[count - 1] = (date: today, minor: running);

    for (var i = count - 1; i >= 1; i--) {
      final curDate = dates[i];
      final dayMovement = dailyNet[curDate] ?? 0;
      running -= dayMovement;
      points[i - 1] = (date: dates[i - 1], minor: running);
    }

    return _balanceSeriesCache[pastDays] = points;
  }

  /// Forecast balance series for [days] horizon from recurring, shifts, bills, and goals.
  /// First point is today with [netPositionMinor]. If no scheduled data exists, returns empty.
  List<BalancePoint> forecastSeries({int days = 14}) {
    if (_forecastSeriesCache != null) return _forecastSeriesCache!;

    final fc = financeStore.forecast(horizonDays: days);
    if (fc.events.isEmpty || fc.points.isEmpty) {
      return _forecastSeriesCache = const [];
    }

    final today = AppDate.dateOnly(now);
    final list = <BalancePoint>[(date: today, minor: netPositionMinor)];

    for (final p in fc.points) {
      final pDate = AppDate.dateOnly(p.date);
      if (pDate.isAfter(today) && pDate.difference(today).inDays <= days) {
        list.add((date: pDate, minor: p.balanceMinor));
      }
    }

    return _forecastSeriesCache = list;
  }

  /// Weekly grouped aggregates for the current month (W1..W5).
  List<({String label, int income, int expense})> get monthWeeklyBuckets {
    if (_monthWeeklyBucketsCache != null) return _monthWeeklyBucketsCache!;

    final currentMonth = now;
    final totalDays =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    final ranges = <({int start, int end, String label})>[
      (start: 1, end: 7, label: '1-7'),
      (start: 8, end: 14, label: '8-14'),
      (start: 15, end: 21, label: '15-21'),
      (start: 22, end: 28, label: '22-28'),
      if (totalDays > 28) (start: 29, end: totalDays, label: '29-$totalDays'),
    ];

    final buckets = <({String label, int income, int expense})>[];

    for (final r in ranges) {
      var inc = 0;
      var exp = 0;
      for (final t in snapshot.transactions) {
        final date = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
        if (date.year == currentMonth.year &&
            date.month == currentMonth.month &&
            date.day >= r.start &&
            date.day <= r.end) {
          final amt = snapshot.convert(
            t.amountMinor,
            snapshot.currencyOf(t.accountId),
          );
          if (t.type == TransactionType.income.value) {
            inc += amt;
          } else if (t.type == TransactionType.expense.value) {
            exp += amt;
          }
        }
      }
      buckets.add((label: r.label, income: inc, expense: exp));
    }

    return _monthWeeklyBucketsCache = buckets;
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    settingsRepo.removeListener(_onStoreChanged);
    super.dispose();
  }
}
