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

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this.financeStore,
    required this.settingsRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
    settingsRepo.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final SettingsRepository settingsRepo;

  void _onStoreChanged() {
    notifyListeners();
  }

  FinanceSnapshot get snapshot => financeStore.snapshot;
  String get baseCurrency => financeStore.baseCurrency;
  DateTime get now => snapshot.now;

  int get netWorthMinor => snapshot.netWorthMinor;
  int get netPositionMinor => netWorthMinor + netDebtMinor;

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

    final todayShifts = snapshot.shifts.where((s) {
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
      snapshot.accounts.where((a) => a.type == AccountType.savings.value).toList();
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

  /// Bills and subscriptions falling due within the next 7 days.
  List<ForecastEvent> get billsDueSoon => forecast
      .upcomingWithin(7, now)
      .where((e) => e.kind == ForecastEventKind.bill || e.kind == ForecastEventKind.subscription)
      .toList();

  List<double> get sparklinePoints {
    if (forecast.points.isEmpty) return const [];
    final pts = forecast.points.map((p) => p.balanceMinor.toDouble()).toList();
    if (pts.length <= 8) return pts;
    final step = pts.length / 8;
    return [for (var i = 0; i < 8; i++) pts[(i * step).floor()]];
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    settingsRepo.removeListener(_onStoreChanged);
    super.dispose();
  }
}
