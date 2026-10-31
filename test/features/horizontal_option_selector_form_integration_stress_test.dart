import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/accounts/view/wizards/add_account_wizard.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/shared/widgets/horizontal_option_selector.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/view/widgets/edit_shift_sheet.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FinanceStore store;
  late WorkViewModel workVm;
  late AccountsViewModel accountsVm;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late AccountRepository accountRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = AccountRepository(db);
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

    workVm = WorkViewModel(
      financeStore: store,
      jobRepo: jobRepo,
      shiftRepo: shiftRepo,
    );
    accountsVm = AccountsViewModel(
      financeStore: store,
      accountRepo: accountRepo,
    );

    if (getIt.isRegistered<FinanceStore>()) getIt.unregister<FinanceStore>();
    if (getIt.isRegistered<WorkViewModel>()) getIt.unregister<WorkViewModel>();
    if (getIt.isRegistered<AccountsViewModel>()) getIt.unregister<AccountsViewModel>();

    getIt.registerSingleton<FinanceStore>(store);
    getIt.registerSingleton<WorkViewModel>(workVm);
    getIt.registerSingleton<AccountsViewModel>(accountsVm);
  });

  tearDown(() async {
    if (getIt.isRegistered<FinanceStore>()) getIt.unregister<FinanceStore>();
    if (getIt.isRegistered<WorkViewModel>()) getIt.unregister<WorkViewModel>();
    if (getIt.isRegistered<AccountsViewModel>()) getIt.unregister<AccountsViewModel>();
    workVm.dispose();
    accountsVm.dispose();
    store.dispose();
    await db.close();
  });

  group('Horizontal Option Selectors Form Interaction Stress Tests', () {
    testWidgets('FI-1: AddAccountWizard uses structured GridView for AccountType and transitions correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddAccountWizard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that structured GridView is rendered for account selection
      expect(find.byType(GridView), findsOneWidget);

      // Verify that Cash, Everyday Bank, Digital Wallet, Savings Account are rendered
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Everyday account'), findsOneWidget);
      expect(find.text('Digital wallet'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);

      // Tap on 'Digital wallet'
      await tester.tap(find.text('Digital wallet'));
      await tester.pumpAndSettle();

      // Checkmark must be visible on selected option
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap Next to advance wizard
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2 should now be visible
      expect(find.text('What is the balance right now?'), findsOneWidget);
    });

    testWidgets('FI-2: HorizontalOptionSelector<ShiftStatus> updates status in showEditShiftDialog', (tester) async {
      int jobId = 0;
      int shiftId = 0;
      await tester.runAsync(() async {
        jobId = await jobRepo.add(
          name: 'Design Engineer',
          hourlyRateMinor: 4500,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        shiftId = await shiftRepo.add(
          jobId: jobId,
          startAt: now.add(const Duration(days: 1, hours: 9)),
          endAt: now.add(const Duration(days: 1, hours: 17)),
          status: ShiftStatus.scheduled,
          breakMinutes: 30,
        );
        await Future.delayed(const Duration(milliseconds: 150));
      });

      final shift = store.shifts.firstWhere((s) => s.id == shiftId);
      final job = store.jobs.firstWhere((j) => j.id == jobId);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showEditShiftDialog(
                      context,
                      shift,
                      job,
                      workVm,
                    );
                  },
                  child: const Text('Open Edit Sheet'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open sheet
      await tester.tap(find.text('Open Edit Sheet'));
      await tester.pumpAndSettle();

      // HorizontalOptionSelector<ShiftStatus> should be present
      expect(find.byType(HorizontalOptionSelector<ShiftStatus>), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);

      // Verify Scheduled is currently selected
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap In progress
      await tester.tap(find.text('In progress'));
      await tester.pumpAndSettle();

      // Checkmark moves to In Progress
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap Cancel to dismiss cleanly
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(HorizontalOptionSelector<ShiftStatus>), findsNothing);
    });

    testWidgets('FI-3: Multiple jobs picker renders HorizontalOptionSelector<int> when jobs.length > 1', (tester) async {
      int job1Id = 0;
      int shiftId = 0;

      await tester.runAsync(() async {
        job1Id = await jobRepo.add(
          name: 'Barista Job',
          hourlyRateMinor: 3000,
          currencyCode: 'USD',
        );
        await jobRepo.add(
          name: 'Tutor Job',
          hourlyRateMinor: 5000,
          currencyCode: 'USD',
        );

        final now = DateTime.now();
        shiftId = await shiftRepo.add(
          jobId: job1Id,
          startAt: now.add(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 1, hours: 4)),
          status: ShiftStatus.scheduled,
        );
        await Future.delayed(const Duration(milliseconds: 150));
      });

      final shift = store.shifts.firstWhere((s) => s.id == shiftId);
      final job1 = store.jobs.firstWhere((j) => j.id == job1Id);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showEditShiftDialog(
                      context,
                      shift,
                      job1,
                      workVm,
                    );
                  },
                  child: const Text('Open Multi Job Edit Sheet'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Multi Job Edit Sheet'));
      await tester.pumpAndSettle();

      // Both HorizontalOptionSelector<int> (for jobs) and HorizontalOptionSelector<ShiftStatus> should be present
      expect(find.byType(HorizontalOptionSelector<int>), findsOneWidget);
      expect(find.byType(HorizontalOptionSelector<ShiftStatus>), findsOneWidget);

      // Verify jobs are listed horizontally
      expect(find.text('Barista Job'), findsOneWidget);
      expect(find.text('Tutor Job'), findsOneWidget);

      // Switch job from Barista to Tutor
      await tester.tap(find.text('Tutor Job'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
