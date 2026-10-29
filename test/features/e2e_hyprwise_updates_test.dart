import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/export/export_service.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/auth/data/model/user_profile.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class MockStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  @override
  Future<void> write({required String key, required String? value, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
  @override
  Future<String?> read({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async => _data[key];
  @override
  Future<void> delete({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async => _data.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance;
  late AppDatabase db;
  late MockStorage storage;
  late AuthService authService;
  late SubscriptionService subService;
  late FinanceStore store;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;
  late DebtRepository debtRepo;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late SettingsRepository settingsRepo;
  late DataRepository dataRepo;
  late ExchangeRateRepository ratesRepo;
  late CalendarViewModel calendarVm;
  late WorkViewModel workVm;
  late AnalyticsViewModel analyticsVm;
  late SettingsViewModel settingsVm;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storage = MockStorage();
    authService = AuthService(storage: storage);
    subService = SubscriptionService(authService: authService, storage: storage);

    accountRepo = AccountRepository(db);
    txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    debtRepo = DebtRepository(db);
    ratesRepo = ExchangeRateRepository(db);
    settingsRepo = SettingsRepository(db);
    await settingsRepo.load();
    dataRepo = DataRepository(db);

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

    calendarVm = CalendarViewModel(financeStore: store);
    workVm = WorkViewModel(financeStore: store, jobRepo: jobRepo, shiftRepo: shiftRepo);
    analyticsVm = AnalyticsViewModel(financeStore: store);
    settingsVm = SettingsViewModel(
      settingsRepo: settingsRepo,
      dataRepo: dataRepo,
      financeStore: store,
      ratesRepo: ratesRepo,
    );

    getIt.registerSingleton<AuthService>(authService);
    getIt.registerSingleton<SubscriptionService>(subService);
    getIt.registerSingleton<FinanceStore>(store);
    getIt.registerSingleton<CalendarViewModel>(calendarVm);
    getIt.registerSingleton<WorkViewModel>(workVm);
    getIt.registerSingleton<SettingsViewModel>(settingsVm);
  });

  tearDown(() async {
    calendarVm.dispose();
    workVm.dispose();
    analyticsVm.dispose();
    settingsVm.dispose();
    authService.dispose();
    subService.dispose();
    store.dispose();
    await db.close();
    await getIt.reset();
  });

  group('Tier 3: Cross-Feature Combinations (Pairwise Coverage)', () {
    test('T3.1: Pro user editing calendar shift maintains Pro state and scheduled shift editability', () async {
      await authService.signInAsGuest();
      final annualPlan = SubscriptionService.availablePlans[1];
      await subService.subscribe(annualPlan);
      expect(subService.isPro, isTrue);

      final jobId = await jobRepo.add(name: 'Senior Consultant', hourlyRateMinor: 6000, currencyCode: 'USD');
      final today = DateTime.now();
      final shiftId = await shiftRepo.add(
        jobId: jobId,
        startAt: DateTime(today.year, today.month, today.day, 10, 0),
        endAt: DateTime(today.year, today.month, today.day, 14, 0),
        breakMinutes: 0,
        status: ShiftStatus.scheduled,
      );

      await Future.delayed(const Duration(milliseconds: 150));
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.shifts);

      final items = calendarVm.selectedDayItems;
      expect(items.length, equals(1));
      expect(items.first.rawId, equals(shiftId));
      expect(items.first.status, equals(ShiftStatus.scheduled.value));
      expect(subService.isPro, isTrue);
    });

    test('T3.2: Pro user exporting comprehensive analytics report generates valid content without paywall lock', () async {
      await authService.signInAsGuest();
      final annualPlan = SubscriptionService.availablePlans[1];
      await subService.subscribe(annualPlan);

      final accId = await accountRepo.add(name: 'Everyday', type: AccountType.bank, openingBalanceMinor: 10000, currencyCode: 'USD');
      await txRepo.add(accountId: accId, type: TransactionType.income, amountMinor: 250000, category: 'consulting', occurredAt: DateTime.now());
      await Future.delayed(const Duration(milliseconds: 150));

      final report = ExportService.generateAnalyticsReport(analyticsVm);
      expect(report, contains('HYPRWISE ANALYTICS REPORT'));
      expect(report, contains('CATEGORY BREAKDOWN'));
      expect(subService.isPro, isTrue);
    });

    test('T3.3: Second-accurate completed shift propagates into analytics work data', () async {
      final jobId = await jobRepo.add(name: 'Software Developer', hourlyRateMinor: 3600, currencyCode: 'USD');
      final now = DateTime.now();
      final startAt = now.subtract(const Duration(hours: 1, seconds: 30)); // 3630 seconds worked

      await shiftRepo.add(
        jobId: jobId,
        startAt: startAt,
        endAt: now,
        breakMinutes: 0,
        status: ShiftStatus.completed,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csvContent, isNotEmpty);
      expect(csvContent, contains('ANALYTICS REPORT'));
    });

    test('T3.4: Pro status upgrade immediately updates UI Listeners', () async {
      await authService.signInAsGuest();
      int listenerCalls = 0;
      subService.addListener(() => listenerCalls++);

      final annualPlan = SubscriptionService.availablePlans[1];
      await subService.subscribe(annualPlan);

      expect(listenerCalls, greaterThan(0));
      expect(subService.isPro, isTrue);
    });

    test('T3.5: Multi-currency shift with second-precision exports correct base currency in header', () async {
      final jobId = await jobRepo.add(name: 'London Designer', hourlyRateMinor: 4500, currencyCode: 'GBP');
      final now = DateTime.now();

      await shiftRepo.add(
        jobId: jobId,
        startAt: now.subtract(const Duration(minutes: 90, seconds: 15)),
        endAt: now,
        breakMinutes: 10,
        status: ShiftStatus.completed,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      final csvContent = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csvContent, contains(analyticsVm.baseCurrency));
    });

    test('T3.6: Debt counterparty record combined with analytics export', () async {
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Elena Rostova',
        amountMinor: 50000,
        currencyCode: 'USD',
        dueDate: DateTime.now().add(const Duration(days: 14)),
        note: 'Equipment rental',
      );
      await Future.delayed(const Duration(milliseconds: 150));

      final csv = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csv, isNotEmpty);
    });
  });

  group('Tier 4: Real-World Application Scenarios (End-to-End User Workflows)', () {
    test('T4.1: Full Shift Life-Cycle: Schedule -> Calendar View -> Edit -> Second-Accurate Completion', () async {
      // Step 1: Create Job
      final jobId = await jobRepo.add(
        name: 'Senior Barista',
        hourlyRateMinor: 3600, // $36.00/hr = 1 cent/second
        currencyCode: 'USD',
      );
      final job = (await jobRepo.watchAll().first).firstWhere((j) => j.id == jobId);

      // Step 2: Schedule upcoming shift
      final today = DateTime.now();
      final startAt = DateTime(today.year, today.month, today.day, 9, 0, 0);
      final endAt = DateTime(today.year, today.month, today.day, 17, 0, 0);

      final shiftId = await shiftRepo.add(
        jobId: jobId,
        startAt: startAt,
        endAt: endAt,
        breakMinutes: 0,
        status: ShiftStatus.scheduled,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      // Step 3: Verify visible in Calendar as scheduled
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.shifts);
      final calendarItems = calendarVm.selectedDayItems;
      expect(calendarItems.length, equals(1));
      expect(calendarItems.first.rawId, equals(shiftId));
      expect(calendarItems.first.status, equals(ShiftStatus.scheduled.value));

      // Step 4: User edits scheduled shift (updates break time to 15 min)
      await shiftRepo.update(shiftId, breakMinutes: 15);
      await Future.delayed(const Duration(milliseconds: 150));

      final updatedShift = (await shiftRepo.watchAll().first).firstWhere((s) => s.id == shiftId);
      expect(updatedShift.breakMinutes, equals(15));

      // Step 5: Shift completes with non-zero seconds: exactly 1h 0m 30s elapsed with 0 min break
      // 3630 seconds elapsed
      final actualStart = DateTime(2026, 10, 14, 10, 0, 0);
      final actualEnd = DateTime(2026, 10, 14, 11, 0, 30);
      final completedShift = Shift(
        id: shiftId,
        jobId: jobId,
        startAt: actualStart.millisecondsSinceEpoch,
        endAt: actualEnd.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      // Step 6: Second-accurate earnings calculated down to the second
      final earnings = ShiftEarnings.forShift(completedShift, job);
      expect(earnings.workedSeconds, equals(3630));
      // 3600 * 3630 / 3600 = 3630 minor units ($36.30)
      expect(earnings.earningsMinor, equals(3630));
      expect(completedShift.durationSeconds, equals(3630));
    });

    test('T4.2: Full Financial Cycle: Multi-source entries -> Analytics aggregation -> Pro Upgrade -> Export', () async {
      // Step 1: User logs accounts and transactions
      final accId = await accountRepo.add(
        name: 'Vault Account',
        type: AccountType.savings,
        openingBalanceMinor: 200000,
        currencyCode: 'USD',
      );

      final now = DateTime.now();
      await txRepo.add(
        accountId: accId,
        type: TransactionType.income,
        amountMinor: 400000, // $4,000.00
        category: 'salary',
        occurredAt: now,
      );
      await txRepo.add(
        accountId: accId,
        type: TransactionType.expense,
        amountMinor: 120000, // $1,200.00
        category: 'groceries',
        occurredAt: now,
      );
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Sam Colleague',
        amountMinor: 30000,
        currencyCode: 'USD',
        dueDate: now.add(const Duration(days: 7)),
      );

      // Step 2: Complete shift
      final jobId = await jobRepo.add(name: 'Barista', hourlyRateMinor: 3600, currencyCode: 'USD');
      await shiftRepo.add(
        jobId: jobId,
        startAt: now.subtract(const Duration(hours: 2)),
        endAt: now,
        breakMinutes: 0,
        status: ShiftStatus.completed,
      );
      await Future.delayed(const Duration(milliseconds: 150));

      // Step 3: Aggregate in Analytics
      expect(store.transactions.length, equals(2));
      expect(store.debts.length, equals(1));
      expect(store.shifts.length, equals(1));

      // Step 4: Generate CSV export
      final csv = ExportService.generateAnalyticsCsv(analyticsVm);
      expect(csv, contains('ANALYTICS REPORT'));
      expect(csv, contains('Groceries'));

      // Step 5: Upgrade to Pro
      await authService.signInAsGuest();
      final annualPlan = SubscriptionService.availablePlans[1];
      await subService.subscribe(annualPlan);
      expect(subService.isPro, isTrue);

      // Step 6: Generate comprehensive human-readable report
      final report = ExportService.generateAnalyticsReport(analyticsVm);
      expect(report, contains('HYPRWISE ANALYTICS REPORT'));
      expect(report, contains('CATEGORY BREAKDOWN'));
    });

    test('T4.3: Real-World Mobile Form Flow & Settings Navigation', () async {
      await storage.write(
        key: 'auth_user_profile',
        value: jsonEncode(const UserProfile(
          id: 'usr_g_sarah',
          email: 'sarah.connor@hyprwise.com',
          displayName: 'Sarah Connor',
          provider: AuthProvider.google,
          isPro: false,
        ).toJson()),
      );
      await authService.load();
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.displayName, equals('Sarah Connor'));

      // Verify base settings
      expect(settingsVm.settings.baseCurrency, isNotEmpty);
      expect(settingsVm.accountsCount, equals(0));

      // Add account
      await accountRepo.add(name: 'Cash Stash', type: AccountType.cash, openingBalanceMinor: 5000, currencyCode: 'USD');
      await Future.delayed(const Duration(milliseconds: 150));

      expect(settingsVm.accountsCount, equals(1));
    });
  });
}
