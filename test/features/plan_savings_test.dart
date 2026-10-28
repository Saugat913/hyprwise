import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/model/goals.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/plan/viewmodels/plan_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accountRepo;
  late TransactionRepository transactionRepo;
  late GoalRepository goalRepo;
  late FinanceStore store;
  late PlanViewModel planVm;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = AccountRepository(db);
    transactionRepo = TransactionRepository(db);
    final recurringRepo = RecurringRepository(db);
    final jobRepo = JobRepository(db);
    final shiftRepo = ShiftRepository(db);
    goalRepo = GoalRepository(db);
    final ratesRepo = ExchangeRateRepository(db);
    final settingsRepo = SettingsRepository(db);
    final debtRepo = DebtRepository(db);

    await settingsRepo.load();

    store = FinanceStore(
      accountsRepo: accountRepo,
      transactionsRepo: transactionRepo,
      recurringRepo: recurringRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      ratesRepo: ratesRepo,
      settingsRepo: settingsRepo,
      debtsRepo: debtRepo,
    );
    store.start();

    planVm = PlanViewModel(
      financeStore: store,
      goalRepo: goalRepo,
      accountRepo: accountRepo,
      transactionRepo: transactionRepo,
    );
  });

  tearDown(() async {
    planVm.dispose();
    store.dispose();
    await db.close();
  });

  test('Creating a plan automatically links to the fixed savings account', () async {
    final goalId = await planVm.addGoal(
      name: 'MacBook Pro',
      targetAmountMinor: 300000, // $3,000
      initialSavedMinor: 50000,  // $500
      createSavingsAccount: true,
      priority: GoalPriority.high,
    );

    // Give stream a tick to propagate
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final accounts = await accountRepo.watchAll().first;
    final savingsAcc = accounts.where((a) => a.name == 'Savings').firstOrNull;
    expect(savingsAcc, isNotNull);
    expect(savingsAcc!.type, equals(AccountType.savings.value));

    final goals = await goalRepo.watchGoals().first;
    final createdGoal = goals.where((g) => g.id == goalId).firstOrNull;
    expect(createdGoal, isNotNull);
    expect(createdGoal!.accountId, equals(savingsAcc.id));
  });

  test('Adding specific amount to goal savings account distributes to the plan', () async {
    // 1. Create source bank account
    final sourceId = await accountRepo.add(
      name: 'Everyday Checking',
      type: AccountType.bank,
      openingBalanceMinor: 200000, // $2,000
      currencyCode: 'AUD',
    );

    // 2. Create goal with savings account
    final goalId = await planVm.addGoal(
      name: 'Emergency Fund',
      targetAmountMinor: 500000, // $5,000
      initialSavedMinor: 100000, // $1,000
      createSavingsAccount: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final goals = await goalRepo.watchGoals().first;
    final goal = goals.firstWhere((g) => g.id == goalId);

    // 3. Deposit $250 from Checking into Goal savings
    await planVm.addSavingsToGoal(
      goal: goal,
      amountMinor: 25000, // $250
      fromAccountId: sourceId,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Checking: 200,000 - 100,000 (initial allocation) - 25,000 = 75,000
    expect(store.snapshot.balanceOf(sourceId), equals(75000));
    // Savings account should be 100,000 + 25,000 = 125,000
    expect(store.snapshot.balanceOf(goal.accountId!), equals(125000));
  });
}
