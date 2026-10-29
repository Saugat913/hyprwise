import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/export/export_service.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  final getIt = GetIt.instance;
  late AppDatabase db;
  late FinanceStore store;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;
  late DebtRepository debtRepo;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late AnalyticsViewModel analyticsVm;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    accountRepo = AccountRepository(db);
    txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    debtRepo = DebtRepository(db);
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
      debtsRepo: debtRepo,
      ratesRepo: ratesRepo,
      settingsRepo: settingsRepo,
    );
    store.start();

    analyticsVm = AnalyticsViewModel(financeStore: store);
    getIt.registerSingleton<FinanceStore>(store);
  });

  tearDown(() async {
    analyticsVm.dispose();
    store.dispose();
    await db.close();
    await getIt.reset();
  });

  Future<void> seedComprehensiveData() async {
    final accId = await accountRepo.add(
      name: 'Primary Checking',
      type: AccountType.bank,
      openingBalanceMinor: 100000,
      currencyCode: 'USD',
    );

    final now = DateTime.now();

    // Income
    await txRepo.add(
      accountId: accId,
      type: TransactionType.income,
      amountMinor: 500000, // $5,000.00
      category: 'salary',
      occurredAt: now,
      note: 'Monthly Salary',
    );

    // Expense
    await txRepo.add(
      accountId: accId,
      type: TransactionType.expense,
      amountMinor: 150000, // $1,500.00
      category: 'groceries',
      occurredAt: now,
      note: 'Supermarket Groceries',
    );

    // Lent debt
    await debtRepo.add(
      type: DebtType.lent,
      personName: 'Bob Partner',
      amountMinor: 25000, // $250.00
      currencyCode: 'USD',
      dueDate: now.add(const Duration(days: 30)),
      note: 'Lunch loan',
    );

    // Borrowed debt
    await debtRepo.add(
      type: DebtType.borrowed,
      personName: 'Alice Colleague',
      amountMinor: 10000, // $100.00
      currencyCode: 'USD',
      dueDate: now.add(const Duration(days: 15)),
      note: 'Concert ticket',
    );

    // Job & Completed Shift
    final jobId = await jobRepo.add(
      name: 'Weekend Barista',
      hourlyRateMinor: 3000,
      currencyCode: 'USD',
    );

    await shiftRepo.add(
      jobId: jobId,
      startAt: now.subtract(const Duration(hours: 4)),
      endAt: now,
      breakMinutes: 15,
      status: ShiftStatus.completed,
    );

    await Future.delayed(const Duration(milliseconds: 150));
  }

  group('R6: Comprehensive Analytics Report Export (Tier 1 Feature Coverage)', () {
    test('T1.1: Exported analytics CSV includes overview metrics section', () async {
      await seedComprehensiveData();
      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);

      expect(csvContent, contains('ANALYTICS REPORT'));
      expect(csvContent, contains('Period'));
    });

    test('T1.2: Exported analytics CSV includes category breakdown and top merchants', () async {
      await seedComprehensiveData();
      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);

      expect(csvContent, contains('CATEGORY BREAKDOWN'));
      expect(csvContent, contains('TOP MERCHANTS / PAYEES'));
    });

    test('T1.3: Exported analytics CSV includes itemized transactions list', () async {
      await seedComprehensiveData();
      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);

      expect(csvContent, contains('TRANSACTIONS'));
      expect(csvContent, contains('Groceries'));
    });

    test('T1.4: Exported analytics text report provides structured human-readable document', () async {
      await seedComprehensiveData();
      final report = ExportService.generateAnalyticsReport(analyticsVm);

      expect(report, contains('HYPRWISE ANALYTICS REPORT'));
      expect(report, contains('Period:'));
      expect(report, contains('CATEGORY BREAKDOWN'));
      expect(report, contains('TOP MERCHANTS / PAYEES'));
    });

    test('T1.5: Currency formatting adheres to user base currency in exported reports', () async {
      await seedComprehensiveData();
      final report = ExportService.generateAnalyticsReport(analyticsVm);
      final currency = analyticsVm.baseCurrency;

      expect(report, contains(currency));
    });
  });

  group('R6: Comprehensive Analytics Report Export (Tier 2 Boundary & Corner Cases)', () {
    test('T2.1: Empty data exports gracefully with zeroed metrics without crashing', () async {
      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csvContent, isNotEmpty);
      expect(csvContent, contains('ANALYTICS REPORT'));

      final textReport = ExportService.generateAnalyticsReport(analyticsVm);
      expect(textReport, isNotEmpty);
      expect(textReport, contains('HYPRWISE ANALYTICS REPORT'));
    });

    test('T2.2: Zero income with positive expenses calculates without negative math errors', () async {
      final accId = await accountRepo.add(name: 'Bank', type: AccountType.bank, openingBalanceMinor: 50000, currencyCode: 'USD');
      await txRepo.add(accountId: accId, type: TransactionType.expense, amountMinor: 20000, category: 'dining', occurredAt: DateTime.now());
      await Future.delayed(const Duration(milliseconds: 150));

      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csvContent, isNotEmpty);
    });

    test('T2.3: 100% savings rate (positive income, 0 expenses) generates cleanly', () async {
      final accId = await accountRepo.add(name: 'Bank', type: AccountType.bank, openingBalanceMinor: 0, currencyCode: 'USD');
      await txRepo.add(accountId: accId, type: TransactionType.income, amountMinor: 300000, category: 'salary', occurredAt: DateTime.now());
      await Future.delayed(const Duration(milliseconds: 150));

      analyticsVm.setActiveType(TransactionType.income);
      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csvContent, contains('Income'));
    });

    test('T2.4: Special characters and commas in notes and merchants are correctly escaped in CSV', () async {
      final accId = await accountRepo.add(name: 'Checking', type: AccountType.bank, openingBalanceMinor: 0, currencyCode: 'USD');
      await txRepo.add(
        accountId: accId,
        type: TransactionType.expense,
        amountMinor: 4500,
        category: 'groceries',
        occurredAt: DateTime.now(),
        note: 'Trader Joe\'s, "Special Snacks", & Drinks',
      );
      await Future.delayed(const Duration(milliseconds: 150));

      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);
      // Valid CSV encoding wraps cells with commas in quotes and doubles inner quotes
      expect(csvContent, contains('"Trader Joe\'s, ""Special Snacks"", & Drinks"'));
    });

    test('T2.5: Multi-currency handling exports base currency code in CSV header', () async {
      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csvContent, contains(analyticsVm.baseCurrency));
    });
  });
}
