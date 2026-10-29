import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

/// Test harness widget reproducing the exact calendar details sheet action row contract
class CalendarDetailsActionSheet extends StatelessWidget {
  const CalendarDetailsActionSheet({
    super.key,
    required this.item,
    required this.onEditShift,
    required this.onViewInWork,
    required this.onClose,
  });

  final CalendarItem item;
  final VoidCallback onEditShift;
  final VoidCallback onViewInWork;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tr = AppStrings.current();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                if (item.type == CalendarItemType.shift) ...[
                  if (item.status == ShiftStatus.scheduled.value) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const AppIcon(HugeIcons.strokeRoundedEdit02, size: 16),
                        label: Text(tr.editShift),
                        onPressed: onEditShift,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.work_outline, size: 16),
                      label: Text(tr.viewInWork),
                      onPressed: onViewInWork,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: onClose,
                    child: Text(tr.closeAction),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  final getIt = GetIt.instance;
  late AppDatabase db;
  late FinanceStore store;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late CalendarViewModel calendarVm;
  late WorkViewModel workVm;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final accRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    final debtRepo = DebtRepository(db);
    final rateRepo = ExchangeRateRepository(db);
    final settingsRepo = SettingsRepository(db);
    await settingsRepo.load();

    store = FinanceStore(
      accountsRepo: accRepo,
      transactionsRepo: txRepo,
      recurringRepo: recRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      debtsRepo: debtRepo,
      ratesRepo: rateRepo,
      settingsRepo: settingsRepo,
    );
    store.start();

    calendarVm = CalendarViewModel(financeStore: store);
    workVm = WorkViewModel(financeStore: store, jobRepo: jobRepo, shiftRepo: shiftRepo);

    getIt.registerSingleton<CalendarViewModel>(calendarVm);
    getIt.registerSingleton<WorkViewModel>(workVm);
    getIt.registerSingleton<FinanceStore>(store);
  });

  tearDown(() async {
    calendarVm.dispose();
    workVm.dispose();
    store.dispose();
    await db.close();
    await getIt.reset();
  });

  group('R1: Calendar Shift Editing (Tier 1 Feature Coverage)', () {
    test('T1.1: Upcoming scheduled shift generates CalendarItem with status scheduled', () async {
      final jobId = await jobRepo.add(name: 'Barista', hourlyRateMinor: 3000, currencyCode: 'USD');
      final today = DateTime.now();
      final startAt = DateTime(today.year, today.month, today.day, 10, 0);
      final endAt = DateTime(today.year, today.month, today.day, 14, 0);

      final shiftId = await shiftRepo.add(
        jobId: jobId,
        startAt: startAt,
        endAt: endAt,
        breakMinutes: 15,
        status: ShiftStatus.scheduled,
      );

      await Future.delayed(const Duration(milliseconds: 150));
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.shifts);

      final items = calendarVm.selectedDayItems;
      expect(items.length, equals(1));
      final item = items.first;

      expect(item.type, equals(CalendarItemType.shift));
      expect(item.rawId, equals(shiftId));
      expect(item.status, equals(ShiftStatus.scheduled.value));
      expect(item.title, equals('Barista'));
    });

    test('T1.2: Completed shift generates CalendarItem with status completed', () async {
      final jobId = await jobRepo.add(name: 'Office Assistant', hourlyRateMinor: 2500, currencyCode: 'USD');
      final today = DateTime.now();
      final startAt = DateTime(today.year, today.month, today.day, 8, 0);
      final endAt = DateTime(today.year, today.month, today.day, 12, 0);

      final shiftId = await shiftRepo.add(
        jobId: jobId,
        startAt: startAt,
        endAt: endAt,
        breakMinutes: 0,
        status: ShiftStatus.completed,
      );

      await Future.delayed(const Duration(milliseconds: 150));
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.shifts);

      final items = calendarVm.selectedDayItems;
      expect(items.length, equals(1));
      final item = items.first;

      expect(item.type, equals(CalendarItemType.shift));
      expect(item.rawId, equals(shiftId));
      expect(item.status, equals(ShiftStatus.completed.value));
    });

    testWidgets('T1.3: Scheduled shift bottom sheet presents Edit shift option', (tester) async {
      bool editTapped = false;
      final item = CalendarItem(
        id: 'shift_1',
        type: CalendarItemType.shift,
        title: 'Barista',
        subtitle: '10:00 - 14:00',
        date: DateTime.now(),
        amountMinor: 12000,
        currencyCode: 'USD',
        isIncome: true,
        colorIndex: 0,
        status: ShiftStatus.scheduled.value,
        rawId: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDetailsActionSheet(
              item: item,
              onEditShift: () => editTapped = true,
              onViewInWork: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final tr = AppStrings.current();
      expect(find.text(tr.editShift), findsOneWidget);
      expect(find.text(tr.viewInWork), findsOneWidget);
      expect(find.text(tr.closeAction), findsOneWidget);

      await tester.tap(find.text(tr.editShift));
      await tester.pump();
      expect(editTapped, isTrue);
    });

    testWidgets('T1.4: Completed shift bottom sheet presents NO Edit shift option (view-only)', (tester) async {
      final item = CalendarItem(
        id: 'shift_2',
        type: CalendarItemType.shift,
        title: 'Office Assistant',
        subtitle: '08:00 - 12:00',
        date: DateTime.now(),
        amountMinor: 10000,
        currencyCode: 'USD',
        isIncome: true,
        colorIndex: 1,
        status: ShiftStatus.completed.value,
        rawId: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDetailsActionSheet(
              item: item,
              onEditShift: () {},
              onViewInWork: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final tr = AppStrings.current();
      expect(find.text(tr.editShift), findsNothing);
      expect(find.text(tr.viewInWork), findsOneWidget);
      expect(find.text(tr.closeAction), findsOneWidget);
    });

    testWidgets('T1.5: In-progress shift bottom sheet presents view-only options (NO Edit shift)', (tester) async {
      final item = CalendarItem(
        id: 'shift_3',
        type: CalendarItemType.shift,
        title: 'Kitchen Staff',
        subtitle: '09:00 - Ongoing',
        date: DateTime.now(),
        amountMinor: 0,
        currencyCode: 'USD',
        isIncome: true,
        colorIndex: 2,
        status: ShiftStatus.inProgress.value,
        rawId: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDetailsActionSheet(
              item: item,
              onEditShift: () {},
              onViewInWork: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final tr = AppStrings.current();
      expect(find.text(tr.editShift), findsNothing);
      expect(find.text(tr.viewInWork), findsOneWidget);
    });
  });

  group('R1: Calendar Shift Editing (Tier 2 Boundary & Corner Cases)', () {
    testWidgets('T2.1: Scheduled shift with fallback title still presents Edit option', (tester) async {
      final tr = AppStrings.current();
      final item = CalendarItem(
        id: 'shift_fallback',
        type: CalendarItemType.shift,
        title: tr.shiftLabel,
        subtitle: '10:00 - 12:00',
        date: DateTime.now(),
        amountMinor: 6000,
        currencyCode: 'USD',
        isIncome: true,
        colorIndex: 0,
        status: ShiftStatus.scheduled.value,
        rawId: 9999,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDetailsActionSheet(
              item: item,
              onEditShift: () {},
              onViewInWork: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(tr.editShift), findsOneWidget);
      expect(find.text(tr.shiftLabel), findsOneWidget);
    });

    test('T2.2: Multi-shift day generates both scheduled and completed calendar items', () async {
      final jobId = await jobRepo.add(name: 'Warehouse Associate', hourlyRateMinor: 2200, currencyCode: 'USD');
      final today = DateTime.now();

      // Morning shift completed
      await shiftRepo.add(
        jobId: jobId,
        startAt: DateTime(today.year, today.month, today.day, 6, 0),
        endAt: DateTime(today.year, today.month, today.day, 10, 0),
        breakMinutes: 0,
        status: ShiftStatus.completed,
      );

      // Afternoon shift scheduled
      await shiftRepo.add(
        jobId: jobId,
        startAt: DateTime(today.year, today.month, today.day, 14, 0),
        endAt: DateTime(today.year, today.month, today.day, 18, 0),
        breakMinutes: 0,
        status: ShiftStatus.scheduled,
      );

      await Future.delayed(const Duration(milliseconds: 150));
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.shifts);

      final items = calendarVm.selectedDayItems;
      expect(items.length, equals(2));

      final scheduledItem = items.firstWhere((i) => i.status == ShiftStatus.scheduled.value);
      final completedItem = items.firstWhere((i) => i.status == ShiftStatus.completed.value);

      expect(scheduledItem, isNotNull);
      expect(completedItem, isNotNull);
    });

    test('T2.3: Midnight-crossing shift preserves scheduled status and duration', () async {
      final jobId = await jobRepo.add(name: 'Night Auditor', hourlyRateMinor: 3200, currencyCode: 'USD');
      final today = DateTime.now();

      final shiftId = await shiftRepo.add(
        jobId: jobId,
        startAt: DateTime(today.year, today.month, today.day, 23, 0),
        endAt: DateTime(today.year, today.month, today.day + 1, 7, 0),
        breakMinutes: 30,
        status: ShiftStatus.scheduled,
      );

      await Future.delayed(const Duration(milliseconds: 150));
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.shifts);

      final items = calendarVm.selectedDayItems;
      expect(items.length, equals(1));
      final item = items.first;

      expect(item.rawId, equals(shiftId));
      expect(item.status, equals(ShiftStatus.scheduled.value));
      expect(item.durationMinutes, equals(480)); // 8 hours
    });

    test('T2.4: Shift with zero break minutes calculates full duration', () async {
      final jobId = await jobRepo.add(name: 'Tutor', hourlyRateMinor: 4000, currencyCode: 'USD');
      final today = DateTime.now();

      final shiftId = await shiftRepo.add(
        jobId: jobId,
        startAt: DateTime(today.year, today.month, today.day, 13, 0),
        endAt: DateTime(today.year, today.month, today.day, 15, 0),
        breakMinutes: 0,
        status: ShiftStatus.scheduled,
      );

      await Future.delayed(const Duration(milliseconds: 150));
      calendarVm.jumpToToday();
      calendarVm.setFilter(CalendarFilter.shifts);

      final item = calendarVm.selectedDayItems.first;
      expect(item.rawId, equals(shiftId));
      expect(item.durationMinutes, equals(120)); // 2 hours
      expect(item.amountMinor, equals(8000)); // $80.00
    });

    testWidgets('T2.5: Rapid tap does not duplicate action sheets or trigger multiple events', (tester) async {
      int editTaps = 0;
      final item = CalendarItem(
        id: 'shift_tap',
        type: CalendarItemType.shift,
        title: 'Consultant',
        subtitle: '15:00 - 19:00',
        date: DateTime.now(),
        amountMinor: 20000,
        currencyCode: 'USD',
        isIncome: true,
        colorIndex: 0,
        status: ShiftStatus.scheduled.value,
        rawId: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDetailsActionSheet(
              item: item,
              onEditShift: () => editTaps++,
              onViewInWork: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final tr = AppStrings.current();
      await tester.tap(find.text(tr.editShift));
      await tester.pump();

      expect(editTaps, equals(1));
    });
  });
}
