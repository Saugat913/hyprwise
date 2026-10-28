import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/category_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categoryRepo;
  late DebtRepository debtRepo;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late FinanceStore store;
  late SettingsRepository settingsRepo;
  late HomeViewModel homeVm;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categoryRepo = CategoryRepository(db);
    debtRepo = DebtRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    final accountRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recurringRepo = RecurringRepository(db);
    final goalRepo = GoalRepository(db);
    final ratesRepo = ExchangeRateRepository(db);
    settingsRepo = SettingsRepository(db);

    await settingsRepo.load();
    await categoryRepo.load();

    store = FinanceStore(
      accountsRepo: accountRepo,
      transactionsRepo: txRepo,
      recurringRepo: recurringRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      ratesRepo: ratesRepo,
      settingsRepo: settingsRepo,
      debtsRepo: debtRepo,
    );
    store.start();

    await accountRepo.add(
      name: 'Main',
      type: AccountType.bank,
      openingBalanceMinor: 100000,
      currencyCode: 'AUD',
    );

    homeVm = HomeViewModel(
      financeStore: store,
      settingsRepo: settingsRepo,
    );
  });

  tearDown(() async {
    homeVm.dispose();
    store.dispose();
    await db.close();
  });

  test('Custom category creation, merchant learning and persistence', () async {
    // 1. Add custom category
    final cat = await categoryRepo.addCategory(
      label: 'Gym & Fitness',
      type: TransactionType.expense,
    );
    expect(cat.isCustom, isTrue);
    expect(TransactionCategories.find('Gym & Fitness', TransactionType.expense), isNotNull);

    // 2. Add merchant under custom category and under built-in category
    await categoryRepo.addMerchant(categoryKey: cat.value, merchant: 'Anytime Fitness');
    await categoryRepo.addMerchant(categoryKey: 'eating_out', merchant: "McDonald's");

    expect(TransactionCategories.merchantsFor(cat.value), contains('Anytime Fitness'));
    expect(TransactionCategories.merchantsFor('eating_out'), contains("McDonald's"));

    // 3. Verify persistence by creating a new repo instance and loading
    final newRepo = CategoryRepository(db);
    await newRepo.load();
    expect(newRepo.customCategories.any((c) => c.label == 'Gym & Fitness'), isTrue);
    expect(TransactionCategories.merchantsFor(cat.value), contains('Anytime Fitness'));
  });

  test('HomeViewModel includes today\'s shift in upcomingEvents and tracks debts', () async {
    final jobId = await jobRepo.add(
      name: 'Barista',
      hourlyRateMinor: 3000,
      currencyCode: 'AUD',
    );

    // Schedule a shift for today
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day, 9);
    final endToday = DateTime(now.year, now.month, now.day, 17);

    await shiftRepo.add(
      jobId: jobId,
      startAt: startToday,
      endAt: endToday,
      status: ShiftStatus.scheduled,
    );

    // Add a debt: Lent $100 to Alice, Borrowed $40 from Bob
    await debtRepo.add(
      personName: 'Alice',
      type: DebtType.lent,
      amountMinor: 10000,
      currencyCode: 'AUD',
    );
    await debtRepo.add(
      personName: 'Bob',
      type: DebtType.borrowed,
      amountMinor: 4000,
      currencyCode: 'AUD',
    );

    // Allow drift streams to emit
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Verify HomeViewModel
    expect(homeVm.totalLentMinor, 10000);
    expect(homeVm.totalBorrowedMinor, 4000);
    expect(homeVm.netDebtMinor, 6000);
    expect(homeVm.activeDebts.length, 2);

    // Verify today's shift is present in upcomingEvents
    final todayShiftEvents = homeVm.upcomingEvents.where(
      (e) => e.kind == ForecastEventKind.shift && AppDate.dateOnly(e.date) == AppDate.dateOnly(now),
    );
    expect(todayShiftEvents.isNotEmpty, isTrue);
    expect(todayShiftEvents.first.label, contains('Barista'));
  });
}
