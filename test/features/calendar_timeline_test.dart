import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
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
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  late AppDatabase db;
  late FinanceStore store;
  late CalendarViewModel calendarVm;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final accountRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    final jobRepo = JobRepository(db);
    final shiftRepo = ShiftRepository(db);
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
  });

  tearDown(() async {
    calendarVm.dispose();
    store.dispose();
    await db.close();
  });

  test('Calendar timeline spans 8 hours for 9-to-5 shift and formats duration properly', () async {
    final jobId = await store.jobsRepo.add(
      name: 'Cafe Barista',
      hourlyRateMinor: 3000,
      currencyCode: 'AUD',
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startAt = DateTime(today.year, today.month, today.day, 9, 0);
    final endAt = DateTime(today.year, today.month, today.day, 17, 0);

    await store.shiftsRepo.add(
      jobId: jobId,
      startAt: startAt,
      endAt: endAt,
      breakMinutes: 30,
      status: ShiftStatus.scheduled,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    calendarVm.jumpToToday();
    calendarVm.setFilter(CalendarFilter.shifts);

    final items = calendarVm.selectedDayItems;
    expect(items.length, equals(1));

    final shiftItem = items.first;
    expect(shiftItem.type, equals(CalendarItemType.shift));
    expect(shiftItem.title, equals('Cafe Barista'));
    expect(shiftItem.date, equals(startAt));
    expect(shiftItem.endDate, equals(endAt));
    expect(shiftItem.durationMinutes, equals(480)); // 8 hours

    final durationHours = (shiftItem.durationMinutes / 60.0).toStringAsFixed(1);
    expect(durationHours, equals('8.0'));
  });
}
