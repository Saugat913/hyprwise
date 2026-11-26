import 'package:drift/native.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

void main() {
  group('Production Hardening Verification', () {
    late AppDatabase db;
    late AccountRepository accountRepo;
    late TransactionRepository transactionRepo;
    late ShiftRepository shiftRepo;
    late JobRepository jobRepo;
    late GoalRepository goalRepo;
    late SettingsRepository settingsRepo;
    late FinanceStore financeStore;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      accountRepo = AccountRepository(db);
      await accountRepo.ensureFixedTwoAccounts('NPR');

      transactionRepo = TransactionRepository(db);
      final recurringRepo = RecurringRepository(db);
      jobRepo = JobRepository(db);
      shiftRepo = ShiftRepository(db);
      goalRepo = GoalRepository(db);
      final ratesRepo = ExchangeRateRepository(db);
      settingsRepo = SettingsRepository(db);
      await settingsRepo.load();
      await settingsRepo.setBaseCurrency('NPR');
      final debtsRepo = DebtRepository(db);

      financeStore = FinanceStore(
        accountsRepo: accountRepo,
        transactionsRepo: transactionRepo,
        recurringRepo: recurringRepo,
        jobsRepo: jobRepo,
        shiftsRepo: shiftRepo,
        goalsRepo: goalRepo,
        ratesRepo: ratesRepo,
        settingsRepo: settingsRepo,
        debtsRepo: debtsRepo,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    tearDown(() async {
      await db.close();
    });

    test('Assistant does NOT auto-insert transactions for hypothetical questions', () async {
      final vm = AssistantViewModel(
        financeStore: financeStore,
        transactionRepo: transactionRepo,
        shiftRepo: shiftRepo,
        goalRepo: goalRepo,
      );

      await vm.sendMessage('Can I afford to buy a 500 laptop?');
      final txs = await db.select(db.transactions).get();
      expect(txs, isEmpty);
    });

    test('DataRepository.importJson rejects malformed payload without wiping existing data', () async {
      final dataRepo = DataRepository(db);
      final accountsBefore = await db.select(db.accounts).get();
      expect(accountsBefore, isNotEmpty);

      await expectLater(
        dataRepo.importJson('{"not_a_valid_backup": true}'),
        throwsFormatException,
      );

      final accountsAfter = await db.select(db.accounts).get();
      expect(accountsAfter.length, accountsBefore.length);
    });

    test('DataRepository.exportCsv uses active base currency instead of hardcoded AUD', () async {
      final dataRepo = DataRepository(db);
      final acc = (await db.select(db.accounts).get()).first;
      await transactionRepo.add(
        accountId: acc.id,
        amountMinor: 25000,
        type: TransactionType.expense,
        category: 'Groceries',
        note: 'Bhatbhateni',
        occurredAt: DateTime(2026, 5, 1),
      );

      final csv = await dataRepo.exportCsv();
      expect(csv, contains('NPR'));
      expect(csv, isNot(contains('AUD')));
    });

    test('WorkViewModel transitions scheduled shift via startScheduledShift and blocks concurrent live shifts', () async {
      final jobId = await jobRepo.add(
        name: 'Barista',
        hourlyRateMinor: 2800,
        currencyCode: 'NPR',
      );
      final now = DateTime.now();
      final scheduledId = await shiftRepo.add(
        jobId: jobId,
        startAt: now.add(const Duration(hours: 2)),
        endAt: now.add(const Duration(hours: 6)),
        status: ShiftStatus.scheduled,
      );

      final vm = WorkViewModel(
        financeStore: financeStore,
        jobRepo: jobRepo,
        shiftRepo: shiftRepo,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final scheduled = (await db.select(db.shifts).get()).firstWhere((s) => s.id == scheduledId);
      final startedId = await vm.startScheduledShift(scheduled);
      expect(startedId, scheduledId);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final updated = (await db.select(db.shifts).get()).firstWhere((s) => s.id == scheduledId);
      expect(updated.status, ShiftStatus.inProgress.value);

      // Attempting to clock in a second concurrent shift returns the existing active shift ID
      final secondId = await vm.startShift(jobId: jobId);
      expect(secondId, scheduledId);

      vm.dispose();
    });

    test('Scheduling 80+ recurring shifts batches into 1 store update, caches forecast/calendar, and batch-undoes cleanly', () async {
      financeStore.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final jobId = await jobRepo.add(
        name: 'Hospitality',
        hourlyRateMinor: 3000,
        currencyCode: 'NPR',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final workVm = WorkViewModel(
        financeStore: financeStore,
        jobRepo: jobRepo,
        shiftRepo: shiftRepo,
      );
      final calVm = CalendarViewModel(financeStore: financeStore);

      var storeNotifications = 0;
      void onStore() => storeNotifications++;
      financeStore.addListener(onStore);

      // 5 weekdays/week × 20 weeks = 100 shifts (exceeds user's 80-shift scenario)
      final sw = Stopwatch()..start();
      final createdIds = await workVm.scheduleRecurringShifts(
        jobId: jobId,
        weekdays: {1, 2, 3, 4, 5},
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        weeksCount: 20,
        breakMinutes: 30,
      );
      sw.stop();

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(createdIds.length, 100);
      expect(financeStore.shifts.length, 100);
      // Single batched SQLite transaction emits <= 2 notifications (never 100!)
      expect(storeNotifications, lessThanOrEqualTo(2));
      // Verify forecast memoization returns exact same cached instance
      final fc1 = financeStore.forecast(horizonDays: 90);
      final fc2 = financeStore.forecast(horizonDays: 90);
      expect(identical(fc1, fc2), isTrue);

      // Verify CalendarViewModel O(1) day lookup & cached selectedDayItems
      final dayItems1 = calVm.selectedDayItems;
      final dayItems2 = calVm.selectedDayItems;
      expect(identical(dayItems1, dayItems2), isTrue);
      for (final d in calVm.weekStrip) {
        calVm.hasEventsOn(d);
      }

      // Batch delete (Undo) removes all 100 shifts in 1 transaction
      storeNotifications = 0;
      await workVm.deleteShifts(createdIds);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(financeStore.shifts, isEmpty);
      expect(storeNotifications, lessThanOrEqualTo(2));

      financeStore.removeListener(onStore);
      calVm.dispose();
      workVm.dispose();
      financeStore.dispose();
    });
  });
}
