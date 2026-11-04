import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/home/view/home_screen.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/reminder_rule_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.instance;
  late AppDatabase db;
  late AccountRepository accountRepo;
  late DebtRepository debtRepo;
  late ExchangeRateRepository ratesRepo;
  late SettingsRepository settingsRepo;
  late ReminderRuleRepository reminderRuleRepo;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late FinanceStore financeStore;
  late HomeViewModel homeVm;
  late WorkViewModel workVm;
  late AlertsViewModel alertsVm;
  late SubscriptionService subService;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    accountRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    ratesRepo = ExchangeRateRepository(db);
    settingsRepo = SettingsRepository(db);
    debtRepo = DebtRepository(db);
    reminderRuleRepo = ReminderRuleRepository(db);

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

    homeVm = HomeViewModel(
      financeStore: financeStore,
      settingsRepo: settingsRepo,
    );
    workVm = WorkViewModel(
      financeStore: financeStore,
      jobRepo: jobRepo,
      shiftRepo: shiftRepo,
    );
    alertsVm = AlertsViewModel(
      financeStore: financeStore,
      settingsRepo: settingsRepo,
      reminderRuleRepo: reminderRuleRepo,
    );
    final authService = AuthService();
    subService = SubscriptionService(authService: authService);

    getIt
      ..registerSingleton<AppDatabase>(db)
      ..registerSingleton<AccountRepository>(accountRepo)
      ..registerSingleton<SettingsRepository>(settingsRepo)
      ..registerSingleton<FinanceStore>(financeStore)
      ..registerSingleton<HomeViewModel>(homeVm)
      ..registerSingleton<WorkViewModel>(workVm)
      ..registerSingleton<AlertsViewModel>(alertsVm)
      ..registerSingleton<SubscriptionService>(subService);
  });

  tearDown(() async {
    homeVm.dispose();
    workVm.dispose();
    alertsVm.dispose();
    financeStore.dispose();
    await db.close();
    await getIt.reset();
  });

  group('HomeViewModel Usable vs Non-Usable Balance Calculations', () {
    test('Partitions everyday checking and savings with exact identity match', () async {
      await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 420000, // $4,200.00
        currencyCode: 'AUD',
      );
      await accountRepo.add(
        name: 'High Interest Savings',
        type: AccountType.savings,
        openingBalanceMinor: 580000, // $5,800.00
        currencyCode: 'AUD',
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 420000);
      expect(homeVm.nonUsableBalanceMinor, 580000);
      expect(homeVm.savingsTotalMinor, 580000);
      expect(homeVm.netPositionMinor, 1000000);

      // Identity: usable + nonUsable == netPosition
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );

      // Ratios
      expect(homeVm.usableRatio, closeTo(0.42, 0.001));
      expect(homeVm.nonUsableRatio, closeTo(0.58, 0.001));
      expect(homeVm.usableRatio + homeVm.nonUsableRatio, closeTo(1.0, 0.001));
    });

    test('Includes bank, cash, wallet, and everyday named accounts in usable balance', () async {
      await accountRepo.add(
        name: 'ANZ Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 100000, // $1,000.00
        currencyCode: 'AUD',
      );
      await accountRepo.add(
        name: 'Physical Cash',
        type: AccountType.cash,
        openingBalanceMinor: 25000, // $250.00
        currencyCode: 'AUD',
      );
      await accountRepo.add(
        name: 'Digital Wallet',
        type: AccountType.wallet,
        openingBalanceMinor: 15000, // $150.00
        currencyCode: 'AUD',
      );
      await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 60000, // $600.00
        currencyCode: 'AUD',
      );
      await accountRepo.add(
        name: 'Locked Savings',
        type: AccountType.savings,
        openingBalanceMinor: 300000, // $3,000.00
        currencyCode: 'AUD',
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 200000); // 1000 + 250 + 150 + 600 = 2000
      expect(homeVm.savingsTotalMinor, 300000);
      expect(homeVm.nonUsableBalanceMinor, 300000);
      expect(homeVm.netPositionMinor, 500000);
      expect(homeVm.usableRatio, closeTo(0.40, 0.001));
      expect(homeVm.nonUsableRatio, closeTo(0.60, 0.001));
    });

    test('Excludes archived accounts from usable balance and savings total', () async {
      final activeId = await accountRepo.add(
        name: 'Active Checking',
        type: AccountType.bank,
        openingBalanceMinor: 200000,
        currencyCode: 'AUD',
      );
      final archivedLiquidId = await accountRepo.add(
        name: 'Old Checking',
        type: AccountType.bank,
        openingBalanceMinor: 500000,
        currencyCode: 'AUD',
      );
      final archivedSavingsId = await accountRepo.add(
        name: 'Old Savings',
        type: AccountType.savings,
        openingBalanceMinor: 800000,
        currencyCode: 'AUD',
      );

      await accountRepo.setArchived(archivedLiquidId, archived: true);
      await accountRepo.setArchived(archivedSavingsId, archived: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(activeId, isPositive);
      expect(homeVm.usableBalanceMinor, 200000);
      expect(homeVm.savingsTotalMinor, 0);
      expect(homeVm.nonUsableBalanceMinor, 0);
      expect(homeVm.netPositionMinor, 200000);
    });

    test('Edge case: 100% usable funds (no savings or debts)', () async {
      await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 500000, // $5,000.00
        currencyCode: 'AUD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 500000);
      expect(homeVm.nonUsableBalanceMinor, 0);
      expect(homeVm.usableRatio, 1.0);
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test('Edge case: 100% savings funds (no liquid checking/cash)', () async {
      await accountRepo.add(
        name: 'Emergency Fund',
        type: AccountType.savings,
        openingBalanceMinor: 500000, // $5,000.00
        currencyCode: 'AUD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 0);
      expect(homeVm.nonUsableBalanceMinor, 500000);
      expect(homeVm.savingsTotalMinor, 500000);
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 1.0);
    });

    test('Edge case: \$0.00 balances returns 0.0 ratios safely with no divide-by-zero', () async {
      await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 0,
        currencyCode: 'AUD',
      );
      await accountRepo.add(
        name: 'Savings',
        type: AccountType.savings,
        openingBalanceMinor: 0,
        currencyCode: 'AUD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 0);
      expect(homeVm.nonUsableBalanceMinor, 0);
      expect(homeVm.netPositionMinor, 0);
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test('Edge case: Negative net position (overdraft/debts) clamps ratios defensively to 0.0', () async {
      await accountRepo.add(
        name: 'Overdrawn Checking',
        type: AccountType.bank,
        openingBalanceMinor: -20000, // -$200.00
        currencyCode: 'AUD',
      );
      await debtRepo.add(
        personName: 'Credit Union',
        type: DebtType.borrowed,
        amountMinor: 80000, // -$800.00
        currencyCode: 'AUD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, -20000);
      expect(homeVm.netPositionMinor, -100000); // -$1,000.00
      expect(homeVm.nonUsableBalanceMinor, -80000);
      // Both ratios defensively clamp to 0.0 when total <= 0
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test('Multi-currency conversion normalizes to base currency in partition', () async {
      // Base currency defaults to USD. Add quote: 1 EUR = 1.2 USD
      await ratesRepo.add(baseCode: 'EUR', quoteCode: 'USD', rate: 1.2);

      await accountRepo.add(
        name: 'Euro Wallet',
        type: AccountType.wallet,
        openingBalanceMinor: 10000, // 100 EUR -> 120 USD (12000 minor)
        currencyCode: 'EUR',
      );
      await accountRepo.add(
        name: 'US Savings',
        type: AccountType.savings,
        openingBalanceMinor: 12000, // 120 USD (12000 minor)
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(homeVm.usableBalanceMinor, 12000); // 10000 * 1.2 = 12000 USD
      expect(homeVm.savingsTotalMinor, 12000);
      expect(homeVm.nonUsableBalanceMinor, 12000);
      expect(homeVm.netPositionMinor, 24000);
      expect(homeVm.usableRatio, closeTo(0.5, 0.001));
      expect(homeVm.nonUsableRatio, closeTo(0.5, 0.001));
    });
  });

  group('HomeScreen HeroCard Data Visualization Widget Tests', () {
    Widget buildTestApp({
      required GoRouter router,
    }) {
      return MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
      );
    }

    testWidgets('Renders segmented proportion bar and dual breakdown pills with correct data', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 420000, // $4,200.00 (42%)
          currencyCode: 'AUD',
        );
        await accountRepo.add(
          name: 'High Interest Savings',
          type: AccountType.savings,
          openingBalanceMinor: 580000, // $5,800.00 (58%)
          currencyCode: 'AUD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) => const Scaffold(body: Text('AccountsScreen')),
          ),
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) => const Scaffold(body: Text('PlanScreen')),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 1. Verify Net Position headline rendered
      expect(find.text(r'$10,000.00'), findsOneWidget);

      // 2. Verify Spendable and Reserved labels rendered
      expect(find.text('Spendable'), findsOneWidget);
      expect(find.text('Reserved'), findsOneWidget);

      // 3. Verify formatted balance amounts
      expect(find.text(r'$4,200.00'), findsWidgets);
      expect(find.text(r'$5,800.00'), findsWidgets);

      // 4. Verify percentage shares
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('58%'), findsOneWidget);

      // 5. Verify Flat Segmented Balance Proportion Bar exists with 6.0px height
      final proportionBarContainers = tester.widgetList<Container>(find.byType(Container)).where((c) {
        return c.constraints?.maxHeight == 6.0 ||
            (c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).borderRadius == BorderRadius.circular(AppRadius.md));
      }).toList();
      expect(proportionBarContainers.isNotEmpty, isTrue);

      // 6. Verify ColoredBoxes for spendable and reserved segments
      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      final reservedBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF64748B),
      );
      expect(spendableBoxes, findsOneWidget);
      expect(reservedBoxes, findsOneWidget);
    });

    testWidgets('Tapping Spendable pill navigates to accounts route', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 200000,
          currencyCode: 'AUD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 300000,
          currencyCode: 'AUD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) => const Scaffold(body: Text('AccountsScreenTarget')),
          ),
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) => const Scaffold(body: Text('PlanScreenTarget')),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Find and tap Spendable pill
      final spendablePill = find.text('Spendable');
      expect(spendablePill, findsOneWidget);
      await tester.tap(spendablePill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AccountsScreenTarget'), findsOneWidget);
    });

    testWidgets('Tapping Reserved pill navigates to plan route', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 200000,
          currencyCode: 'AUD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 300000,
          currencyCode: 'AUD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) => const Scaffold(body: Text('AccountsScreenTarget')),
          ),
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) => const Scaffold(body: Text('PlanScreenTarget')),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Find and tap Reserved pill
      final reservedPill = find.text('Reserved');
      expect(reservedPill, findsOneWidget);
      await tester.tap(reservedPill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PlanScreenTarget'), findsOneWidget);
    });

    testWidgets('Narrow 320px viewport renders without any RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 125000000, // Large $1,250,000.00
          currencyCode: 'AUD',
        );
        await accountRepo.add(
          name: 'High Interest Savings',
          type: AccountType.savings,
          openingBalanceMinor: 87500000, // $875,000.00
          currencyCode: 'AUD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.text('Spendable'), findsOneWidget);
      expect(find.text('Reserved'), findsOneWidget);
    });

    testWidgets('Defensive fallback for zero balance renders neutral bar with no divide-by-zero', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 0,
          currencyCode: 'AUD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 0,
          currencyCode: 'AUD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.text(r'$0.00'), findsWidgets);
      expect(find.text('0%'), findsNWidgets(2)); // Both pills display 0%
    });
  });
}
