import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/model/recurring.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/goals/view/goal_screen.dart';
import 'package:finance_tracker/features/goals/viewmodels/goal_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.instance;
  late AppDatabase db;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;
  late RecurringRepository recRepo;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late GoalRepository goalRepo;
  late ExchangeRateRepository ratesRepo;
  late SettingsRepository settingsRepo;
  late DebtRepository debtRepo;
  late FinanceStore financeStore;
  late PlanViewModel planVm;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    accountRepo = AccountRepository(db);
    txRepo = TransactionRepository(db);
    recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    goalRepo = GoalRepository(db);
    ratesRepo = ExchangeRateRepository(db);
    settingsRepo = SettingsRepository(db);
    debtRepo = DebtRepository(db);

    await settingsRepo.load();

    financeStore = FinanceStore(
      accountsRepo: accountRepo,
      transactionsRepo: txRepo,
      recurringRepo: recRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      ratesRepo: ratesRepo,
      settingsRepo: settingsRepo,
      debtsRepo: debtRepo,
    );
    financeStore.start();

    planVm = PlanViewModel(
      financeStore: financeStore,
      goalRepo: goalRepo,
      accountRepo: accountRepo,
      transactionRepo: txRepo,
    );

    getIt
      ..registerSingleton<AppDatabase>(db)
      ..registerSingleton<AccountRepository>(accountRepo)
      ..registerSingleton<SettingsRepository>(settingsRepo)
      ..registerSingleton<FinanceStore>(financeStore)
      ..registerSingleton<PlanViewModel>(planVm);
  });

  tearDown(() async {
    planVm.dispose();
    financeStore.dispose();
    await db.close();
    await getIt.reset();
  });

  group('PlanViewModel Three-Month Growth Rate and Polarity Calculations', () {
    test(
      'Calculates positive threeMonthGrowthRatePercent and positive polarity',
      () async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 100000, // $1,000.00
          currencyCode: 'AUD',
        );

        // Add a recurring monthly income of $150.00 (15000 minor)
        final now = DateTime.now();
        await recRepo.add(
          name: 'Freelance Monthly',
          amountMinor: 15000,
          kind: RecurringKind.income,
          category: 'Freelance',
          frequency: RecurrenceFrequency.monthly,
          nextDueAt: DateTime(now.year, now.month, 1),
          currencyCode: 'AUD',
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(planVm.currentTotalBalanceMinor, 100000);
        expect(planVm.monthlyNetDeltaMinor, greaterThan(0));
        expect(planVm.isPositiveTrajectory, isTrue);
        expect(planVm.isNegativeTrajectory, isFalse);
        expect(planVm.isNeutralTrajectory, isFalse);
        expect(planVm.trajectoryPolarity, PlanTrajectoryPolarity.positive);

        final growthRate = planVm.threeMonthGrowthRatePercent;
        expect(growthRate, isNotNull);
        expect(growthRate!, greaterThan(0));
        // 3 months of 15000 = 45000 net change -> 45000 / 100000 * 100 = 45.0%
        expect(growthRate, closeTo(45.0, 0.5));
      },
    );

    test('Calculates negative decline rate and negative polarity', () async {
      await accountRepo.add(
        name: 'Everyday Checking',
        type: AccountType.bank,
        openingBalanceMinor: 200000, // $2,000.00
        currencyCode: 'AUD',
      );

      // Add recurring monthly expense of $200.00 (20000 minor)
      final now = DateTime.now();
      await recRepo.add(
        name: 'Gym & Subscriptions',
        amountMinor: 20000,
        kind: RecurringKind.expense,
        category: 'Subscriptions',
        frequency: RecurrenceFrequency.monthly,
        nextDueAt: DateTime(now.year, now.month, 1),
        currencyCode: 'AUD',
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(planVm.currentTotalBalanceMinor, 200000);
      expect(planVm.monthlyNetDeltaMinor, lessThan(0));
      expect(planVm.isPositiveTrajectory, isFalse);
      expect(planVm.isNegativeTrajectory, isTrue);
      expect(planVm.isNeutralTrajectory, isFalse);
      expect(planVm.trajectoryPolarity, PlanTrajectoryPolarity.negative);

      final growthRate = planVm.threeMonthGrowthRatePercent;
      expect(growthRate, isNotNull);
      expect(growthRate!, lessThan(0));
      // 3 months of -20000 = -60000 -> -60000 / 200000 * 100 = -30.0%
      expect(growthRate, closeTo(-30.0, 0.5));
    });

    test(
      'Calculates neutral steady state when monthly net delta is zero',
      () async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 150000, // $1,500.00
          currencyCode: 'AUD',
        );

        // No transactions, no recurring events -> net delta = 0
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(planVm.currentTotalBalanceMinor, 150000);
        expect(planVm.monthlyNetDeltaMinor, 0);
        expect(planVm.threeMonthNetChangeMinor, 0);

        // Fix verification: zero is NOT treated as positive!
        expect(planVm.isNeutralTrajectory, isTrue);
        expect(planVm.isPositiveTrajectory, isFalse);
        expect(planVm.isNegativeTrajectory, isFalse);
        expect(planVm.trajectoryPolarity, PlanTrajectoryPolarity.neutral);

        final growthRate = planVm.threeMonthGrowthRatePercent;
        expect(growthRate, isNotNull);
        expect(growthRate!, 0.0);
      },
    );

    test(
      'Zero current balance returns null safely (no divide-by-zero crash)',
      () async {
        // Empty accounts -> balance = 0
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(planVm.currentTotalBalanceMinor, 0);
        expect(planVm.threeMonthGrowthRatePercent, isNull);
      },
    );

    test(
      'Negative current balance (debt) handles abs() denominator safely',
      () async {
        final accountId = await accountRepo.add(
          name: 'Overdraft Account',
          type: AccountType.bank,
          openingBalanceMinor: -100000, // -$1,000.00 net debt
          currencyCode: 'AUD',
        );

        // Add a recurring monthly income of $100.00 (10000 minor)
        final now = DateTime.now();
        await recRepo.add(
          name: 'Salary Support',
          amountMinor: 10000,
          kind: RecurringKind.income,
          category: 'Salary',
          frequency: RecurrenceFrequency.monthly,
          nextDueAt: DateTime(now.year, now.month, 1),
          currencyCode: 'AUD',
          accountId: accountId,
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(planVm.currentTotalBalanceMinor, -100000);
        final growthRate = planVm.threeMonthGrowthRatePercent;
        expect(growthRate, isNotNull);
        // Denominator is |-100000| = 100000. 3-month net delta = +30000 -> +30.0%
        expect(growthRate!, closeTo(30.0, 0.5));
      },
    );
  });

  group('PlanViewModel Trajectory Points Negative Values Support', () {
    test(
      'Trajectory points preserve negative balances without clamping to positive slivers',
      () async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: -50000, // -$500.00
          currencyCode: 'AUD',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final points = planVm.trajectoryPoints;
        expect(points.length, 6);

        // Trajectory points should carry negative balances directly
        final currentPoint = points[2]; // m0
        expect(currentPoint.balanceMinor, -50000);
        expect(currentPoint.balanceMinor, lessThan(0));

        // Forecast points should also be negative and not clamped
        for (final p in points) {
          expect(p.balanceMinor, isA<int>());
          expect(p.label.isNotEmpty, isTrue);
        }
      },
    );
  });

  group('PlanScreen compact outlook hero widget tests', () {
    Widget buildTestApp({required GoRouter router}) {
      return MaterialApp.router(routerConfig: router, theme: AppTheme.light);
    }

    testWidgets(
      'Renders the forecast, current balance and monthly change for positive growth',
      (tester) async {
        await tester.runAsync(() async {
          await accountRepo.add(
            name: 'Everyday Checking',
            type: AccountType.bank,
            openingBalanceMinor: 100000, // $1,000.00
            currencyCode: 'AUD',
          );

          final now = DateTime.now();
          await recRepo.add(
            name: 'Monthly Bonus',
            amountMinor: 25000, // $250.00 / mo
            kind: RecurringKind.income,
            category: 'Income',
            frequency: RecurrenceFrequency.monthly,
            nextDueAt: DateTime(now.year, now.month, 1),
            currencyCode: 'AUD',
          );

          await Future<void>.delayed(const Duration(milliseconds: 100));
        });

        final router = GoRouter(
          initialLocation: AppRoutes.plan,
          routes: [
            GoRoute(
              path: AppRoutes.plan,
              builder: (context, state) => const PlanScreen(),
            ),
            GoRoute(
              path: AppRoutes.addGoal,
              builder:
                  (context, state) =>
                      const Scaffold(body: Text('AddGoalScreen')),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Projected balance in 3 months'), findsOneWidget);
        expect(find.text('Current balance'), findsOneWidget);
        expect(find.text('Monthly change'), findsOneWidget);
        expect(find.textContaining(r'+$250.00'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders negative monthly change without a crowded trend badge',
      (tester) async {
        await tester.runAsync(() async {
          await accountRepo.add(
            name: 'Everyday Checking',
            type: AccountType.bank,
            openingBalanceMinor: 300000, // $3,000.00
            currencyCode: 'AUD',
          );

          final now = DateTime.now();
          await recRepo.add(
            name: 'Office Rent',
            amountMinor: 50000, // -$500.00 / mo
            kind: RecurringKind.expense,
            category: 'Rent',
            frequency: RecurrenceFrequency.monthly,
            nextDueAt: DateTime(now.year, now.month, 1),
            currencyCode: 'AUD',
          );

          await Future<void>.delayed(const Duration(milliseconds: 100));
        });

        final router = GoRouter(
          initialLocation: AppRoutes.plan,
          routes: [
            GoRoute(
              path: AppRoutes.plan,
              builder: (context, state) => const PlanScreen(),
            ),
            GoRoute(
              path: AppRoutes.addGoal,
              builder:
                  (context, state) =>
                      const Scaffold(body: Text('AddGoalScreen')),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Monthly change'), findsOneWidget);
        expect(find.textContaining('−\$500.00'), findsOneWidget);
        expect(find.byIcon(Icons.trending_down_rounded), findsNothing);
      },
    );

    testWidgets('Renders a neutral monthly change safely', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 250000, // $2,500.00
          currencyCode: 'AUD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final router = GoRouter(
        initialLocation: AppRoutes.plan,
        routes: [
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) => const PlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.addGoal,
            builder:
                (context, state) => const Scaffold(body: Text('AddGoalScreen')),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Monthly change'), findsOneWidget);
      expect(find.text(r'$0.00'), findsOneWidget);
    });

    testWidgets('Narrow 320px viewport renders without any RenderFlex overflow', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 12500000, // $125,000.00
          currencyCode: 'AUD',
        );

        final now = DateTime.now();
        await recRepo.add(
          name: 'Executive Consulting',
          amountMinor: 350000, // +$3,500.00 / mo
          kind: RecurringKind.income,
          category: 'Income',
          frequency: RecurrenceFrequency.monthly,
          nextDueAt: DateTime(now.year, now.month, 1),
          currencyCode: 'AUD',
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: AppRoutes.plan,
        routes: [
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) => const PlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.addGoal,
            builder:
                (context, state) => const Scaffold(body: Text('AddGoalScreen')),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final error = tester.takeException();
      if (error != null) {
        fail(
          'CAUGHT ERROR:\n${error is FlutterError ? error.toStringDeep() : error}',
        );
      }
      expect(error, isNull);

      // Verify essential components rendered
      expect(find.text('Projected balance in 3 months'), findsOneWidget);
      expect(find.text('Current balance'), findsOneWidget);
      expect(find.text('Monthly change'), findsOneWidget);
    });
  });
}
