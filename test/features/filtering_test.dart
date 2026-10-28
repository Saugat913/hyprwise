import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/money/viewmodels/money_view_model.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  late AppDatabase db;
  late FinanceStore store;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = AccountRepository(db);
    txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
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

  test('CalendarViewModel isolates items to the selected date and filters by type', () async {
    final accId = await accountRepo.add(name: 'Bank', type: AccountType.bank, currencyCode: 'AUD', openingBalanceMinor: 10000);
    final jobId = await jobRepo.add(name: 'Barista', hourlyRateMinor: 2500, currencyCode: 'AUD');

    final today = DateTime.now();
    final targetDay = DateTime(today.year, today.month, 15, 10, 0);
    final anotherDay = DateTime(today.year, today.month, 16, 14, 0);

    // Shift on target day
    await shiftRepo.add(
      jobId: jobId,
      startAt: targetDay,
      endAt: targetDay.add(const Duration(hours: 4)),
      status: ShiftStatus.completed,
    );

    // Expense on target day
    await txRepo.add(
      accountId: accId,
      amountMinor: 1500,
      type: TransactionType.expense,
      category: 'eating_out',
      note: 'McDonalds',
      occurredAt: targetDay.add(const Duration(hours: 2)),
    );

    // Expense on another day
    await txRepo.add(
      accountId: accId,
      amountMinor: 5000,
      type: TransactionType.expense,
      category: 'groceries',
      occurredAt: anotherDay,
    );

    // Allow drift streams to pump to store
    await Future.delayed(const Duration(milliseconds: 50));

    final vm = CalendarViewModel(financeStore: store);
    vm.selectDate(targetDay);

    // Default filter is 'all'
    expect(vm.filter, CalendarFilter.all);
    expect(vm.selectedDayItems.length, 2);
    expect(vm.dayIncomeMinor, 10000); // 4h @ $25/h = $100
    expect(vm.dayExpenseMinor, 1500); // $15

    // Filter to shifts only
    vm.setFilter(CalendarFilter.shifts);
    expect(vm.selectedDayItems.length, 1);
    expect(vm.selectedDayItems.first.type, CalendarItemType.shift);

    // Filter to transactions only
    vm.setFilter(CalendarFilter.transactions);
    expect(vm.selectedDayItems.length, 1);
    expect(vm.selectedDayItems.first.type, CalendarItemType.expense);
    expect(vm.selectedDayItems.first.title, 'McDonalds');
  });

  test('AnalyticsViewModel filters correctly by category and date range', () async {
    final accId = await accountRepo.add(name: 'Everyday', type: AccountType.bank, currencyCode: 'AUD', openingBalanceMinor: 50000);

    final now = DateTime.now();
    await txRepo.add(
      accountId: accId,
      amountMinor: 4000,
      type: TransactionType.expense,
      category: 'eating_out',
      note: 'KFC',
      occurredAt: now,
    );
    await txRepo.add(
      accountId: accId,
      amountMinor: 8000,
      type: TransactionType.expense,
      category: 'groceries',
      note: 'Woolworths',
      occurredAt: now,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    final vm = AnalyticsViewModel(financeStore: store);
    vm.setDateFilter(AnalyticsDateFilter.thisMonth);

    // Total expense includes both
    expect(vm.expenseMinor, 12000);
    expect(vm.categoryBreakdown.length, 2);

    // Filter to 'eating_out' only
    vm.selectCategory('eating_out');
    expect(vm.expenseMinor, 4000);
    expect(vm.topMerchants.length, 1);
    expect(vm.topMerchants.first.name, 'KFC');

    // Reset filters
    vm.clearFilters();
    expect(vm.selectedCategory, isNull);
    expect(vm.expenseMinor, 12000);
  });

  test('MoneyViewModel filters by search query and category', () async {
    final accId = await accountRepo.add(name: 'Wallet', type: AccountType.wallet, currencyCode: 'AUD', openingBalanceMinor: 20000);

    await txRepo.add(
      accountId: accId,
      amountMinor: 1200,
      type: TransactionType.expense,
      category: 'transport',
      note: 'Train ticket',
      occurredAt: DateTime.now(),
    );
    await txRepo.add(
      accountId: accId,
      amountMinor: 3500,
      type: TransactionType.expense,
      category: 'groceries',
      note: 'Coles shopping',
      occurredAt: DateTime.now(),
    );

    await Future.delayed(const Duration(milliseconds: 50));

    final vm = MoneyViewModel(financeStore: store, transactionRepo: txRepo);

    expect(vm.transactions.length, 2);

    // Search for 'train'
    vm.setSearchQuery('train');
    expect(vm.transactions.length, 1);
    expect(vm.transactions.first.category, 'Transport');

    // Clear search and filter by category
    vm.setSearchQuery('');
    vm.selectCategory('groceries');
    expect(vm.transactions.length, 1);
    expect(vm.transactions.first.note, 'Coles shopping');
  });
}
