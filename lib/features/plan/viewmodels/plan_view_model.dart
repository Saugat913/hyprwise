import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/plan/data/model/goals.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

enum GoalFilter { all, inProgress, completed }

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

  int get projectedBalanceIn3Months => forecast.endMinor;

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
