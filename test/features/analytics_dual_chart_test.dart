import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/analytics/view/analytics_screen.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  late AppDatabase db;
  late FinanceStore store;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = AccountRepository(db);
    txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    final jobRepo = JobRepository(db);
    final shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    final ratesRepo = ExchangeRateRepository(db);
    final settingsRepo = SettingsRepository(db);
    await settingsRepo.load();

    store = FinanceStore(
      accountsRepo: accountRepo,
      transactionsRepo: txRepo,
      recurringRepo: recRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      ratesRepo: ratesRepo,
      settingsRepo: settingsRepo,
    );
    store.start();
  });

  tearDown(() async {
    store.dispose();
    await db.close();
  });

  test('AnalyticsViewModel dualChartData computes income and expense buckets per day', () async {
    final accId = await accountRepo.add(
      name: 'Checking',
      type: AccountType.bank,
      currencyCode: 'USD',
      openingBalanceMinor: 100000,
    );

    final now = DateTime.now();

    // 1. Add Income transaction
    await txRepo.add(
      accountId: accId,
      amountMinor: 50000, // $500.00
      type: TransactionType.income,
      category: 'salary',
      note: 'Paycheck',
      occurredAt: now,
    );

    // 2. Add Expense transaction
    await txRepo.add(
      accountId: accId,
      amountMinor: 20000, // $200.00
      type: TransactionType.expense,
      category: 'groceries',
      note: 'Supermarket',
      occurredAt: now,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    final vm = AnalyticsViewModel(financeStore: store);
    vm.setDateFilter(AnalyticsDateFilter.thisWeek);

    final dualData = vm.dualChartData;

    expect(dualData.labels.isNotEmpty, isTrue);
    expect(dualData.incomeValues.length, equals(dualData.labels.length));
    expect(dualData.expenseValues.length, equals(dualData.labels.length));

    // Both income ($500) and expense ($200) should be captured in the buckets
    expect(dualData.incomeValues.any((v) => v == 50000.0), isTrue);
    expect(dualData.expenseValues.any((v) => v == 20000.0), isTrue);
    expect(dualData.hasAnyData, isTrue);
  });

  testWidgets('Dual bar chart renders 31 days on compact 360px viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final accId = await accountRepo.add(
      name: 'Checking',
      type: AccountType.bank,
      currencyCode: 'USD',
      openingBalanceMinor: 100000,
    );

    final now = DateTime.now();
    for (int day = 1; day <= 30; day++) {
      await txRepo.add(
        accountId: accId,
        amountMinor: 1000 * day,
        type: day % 2 == 0 ? TransactionType.income : TransactionType.expense,
        category: day % 2 == 0 ? 'salary' : 'groceries',
        occurredAt: now.subtract(Duration(days: day)),
      );
    }

    await Future.delayed(const Duration(milliseconds: 50));

    final vm = AnalyticsViewModel(financeStore: store);
    vm.setDateFilter(AnalyticsDateFilter.thisMonth);

    await getIt.reset();
    getIt.registerSingleton<AnalyticsViewModel>(vm);

    await tester.pumpWidget(
      const MaterialApp(
        home: AnalyticsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'RenderFlex overflowed in dual bar chart');
  });
}
