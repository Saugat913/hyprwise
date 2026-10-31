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
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
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
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = AccountRepository(db);
    txRepo = TransactionRepository(db);
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

  group('Empirical Challenge: Upcoming Scheduled Shift Editing Lifecycle', () {
    testWidgets('Edit scheduled shift, modify break and note, save changes, and verify DB update', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int shiftId = 0;
      await tester.runAsync(() async {
        final jobId = await jobRepo.add(
          name: 'Tech Specialist',
          hourlyRateMinor: 4500,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final startAt = DateTime(today.year, today.month, today.day, 10, 0);
        final endAt = DateTime(today.year, today.month, today.day, 16, 0);

        shiftId = await shiftRepo.add(
          jobId: jobId,
          startAt: startAt,
          endAt: endAt,
          breakMinutes: 15,
          status: ShiftStatus.scheduled,
          note: 'Original note',
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap scheduled shift
      expect(find.text('Tech Specialist'), findsWidgets);
      await tester.tap(find.text('Tech Specialist').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // "Edit shift" must be present
      expect(find.text('Edit shift'), findsOneWidget);
      await tester.tap(find.text('Edit shift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Edit shift dialog opens
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Original note'), findsOneWidget);

      // Modify break minutes to 45
      final breakField = find.widgetWithText(TextField, '15');
      expect(breakField, findsOneWidget);
      await tester.enterText(breakField, '45');

      // Modify note
      final noteField = find.widgetWithText(TextField, 'Original note');
      expect(noteField, findsOneWidget);
      await tester.enterText(noteField, 'Updated test note');

      // Tap Save changes
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify DB update
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        final updatedShift = workVm.shifts.firstWhere((s) => s.id == shiftId);
        expect(updatedShift.breakMinutes, equals(45));
        expect(updatedShift.note, equals('Updated test note'));
        expect(updatedShift.status, equals(ShiftStatus.scheduled.value));
      });
    });

    testWidgets('Scheduled shift edited to completed status immediately removes Edit shift button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int shiftId = 0;
      await tester.runAsync(() async {
        final jobId = await jobRepo.add(
          name: 'Retail Associate',
          hourlyRateMinor: 2000,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final startAt = DateTime(today.year, today.month, today.day, 9, 0);
        final endAt = DateTime(today.year, today.month, today.day, 13, 0);

        shiftId = await shiftRepo.add(
          jobId: jobId,
          startAt: startAt,
          endAt: endAt,
          breakMinutes: 0,
          status: ShiftStatus.scheduled,
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap scheduled shift
      await tester.tap(find.text('Retail Associate').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit shift'), findsOneWidget);
      await tester.tap(find.text('Edit shift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Change status dropdown to Completed
      await tester.tap(find.text('Scheduled').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Wait for store to update
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        final updatedShift = workVm.shifts.firstWhere((s) => s.id == shiftId);
        expect(updatedShift.status, equals(ShiftStatus.completed.value));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap the shift again in calendar
      await tester.tap(find.text('Retail Associate').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Now it must be STRICTLY view-only (no Edit shift button!)
      expect(find.text('Edit shift'), findsNothing);
      expect(find.text('View in Work'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Cancel button in edit sheet dismisses dialog without persisting edits', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int shiftId = 0;
      await tester.runAsync(() async {
        final jobId = await jobRepo.add(
          name: 'Consultant',
          hourlyRateMinor: 5000,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        shiftId = await shiftRepo.add(
          jobId: jobId,
          startAt: DateTime(today.year, today.month, today.day, 14, 0),
          endAt: DateTime(today.year, today.month, today.day, 18, 0),
          breakMinutes: 10,
          status: ShiftStatus.scheduled,
          note: 'Keep this note',
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Consultant').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Edit shift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Edit the note field
      final noteField = find.widgetWithText(TextField, 'Keep this note');
      await tester.enterText(noteField, 'Discarded note changes');

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Dialog is dismissed
      expect(find.text('Save changes'), findsNothing);

      // Verify original note was NOT overwritten
      final shift = workVm.shifts.firstWhere((s) => s.id == shiftId);
      expect(shift.note, equals('Keep this note'));
    });
  });

  group('Empirical Challenge: Completed & In-Progress Strict View-Only Assertion', () {
    testWidgets('Completed shift (past) has NO Edit shift option under any circumstance', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        final jobId = await jobRepo.add(
          name: 'Past Shift Job',
          hourlyRateMinor: 3000,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        await shiftRepo.add(
          jobId: jobId,
          startAt: DateTime(today.year, today.month, today.day, 8, 0),
          endAt: DateTime(today.year, today.month, today.day, 12, 0),
          breakMinutes: 20,
          status: ShiftStatus.completed,
          note: 'Completed past shift',
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Past Shift Job').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit shift'), findsNothing);
      expect(find.text('View in Work'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('In-progress shift has NO Edit shift option (strictly view-only)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        final jobId = await jobRepo.add(
          name: 'Live Shift Job',
          hourlyRateMinor: 3500,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        await shiftRepo.add(
          jobId: jobId,
          startAt: DateTime(today.year, today.month, today.day, 9, 0),
          endAt: DateTime(today.year, today.month, today.day, 17, 0),
          breakMinutes: 0,
          status: ShiftStatus.inProgress,
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Live Shift Job').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit shift'), findsNothing);
      expect(find.text('View in Work'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('Empirical Challenge: Edge Cases & Error Resilience', () {
    testWidgets('Deleted shift before tap: clicking Edit shift gracefully handles missing shift', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      int shiftId = 0;
      await tester.runAsync(() async {
        final jobId = await jobRepo.add(
          name: 'Temp Deletion Job',
          hourlyRateMinor: 2500,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        shiftId = await shiftRepo.add(
          jobId: jobId,
          startAt: DateTime(today.year, today.month, today.day, 11, 0),
          endAt: DateTime(today.year, today.month, today.day, 15, 0),
          breakMinutes: 0,
          status: ShiftStatus.scheduled,
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Open item details bottom sheet
      await tester.tap(find.text('Temp Deletion Job').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit shift'), findsOneWidget);

      // Now delete shift from DB while sheet is open
      await tester.runAsync(() async {
        await shiftRepo.delete(shiftId);
        await Future.delayed(const Duration(milliseconds: 150));
      });

      // Tap Edit shift: shift is no longer in workVm.shifts
      // Must not crash or throw unhandled exception
      await tester.tap(find.text('Edit shift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Sheet was popped, dialog was not opened because shift == null
      expect(find.text('Save changes'), findsNothing);
    });

    testWidgets('Shift with null note and 0 break minutes opens and edits without error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        final jobId = await jobRepo.add(
          name: 'Zero Break Job',
          hourlyRateMinor: 2200,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        await shiftRepo.add(
          jobId: jobId,
          startAt: DateTime(today.year, today.month, today.day, 10, 0),
          endAt: DateTime(today.year, today.month, today.day, 12, 0),
          breakMinutes: 0,
          status: ShiftStatus.scheduled,
          note: null,
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Zero Break Job').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Edit shift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Save changes'), findsOneWidget);
      expect(find.widgetWithText(TextField, '0'), findsOneWidget);
    });

    testWidgets('Non-shift calendar item (transaction) has NO Edit shift or View in Work', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        final accId = await accountRepo.add(
          name: 'Main Checking',
          type: AccountType.bank,
          currencyCode: 'USD',
          openingBalanceMinor: 100000,
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 14, 0);

        await txRepo.add(
          accountId: accId,
          type: TransactionType.expense,
          category: 'groceries',
          amountMinor: 4500,
          occurredAt: today,
          note: 'Weekly Grocery',
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Switch filter or tap grocery transaction in calendar
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.transactions);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Weekly Grocery'), findsWidgets);
      await tester.ensureVisible(find.text('Weekly Grocery').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly Grocery').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify transaction bottom sheet has only Close action, never Edit shift
      expect(find.text('Edit shift'), findsNothing);
      expect(find.text('View in Work'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Missing Job with single job in DB falls back gracefully in edit dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Insert shift with an unmapped jobId (9999)
        await shiftRepo.add(
          jobId: 9999,
          startAt: DateTime(today.year, today.month, today.day, 13, 0),
          endAt: DateTime(today.year, today.month, today.day, 17, 0),
          breakMinutes: 0,
          status: ShiftStatus.scheduled,
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Falls back to localized Shift label
      expect(find.text('Work Shift'), findsWidgets);
      await tester.tap(find.text('Work Shift').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit shift'), findsOneWidget);
      await tester.tap(find.text('Edit shift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Since viewModel.jobs.length <= 1, no dropdown is rendered, edit sheet works cleanly!
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('Orphan shift jobId with multiple jobs in DB: stress test behavior', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.runAsync(() async {
        await jobRepo.add(
          name: 'Job Alpha',
          hourlyRateMinor: 2000,
          currencyCode: 'USD',
        );
        await jobRepo.add(
          name: 'Job Beta',
          hourlyRateMinor: 3000,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Shift with orphan jobId
        await shiftRepo.add(
          jobId: 9999,
          startAt: DateTime(today.year, today.month, today.day, 10, 0),
          endAt: DateTime(today.year, today.month, today.day, 14, 0),
          breakMinutes: 0,
          status: ShiftStatus.scheduled,
        );

        await Future.delayed(const Duration(milliseconds: 150));
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Work Shift'), findsWidgets);
      await tester.tap(find.text('Work Shift').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit shift'), findsOneWidget);
      await tester.tap(find.text('Edit shift'));
      await tester.pump();
      // DropdownButtonFormField asserts when initialValue is not found in items list
      final exception = tester.takeException();
      expect(exception, isA<AssertionError>());
      expect(
        exception.toString(),
        contains("There should be exactly one item with [DropdownButton]'s value: 9999"),
      );
    });
  });
}


