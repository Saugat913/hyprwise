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

  group('Adversarial Stress Testing: Extreme Edge Cases in Usable vs Non-Usable Partition', () {
    test(r'Scenario 1: Net position -$50,000 with positive everyday cash (+$5,000)', () async {
      // User has $5,000 everyday cash in bank, but owes $55,000 in borrowed debts.
      await accountRepo.add(
        name: 'Everyday Checking',
        type: AccountType.bank,
        openingBalanceMinor: 500000, // +$5,000.00
        currencyCode: 'USD',
      );
      await debtRepo.add(
        personName: 'Home Loan / Lender',
        type: DebtType.borrowed,
        amountMinor: 5500000, // -$55,000.00
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 500000);
      expect(homeVm.netDebtMinor, -5500000);
      expect(homeVm.netPositionMinor, -5000000); // -$50,000.00
      expect(homeVm.nonUsableBalanceMinor, -5500000);

      // Invariant check: usable + nonUsable == netPosition
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );

      // Ratio checks: when netPosition <= 0, both ratios must safely be 0.0 without NaN/Infinity
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);
      expect(homeVm.usableRatio.isFinite, isTrue);
      expect(homeVm.nonUsableRatio.isFinite, isTrue);
      expect(homeVm.usableRatio.isNaN, isFalse);
      expect(homeVm.nonUsableRatio.isNaN, isFalse);
    });

    test(r'Scenario 2: Usable cash negative (overdrawn -$200) while savings is positive (+$1,000)', () async {
      await accountRepo.add(
        name: 'Overdrawn Bank Account',
        type: AccountType.bank,
        openingBalanceMinor: -20000, // -$200.00
        currencyCode: 'USD',
      );
      await accountRepo.add(
        name: 'Term Deposit Savings',
        type: AccountType.savings,
        openingBalanceMinor: 100000, // +$1,000.00
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, -20000);
      expect(homeVm.savingsTotalMinor, 100000);
      expect(homeVm.netPositionMinor, 80000); // +$800.00
      // nonUsable = netPosition - usable = 80,000 - (-20,000) = 100,000
      expect(homeVm.nonUsableBalanceMinor, 100000);

      // Invariant check
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );

      // Usable balance is negative, so usableRatio must be clamped defensively to 0.0
      expect(homeVm.usableRatio, 0.0);
      // Non-usable ratio: 100,000 / 80,000 = 1.25 -> clamped to 1.0
      expect(homeVm.nonUsableRatio, 1.0);
      expect(homeVm.usableRatio.isFinite, isTrue);
      expect(homeVm.nonUsableRatio.isFinite, isTrue);
    });

    test(r'Scenario 3: Overdrawn bank (-$1,500) and savings (+$1,000) with net negative position (-$500)', () async {
      await accountRepo.add(
        name: 'Heavy Overdraft',
        type: AccountType.bank,
        openingBalanceMinor: -150000, // -$1,500.00
        currencyCode: 'USD',
      );
      await accountRepo.add(
        name: 'Savings',
        type: AccountType.savings,
        openingBalanceMinor: 100000, // +$1,000.00
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, -150000);
      expect(homeVm.netPositionMinor, -50000); // -$500.00
      expect(homeVm.nonUsableBalanceMinor, 100000); // -50,000 - (-150,000) = 100,000

      // Invariant check
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );

      // Since netPosition <= 0, both ratios must clamp to 0.0
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test(r'Scenario 4: Positive usable cash (+$1,000) with borrowed debt (-$400), net position +$600', () async {
      await accountRepo.add(
        name: 'Cash Everyday',
        type: AccountType.cash,
        openingBalanceMinor: 100000, // +$1,000.00
        currencyCode: 'USD',
      );
      await debtRepo.add(
        personName: 'Bob',
        type: DebtType.borrowed,
        amountMinor: 40000, // -$400.00
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 100000);
      expect(homeVm.netPositionMinor, 60000); // +$600.00
      expect(homeVm.nonUsableBalanceMinor, -40000); // 60,000 - 100,000 = -40,000

      // Invariant check
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );

      // usableRatio: 100,000 / 60,000 = 1.666... -> clamped to 1.0
      expect(homeVm.usableRatio, 1.0);
      // nonUsableBalanceMinor <= 0 -> nonUsableRatio returns 0.0
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test(r'Scenario 5: Both usable and non-usable are negative', () async {
      await accountRepo.add(
        name: 'Overdraft',
        type: AccountType.bank,
        openingBalanceMinor: -20000, // -$200.00
        currencyCode: 'USD',
      );
      await debtRepo.add(
        personName: 'Lender',
        type: DebtType.borrowed,
        amountMinor: 80000, // -$800.00
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, -20000);
      expect(homeVm.nonUsableBalanceMinor, -80000);
      expect(homeVm.netPositionMinor, -100000); // -$1,000.00

      // Invariant check
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );

      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test(r'Scenario 6: Exactly zero net position variants', () async {
      // 6a: Bank +$500, Borrowed -$500 => Net = 0
      final acc1 = await accountRepo.add(
        name: 'Checking',
        type: AccountType.bank,
        openingBalanceMinor: 50000,
        currencyCode: 'USD',
      );
      await debtRepo.add(
        personName: 'Friend',
        type: DebtType.borrowed,
        amountMinor: 50000,
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.netPositionMinor, 0);
      expect(homeVm.usableBalanceMinor, 50000);
      expect(homeVm.nonUsableBalanceMinor, -50000);
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);

      // Clean up for 6b: Bank -$500, Savings +$500 => Net = 0
      await accountRepo.setArchived(acc1, archived: true);
      await accountRepo.add(
        name: 'Overdrawn',
        type: AccountType.bank,
        openingBalanceMinor: -50000,
        currencyCode: 'USD',
      );
      await accountRepo.add(
        name: 'Savings Piggy',
        type: AccountType.savings,
        openingBalanceMinor: 100000, // 100000 - 50000 debt = +50000 net non-usable, total net = 0
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.netPositionMinor, 0);
      expect(homeVm.usableBalanceMinor, -50000);
      expect(homeVm.nonUsableBalanceMinor, 50000);
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test(r'Scenario 7: Mixed currencies across 12 accounts with exchange rates', () async {
      // Base currency is USD
      // Exchange rates: 1 unit of foreign currency to USD
      await ratesRepo.add(baseCode: 'AUD', quoteCode: 'USD', rate: 0.65);
      await ratesRepo.add(baseCode: 'EUR', quoteCode: 'USD', rate: 1.10);
      await ratesRepo.add(baseCode: 'GBP', quoteCode: 'USD', rate: 1.30);
      await ratesRepo.add(baseCode: 'JPY', quoteCode: 'USD', rate: 0.0067);
      await ratesRepo.add(baseCode: 'NPR', quoteCode: 'USD', rate: 0.0075);
      await ratesRepo.add(baseCode: 'CAD', quoteCode: 'USD', rate: 0.74);
      await ratesRepo.add(baseCode: 'CHF', quoteCode: 'USD', rate: 1.15);
      await ratesRepo.add(baseCode: 'SGD', quoteCode: 'USD', rate: 0.75);
      await ratesRepo.add(baseCode: 'NZD', quoteCode: 'USD', rate: 0.60);
      await ratesRepo.add(baseCode: 'INR', quoteCode: 'USD', rate: 0.012);

      // Liquid accounts (usable):
      // 1. AUD Everyday: 100,000 minor ($1,000.00 AUD) * 0.65 = 65,000 minor USD
      await accountRepo.add(name: 'AUD Everyday', type: AccountType.bank, openingBalanceMinor: 100000, currencyCode: 'AUD');
      // 2. JPY Wallet: 10,000,000 minor (100,000 JPY) * 0.0067 = 67,000 minor USD
      await accountRepo.add(name: 'JPY Wallet', type: AccountType.wallet, openingBalanceMinor: 10000000, currencyCode: 'JPY');
      // 3. NPR Everyday: 5,000,000 minor (50,000 NPR) * 0.0075 = 37,500 minor USD
      await accountRepo.add(name: 'NPR Everyday', type: AccountType.bank, openingBalanceMinor: 5000000, currencyCode: 'NPR');
      // 4. EUR Checking: 50,000 minor (500 EUR) * 1.10 = 55,000 minor USD
      await accountRepo.add(name: 'EUR Checking', type: AccountType.bank, openingBalanceMinor: 50000, currencyCode: 'EUR');
      // 5. SGD Cash: 20,000 minor (200 SGD) * 0.75 = 15,000 minor USD
      await accountRepo.add(name: 'SGD Cash', type: AccountType.cash, openingBalanceMinor: 20000, currencyCode: 'SGD');
      // 6. CAD Wallet: 30,000 minor (300 CAD) * 0.74 = 22,200 minor USD
      await accountRepo.add(name: 'CAD Wallet', type: AccountType.wallet, openingBalanceMinor: 30000, currencyCode: 'CAD');

      // Non-liquid accounts (savings / reserved):
      // 7. USD Savings: 500,000 minor ($5,000.00 USD) = 500,000 minor USD
      await accountRepo.add(name: 'USD Savings', type: AccountType.savings, openingBalanceMinor: 500000, currencyCode: 'USD');
      // 8. GBP Fixed Savings: 200,000 minor (2,000 GBP) * 1.30 = 260,000 minor USD
      await accountRepo.add(name: 'GBP Savings', type: AccountType.savings, openingBalanceMinor: 200000, currencyCode: 'GBP');
      // 9. CHF Vault: 100,000 minor (1,000 CHF) * 1.15 = 115,000 minor USD
      await accountRepo.add(name: 'CHF Vault', type: AccountType.savings, openingBalanceMinor: 100000, currencyCode: 'CHF');
      // 10. NZD Term Deposit: 150,000 minor (1,500 NZD) * 0.60 = 90,000 minor USD
      await accountRepo.add(name: 'NZD Term Deposit', type: AccountType.savings, openingBalanceMinor: 150000, currencyCode: 'NZD');
      // 11. INR Family Reserve: 10,000,000 minor (100,000 INR) * 0.012 = 120,000 minor USD
      await accountRepo.add(name: 'INR Family Reserve', type: AccountType.savings, openingBalanceMinor: 10000000, currencyCode: 'INR');
      // 12. USD Emergency Fund: 250,000 minor ($2,500.00 USD) = 250,000 minor USD
      await accountRepo.add(name: 'USD Emergency Fund', type: AccountType.savings, openingBalanceMinor: 250000, currencyCode: 'USD');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Sum of usable: 65,000 + 67,000 + 37,500 + 55,000 + 15,000 + 22,200 = 261,700 minor USD
      // Sum of non-usable: 500,000 + 260,000 + 115,000 + 90,000 + 120,000 + 250,000 = 1,335,000 minor USD
      // Total net position: 261,700 + 1,335,000 = 1,596,700 minor USD
      expect(homeVm.usableBalanceMinor, 261700);
      expect(homeVm.savingsTotalMinor, 1335000);
      expect(homeVm.nonUsableBalanceMinor, 1335000);
      expect(homeVm.netPositionMinor, 1596700);

      // INVARIANT: usable + nonUsable == netPosition
      expect(
        homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor,
        equals(homeVm.netPositionMinor),
      );

      // Ratios
      final expectedUsableRatio = 261700 / 1596700; // ~0.1639
      final expectedNonUsableRatio = 1335000 / 1596700; // ~0.8361
      expect(homeVm.usableRatio, closeTo(expectedUsableRatio, 0.0001));
      expect(homeVm.nonUsableRatio, closeTo(expectedNonUsableRatio, 0.0001));
      expect(homeVm.usableRatio + homeVm.nonUsableRatio, closeTo(1.0, 0.00001));
      expect(homeVm.usableRatio.isFinite, isTrue);
      expect(homeVm.nonUsableRatio.isFinite, isTrue);
    });

    test(r'Scenario 8: Dynamic archiving and unarchiving lifecycle', () async {
      final liquid1 = await accountRepo.add(
        name: 'Checking A',
        type: AccountType.bank,
        openingBalanceMinor: 100000,
        currencyCode: 'USD',
      );
      final liquid2 = await accountRepo.add(
        name: 'Checking B',
        type: AccountType.wallet,
        openingBalanceMinor: 100000,
        currencyCode: 'USD',
      );
      final savings1 = await accountRepo.add(
        name: 'Savings A',
        type: AccountType.savings,
        openingBalanceMinor: 200000,
        currencyCode: 'USD',
      );
      final savings2 = await accountRepo.add(
        name: 'Savings B',
        type: AccountType.savings,
        openingBalanceMinor: 200000,
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableBalanceMinor, 200000);
      expect(homeVm.nonUsableBalanceMinor, 400000);
      expect(homeVm.netPositionMinor, 600000);
      expect(homeVm.usableRatio, closeTo(200000 / 600000, 0.001));

      // Step A: Archive liquid1
      await accountRepo.setArchived(liquid1, archived: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(homeVm.usableBalanceMinor, 100000);
      expect(homeVm.nonUsableBalanceMinor, 400000);
      expect(homeVm.netPositionMinor, 500000);
      expect(homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor, equals(homeVm.netPositionMinor));

      // Step B: Archive savings1
      await accountRepo.setArchived(savings1, archived: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(homeVm.usableBalanceMinor, 100000);
      expect(homeVm.nonUsableBalanceMinor, 200000);
      expect(homeVm.netPositionMinor, 300000);
      expect(homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor, equals(homeVm.netPositionMinor));

      // Step C: Archive remaining liquid2
      await accountRepo.setArchived(liquid2, archived: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(homeVm.usableBalanceMinor, 0);
      expect(homeVm.nonUsableBalanceMinor, 200000);
      expect(homeVm.netPositionMinor, 200000);
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 1.0);
      expect(homeVm.usableBalanceMinor + homeVm.nonUsableBalanceMinor, equals(homeVm.netPositionMinor));

      // Step D: Archive remaining savings2 (All accounts archived)
      await accountRepo.setArchived(savings2, archived: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(homeVm.usableBalanceMinor, 0);
      expect(homeVm.nonUsableBalanceMinor, 0);
      expect(homeVm.netPositionMinor, 0);
      expect(homeVm.usableRatio, 0.0);
      expect(homeVm.nonUsableRatio, 0.0);

      // Step E: Unarchive liquid1
      await accountRepo.setArchived(liquid1, archived: false);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(homeVm.usableBalanceMinor, 100000);
      expect(homeVm.nonUsableBalanceMinor, 0);
      expect(homeVm.netPositionMinor, 100000);
      expect(homeVm.usableRatio, 1.0);
      expect(homeVm.nonUsableRatio, 0.0);
    });

    test(r'Scenario 9: Fuzz and boundary testing for NaN, Infinity, and divide-by-zero immunity', () async {
      // Test extreme boundary values in mathematical ratio properties
      // 1. Extreme large positive net position: $10,000,000,000.00
      await accountRepo.add(
        name: 'Mega Bank',
        type: AccountType.bank,
        openingBalanceMinor: 1000000000000, // 1 trillion minor units
        currencyCode: 'USD',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(homeVm.usableRatio, 1.0);
      expect(homeVm.nonUsableRatio, 0.0);
      expect(homeVm.usableRatio.isFinite, isTrue);
      expect(homeVm.nonUsableRatio.isFinite, isTrue);
      expect(homeVm.usableRatio.isNaN, isFalse);
      expect(homeVm.nonUsableRatio.isNaN, isFalse);
    });
  });

  group('Adversarial Widget Stress Tests on HomeScreen HeroCard', () {
    Widget buildTestApp({required GoRouter router}) {
      return MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
      );
    }

    testWidgets(r'Widget Stress: Renders safely when Net Position is -$50,000 with +$5,000 everyday cash', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 500000, // +$5,000.00
          currencyCode: 'USD',
        );
        await debtRepo.add(
          personName: 'Lender Mortgage',
          type: DebtType.borrowed,
          amountMinor: 5500000, // -$55,000.00
          currencyCode: 'USD',
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

      // Zero exceptions thrown
      expect(tester.takeException(), isNull);

      // Verify formatted Net Position shows −$50,000.00 (using MoneyFormatter unicode minus)
      expect(find.text('−\$50,000.00'), findsOneWidget);

      // Verify Spendable Pill shows +$5,000.00 and 0%
      expect(find.text(r'$5,000.00'), findsWidgets);
      expect(find.text('0%'), findsNWidgets(2)); // Both pills 0%

      // Verify Reserved Pill shows −$55,000.00
      expect(find.text('−\$55,000.00'), findsOneWidget);

      // Verify proportion bar renders neutral track (no ColoredBox children when net position <= 0)
      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      final reservedBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF64748B),
      );
      expect(spendableBoxes, findsNothing);
      expect(reservedBoxes, findsNothing);
    });

    testWidgets(r'Widget Stress: Renders safely with Overdrawn Bank (-$200) and Savings (+$1,000)', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Overdrawn Bank',
          type: AccountType.bank,
          openingBalanceMinor: -20000, // -$200.00
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 100000, // +$1,000.00
          currencyCode: 'USD',
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

      // Net position +$800.00
      expect(find.text(r'$800.00'), findsOneWidget);

      // Spendable shows −$200.00 (0%)
      expect(find.text('−\$200.00'), findsWidgets);
      expect(find.text('0%'), findsOneWidget);

      // Reserved shows $1,000.00 (100%)
      expect(find.text(r'$1,000.00'), findsWidgets);
      expect(find.text('100%'), findsOneWidget);

      // Proportion bar: spendable flex is 0, reserved flex is 1000
      // Therefore only reserved ColoredBox should exist
      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      final reservedBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF64748B),
      );
      expect(spendableBoxes, findsNothing);
      expect(reservedBoxes, findsOneWidget);
    });

    testWidgets(r'Widget Stress: Ultra-compact 300px viewport with 10-digit extreme balances causes no RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Checking',
          type: AccountType.bank,
          openingBalanceMinor: 99999999999, // $999,999,999.99
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 88888888888, // $888,888,888.88
          currencyCode: 'USD',
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
  });
}
