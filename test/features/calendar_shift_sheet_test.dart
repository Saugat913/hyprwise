import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/calendar/view/calendar_screen.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FinanceStore store;
  late CalendarViewModel calendarVm;
  late WorkViewModel workVm;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final accountRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    final debtRepo = DebtRepository(db);
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

    calendarVm = CalendarViewModel(financeStore: store);
    workVm = WorkViewModel(
      financeStore: store,
      jobRepo: jobRepo,
      shiftRepo: shiftRepo,
    );

    if (getIt.isRegistered<FinanceStore>()) getIt.unregister<FinanceStore>();
    if (getIt.isRegistered<CalendarViewModel>()) getIt.unregister<CalendarViewModel>();
    if (getIt.isRegistered<WorkViewModel>()) getIt.unregister<WorkViewModel>();

    getIt.registerSingleton<FinanceStore>(store);
    getIt.registerSingleton<CalendarViewModel>(calendarVm);
    getIt.registerSingleton<WorkViewModel>(workVm);
  });

  tearDown(() async {
    if (getIt.isRegistered<FinanceStore>()) getIt.unregister<FinanceStore>();
    if (getIt.isRegistered<CalendarViewModel>()) getIt.unregister<CalendarViewModel>();
    if (getIt.isRegistered<WorkViewModel>()) getIt.unregister<WorkViewModel>();
    calendarVm.dispose();
    workVm.dispose();
    store.dispose();
    await db.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: CalendarScreen(),
      ),
    );
  }

  testWidgets('Tapping upcoming scheduled shift shows Edit shift button and opens edit sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.runAsync(() async {
      final jobId = await jobRepo.add(
        name: 'Shift Lead',
        hourlyRateMinor: 4000,
        currencyCode: 'USD',
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startAt = DateTime(today.year, today.month, today.day, 10, 0);
      final endAt = DateTime(today.year, today.month, today.day, 16, 0);

      await shiftRepo.add(
        jobId: jobId,
        startAt: startAt,
        endAt: endAt,
        breakMinutes: 30,
        status: ShiftStatus.scheduled,
      );

      await Future.delayed(const Duration(milliseconds: 150));
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify shift block appears in calendar timeline
    expect(find.text('Shift Lead'), findsWidgets);

    // Tap the scheduled shift
    await tester.tap(find.text('Shift Lead').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Assert scheduled shift sheet includes Edit shift button
    expect(find.text('Edit shift'), findsOneWidget);
    expect(find.text('View in Work'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Tap Edit shift to verify it opens showEditShiftDialog
    await tester.tap(find.text('Edit shift'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Bottom sheet dialog opens with Save changes action
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('Tapping completed shift does not show Edit shift button (view-only)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.runAsync(() async {
      final jobId = await jobRepo.add(
        name: 'Barista',
        hourlyRateMinor: 2500,
        currencyCode: 'AUD',
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startAt = DateTime(today.year, today.month, today.day, 8, 0);
      final endAt = DateTime(today.year, today.month, today.day, 14, 0);

      await shiftRepo.add(
        jobId: jobId,
        startAt: startAt,
        endAt: endAt,
        breakMinutes: 30,
        status: ShiftStatus.completed,
      );

      await Future.delayed(const Duration(milliseconds: 150));
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify shift block appears in calendar timeline
    expect(find.text('Barista'), findsWidgets);

    // Tap the completed shift
    await tester.tap(find.text('Barista').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Assert completed shift sheet is strictly view-only (no Edit shift button)
    expect(find.text('Edit shift'), findsNothing);
    expect(find.text('View in Work'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
