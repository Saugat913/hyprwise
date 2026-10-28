import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/debts/viewmodels/debts_view_model.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

void main() {
  late AppDatabase db;
  late DebtRepository debtRepo;
  late FinanceStore store;
  late DebtsViewModel viewModel;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    debtRepo = DebtRepository(db);

    final accountsRepo = AccountRepository(db);
    final transactionsRepo = TransactionRepository(db);
    final recurringRepo = RecurringRepository(db);
    final jobsRepo = JobRepository(db);
    final shiftsRepo = ShiftRepository(db);
    final goalsRepo = GoalRepository(db);
    final ratesRepo = ExchangeRateRepository(db);
    final settingsRepo = SettingsRepository(db);
    await settingsRepo.load();

    store = FinanceStore(
      accountsRepo: accountsRepo,
      transactionsRepo: transactionsRepo,
      recurringRepo: recurringRepo,
      jobsRepo: jobsRepo,
      shiftsRepo: shiftsRepo,
      goalsRepo: goalsRepo,
      ratesRepo: ratesRepo,
      settingsRepo: settingsRepo,
      debtsRepo: debtRepo,
    );
    store.start();

    viewModel = DebtsViewModel(
      financeStore: store,
      debtRepo: debtRepo,
      transactionRepo: transactionsRepo,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    store.dispose();
    await db.close();
  });

  test('Lending and Borrowing tracks net balance and settlement correctly', () async {
    // 1. Add Lent debt: Sarah owes AUD 50.00
    final lentId = await viewModel.addDebt(
      personName: 'Sarah',
      type: DebtType.lent,
      amountMinor: 5000,
      currencyCode: 'AUD',
      note: 'Dinner split',
    );

    // 2. Add Borrowed debt: I owe David AUD 20.00
    final borrowedId = await viewModel.addDebt(
      personName: 'David',
      type: DebtType.borrowed,
      amountMinor: 2000,
      currencyCode: 'AUD',
      note: 'Taxi fare',
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(viewModel.debts.length, 2);
    expect(viewModel.totalLentMinor, 5000);
    expect(viewModel.totalBorrowedMinor, 2000);
    expect(viewModel.netBalanceMinor, 3000); // 5000 - 2000 = +3000

    // 3. Settle Sarah's debt
    await viewModel.settleDebt(lentId);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(viewModel.settledDebts.length, 1);
    expect(viewModel.activeDebts.length, 1);
    expect(viewModel.totalLentMinor, 0); // Settled doesn't count in active balance
    expect(viewModel.totalBorrowedMinor, 2000);
    expect(viewModel.netBalanceMinor, -2000);

    // 4. Delete David's debt
    await viewModel.deleteDebt(borrowedId);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(viewModel.activeDebts.isEmpty, true);
    expect(viewModel.totalBorrowedMinor, 0);
    expect(viewModel.netBalanceMinor, 0);
  });

  test('AnalyticsViewModel integrates debts, net position and parties correctly', () async {
    final analyticsVm = AnalyticsViewModel(financeStore: store);

    // 1. Add Lent debt: Ram owes NPR 1500
    await viewModel.addDebt(
      personName: 'Ram',
      type: DebtType.lent,
      amountMinor: 150000,
      currencyCode: 'AUD',
      note: 'Groceries split',
    );

    // 2. Add Borrowed debt: I owe Sita NPR 500
    await viewModel.addDebt(
      personName: 'Sita',
      type: DebtType.borrowed,
      amountMinor: 50000,
      currencyCode: 'AUD',
      note: 'Coffee',
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(analyticsVm.activeDebts.length, 2);
    expect(analyticsVm.totalLentMinor, 150000);
    expect(analyticsVm.totalBorrowedMinor, 50000);
    expect(analyticsVm.netDebtMinor, 100000);

    final parties = analyticsVm.topDebtParties;
    expect(parties.length, 2);
    expect(parties.first.name, 'Ram');
    expect(parties.first.netMinor, 150000);
    expect(parties.first.lentMinor, 150000);

    expect(parties.last.name, 'Sita');
    expect(parties.last.netMinor, -50000);
    expect(parties.last.borrowedMinor, 50000);

    analyticsVm.dispose();
  });
}

