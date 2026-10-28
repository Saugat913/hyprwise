import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/plan/data/model/goals.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

enum GoalFilter { all, inProgress, completed }

class PlanForecastPoint {
  const PlanForecastPoint({
    required this.label,
    required this.balanceMinor,
    required this.netChangeMinor,
    required this.isForecast,
  });

  final String label;
  final int balanceMinor;
  final int netChangeMinor;
  final bool isForecast;
}

class PlanViewModel extends ChangeNotifier {
  PlanViewModel({
    required this.financeStore,
    required this.goalRepo,
    required this.accountRepo,
    required this.transactionRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final GoalRepository goalRepo;
  final AccountRepository accountRepo;
  final TransactionRepository transactionRepo;

  GoalFilter _filter = GoalFilter.all;
  GoalFilter get filter => _filter;

  void setFilter(GoalFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void _onStoreChanged() {
    notifyListeners();
  }

  String get baseCurrency => financeStore.baseCurrency;
  List<Goal> get goals => financeStore.goals;
  List<Account> get accounts => financeStore.accounts;

  Account? accountById(int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  ForecastResult get forecast => financeStore.forecast(horizonDays: 90);

  int get currentTotalBalanceMinor => financeStore.snapshot.netWorthMinor;

  int get monthlyNetDeltaMinor {
    final snap = financeStore.snapshot;
    final nowMonth = snap.currentMonth;
    final income = snap.incomeInMonth(nowMonth);
    final expense = snap.expenseInMonth(nowMonth);

    final jobsById = {for (final job in snap.jobs) job.id: job};
    var shiftEarned = 0;
    for (final shift in snap.shifts) {
      if (shift.status != ShiftStatus.completed.value) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
      if (!snap.isInMonth(date, nowMonth)) continue;
      final job = jobsById[shift.jobId];
      if (job == null) continue;
      final earnings = ShiftEarnings.forShift(shift, job);
      shiftEarned += snap.convert(earnings.earningsMinor, job.currencyCode);
    }

    final actualCurrentNet = income + shiftEarned - expense;
    final fcNetPerMonth = (forecast.netChangeMinor / 3).round();
    if (fcNetPerMonth != 0) {
      return fcNetPerMonth;
    }
    return actualCurrentNet;
  }

  int get projectedBalanceIn3Months {
    final fcEnd = forecast.endMinor;
    if (fcEnd != currentTotalBalanceMinor) {
      return fcEnd;
    }
    return currentTotalBalanceMinor + (monthlyNetDeltaMinor * 3);
  }

  int get threeMonthNetChangeMinor =>
      projectedBalanceIn3Months - currentTotalBalanceMinor;

  List<PlanForecastPoint> get trajectoryPoints {
    final snap = financeStore.snapshot;
    final now = snap.now;
    final jobsById = {for (final job in snap.jobs) job.id: job};

    int actualNetForMonth(DateTime month) {
      final inc = snap.incomeInMonth(month);
      final exp = snap.expenseInMonth(month);
      var shiftPay = 0;
      for (final shift in snap.shifts) {
        if (shift.status != ShiftStatus.completed.value) continue;
        final d = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
        if (!snap.isInMonth(d, month)) continue;
        final job = jobsById[shift.jobId];
        if (job == null) continue;
        shiftPay += snap.convert(
          ShiftEarnings.forShift(shift, job).earningsMinor,
          job.currencyCode,
        );
      }
      return inc + shiftPay - exp;
    }

    final mMinus2Date = DateTime(now.year, now.month - 2, 1);
    final mMinus1Date = DateTime(now.year, now.month - 1, 1);
    final m0Date = DateTime(now.year, now.month, 1);
    final mPlus1Date = DateTime(now.year, now.month + 1, 1);
    final mPlus2Date = DateTime(now.year, now.month + 2, 1);
    final mPlus3Date = DateTime(now.year, now.month + 3, 1);

    final net0 = actualNetForMonth(m0Date);
    final netMinus1 = actualNetForMonth(mMinus1Date);
    final netMinus2 = actualNetForMonth(mMinus2Date);

    final bal0 = currentTotalBalanceMinor;
    final balMinus1 = bal0 - net0;
    final balMinus2 = balMinus1 - netMinus1;

    final fc = forecast;
    final hasForecastEvents = fc.events.isNotEmpty;
    final pace = monthlyNetDeltaMinor;

    late final int balPlus1;
    late final int balPlus2;
    late final int balPlus3;

    if (hasForecastEvents) {
      balPlus1 = fc.balanceAt(now.add(const Duration(days: 30)));
      balPlus2 = fc.balanceAt(now.add(const Duration(days: 60)));
      balPlus3 = fc.endMinor;
    } else {
      balPlus1 = bal0 + pace;
      balPlus2 = bal0 + pace * 2;
      balPlus3 = bal0 + pace * 3;
    }

    final netPlus1 = balPlus1 - bal0;
    final netPlus2 = balPlus2 - balPlus1;
    final netPlus3 = balPlus3 - balPlus2;

    return [
      PlanForecastPoint(
        label: DateFormatter.monthShort(mMinus2Date),
        balanceMinor: balMinus2,
        netChangeMinor: netMinus2,
        isForecast: false,
      ),
      PlanForecastPoint(
        label: DateFormatter.monthShort(mMinus1Date),
        balanceMinor: balMinus1,
        netChangeMinor: netMinus1,
        isForecast: false,
      ),
      PlanForecastPoint(
        label: DateFormatter.monthShort(m0Date),
        balanceMinor: bal0,
        netChangeMinor: net0,
        isForecast: false,
      ),
      PlanForecastPoint(
        label: DateFormatter.monthShort(mPlus1Date),
        balanceMinor: balPlus1,
        netChangeMinor: netPlus1,
        isForecast: true,
      ),
      PlanForecastPoint(
        label: DateFormatter.monthShort(mPlus2Date),
        balanceMinor: balPlus2,
        netChangeMinor: netPlus2,
        isForecast: true,
      ),
      PlanForecastPoint(
        label: DateFormatter.monthShort(mPlus3Date),
        balanceMinor: balPlus3,
        netChangeMinor: netPlus3,
        isForecast: true,
      ),
    ];
  }

  List<GoalForecast> get goalForecasts => forecast.goalForecasts;

  List<GoalForecast> get filteredGoalForecasts {
    final all = goalForecasts;
    return switch (_filter) {
      GoalFilter.all => all,
      GoalFilter.inProgress => all.where((gf) => gf.progress.fraction < 1.0).toList(),
      GoalFilter.completed => all.where((gf) => gf.progress.fraction >= 1.0).toList(),
    };
  }

  /// Creates a plan goal linked exclusively to the fixed Savings account.
  /// If [initialSavedMinor] is provided, transfers the amount from Everyday to Savings and contributes to the goal.
  Future<int> addGoal({
    required String name,
    required int targetAmountMinor,
    DateTime? targetDate,
    int? initialSavedMinor,
    String? category,
    GoalPriority priority = GoalPriority.normal,
    bool createSavingsAccount = true,
    int? existingAccountId,
  }) async {
    int? linkedAccountId = existingAccountId ?? financeStore.savingsAccount?.id;

    if (linkedAccountId == null) {
      final pair = await accountRepo.ensureFixedTwoAccounts(baseCurrency);
      linkedAccountId = pair.savings.id;
    }

    final goalId = await goalRepo.add(
      name: name,
      targetAmountMinor: targetAmountMinor,
      currencyCode: baseCurrency,
      targetDate: targetDate,
      accountId: linkedAccountId,
      priority: priority,
      note: category,
    );

    // If initial saved amount was provided, transfer from Everyday to Savings & record contribution
    if (initialSavedMinor != null && initialSavedMinor > 0) {
      final fromAcc = financeStore.everydayAccount;
      if (fromAcc != null && fromAcc.id != linkedAccountId) {
        await transactionRepo.addTransfer(
          sourceAccountId: fromAcc.id,
          destinationAccountId: linkedAccountId,
          amountMinor: initialSavedMinor,
          note: 'Initial savings for $name',
          occurredAt: DateTime.now(),
        );
      }
      await goalRepo.addContribution(
        goalId: goalId,
        amountMinor: initialSavedMinor,
        note: 'Initial deposit',
      );
    }

    TelemetryService.instance.trackEvent('goal_created', {
      'name': name,
      'targetAmount': targetAmountMinor,
      'hasSavingsAccount': true,
    });

    return goalId;
  }

  /// Adds a specific savings amount to fund a goal, either via transfer from
  /// an existing account or direct deposit into the goal's savings account.
  Future<void> addSavingsToGoal({
    required Goal goal,
    required int amountMinor,
    int? fromAccountId,
    String? note,
  }) async {
    if (amountMinor <= 0) return;

    final targetSavingsId = goal.accountId ?? financeStore.savingsAccount?.id;

    if (fromAccountId != null) {
      final currentBalance = financeStore.snapshot.balanceOf(fromAccountId);
      if (currentBalance < amountMinor) {
        throw StateError('Insufficient balance in source account');
      }
      if (targetSavingsId != null && fromAccountId != targetSavingsId) {
        await transactionRepo.addTransfer(
          sourceAccountId: fromAccountId,
          destinationAccountId: targetSavingsId,
          amountMinor: amountMinor,
          note: note ?? 'Saved for ${goal.name}',
          occurredAt: DateTime.now(),
        );
      }
    } else {
      if (targetSavingsId != null) {
        await transactionRepo.add(
          accountId: targetSavingsId,
          type: TransactionType.income,
          amountMinor: amountMinor,
          category: 'Savings',
          note: note ?? 'Deposit for ${goal.name}',
          occurredAt: DateTime.now(),
        );
      }
    }

    await goalRepo.addContribution(
      goalId: goal.id,
      amountMinor: amountMinor,
      note: note ?? 'Goal deposit',
    );

    TelemetryService.instance.trackEvent('goal_funded', {
      'goalId': goal.id,
      'amount': amountMinor,
    });
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
