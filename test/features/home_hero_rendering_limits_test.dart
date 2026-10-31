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

  Widget buildTestApp({
    required GoRouter router,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      locale: locale,
    );
  }

  group('Milestone 1 Adversarial: Viewport Stress & Extreme Amounts', () {
    testWidgets('300px viewport stress with \$999,999,999.99 USD', (tester) async {
      tester.view.physicalSize = const Size(300, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Checking',
          type: AccountType.bank,
          openingBalanceMinor: 49999999999,
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 50000000000,
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

      final err = tester.takeException();
      if (err != null) {
        // ignore: avoid_print
        print('RENDERFLEX ERROR ON 300px USD:\n$err');
      }
      expect(err, isNull, reason: 'RenderFlex overflow occurred on 300px USD');
      expect(find.text('Spendable'), findsOneWidget);
      expect(find.text('Reserved'), findsOneWidget);
    });

    testWidgets('320px viewport stress with \$999,999,999.99 USD', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Checking',
          type: AccountType.bank,
          openingBalanceMinor: 49999999999,
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 50000000000,
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

      final err = tester.takeException();
      if (err != null) {
        // ignore: avoid_print
        print('RENDERFLEX ERROR ON 320px USD:\n$err');
      }
      expect(err, isNull, reason: 'RenderFlex overflow occurred on 320px USD');
      expect(find.text('Spendable'), findsOneWidget);
      expect(find.text('Reserved'), findsOneWidget);
    });

    testWidgets('300px viewport stress with massive NPR (रु ९९,९९,९९,९९९.९९)', (tester) async {
      tester.view.physicalSize = const Size(300, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await settingsRepo.setBaseCurrency('NPR');
        await settingsRepo.setLocaleCode('ne');

        await accountRepo.add(
          name: 'ग्लोबल बैंक',
          type: AccountType.bank,
          openingBalanceMinor: 49999999999,
          currencyCode: 'NPR',
        );
        await accountRepo.add(
          name: 'मुद्दती बचत',
          type: AccountType.savings,
          openingBalanceMinor: 50000000000,
          currencyCode: 'NPR',
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

      await tester.pumpWidget(buildTestApp(
        router: router,
        locale: const Locale('ne'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final err = tester.takeException();
      if (err != null) {
        if (err is FlutterError) {
          for (final d in err.diagnostics) {
            // ignore: avoid_print
            print('DIAGNOSTIC: ${d.name} -> ${d.toDescription()}');
          }
        }
      }
      expect(err, isNull, reason: 'RenderFlex overflow occurred on 300px NPR');
      expect(find.text('खर्चयोग्य'), findsOneWidget);
      expect(find.text('सुरक्षित/बचत'), findsOneWidget);
    });

    testWidgets('320px viewport stress with massive NPR (रु ९९,९९,९९,९९९.९९)', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await settingsRepo.setBaseCurrency('NPR');
        await settingsRepo.setLocaleCode('ne');

        await accountRepo.add(
          name: 'ग्लोबल बैंक',
          type: AccountType.bank,
          openingBalanceMinor: 49999999999,
          currencyCode: 'NPR',
        );
        await accountRepo.add(
          name: 'मुद्दती बचत',
          type: AccountType.savings,
          openingBalanceMinor: 50000000000,
          currencyCode: 'NPR',
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

      await tester.pumpWidget(buildTestApp(
        router: router,
        locale: const Locale('ne'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final err = tester.takeException();
      if (err != null) {
        // ignore: avoid_print
        print('RENDERFLEX ERROR ON 320px NPR:\n$err');
      }
      expect(err, isNull, reason: 'RenderFlex overflow occurred on 320px NPR');
      expect(find.text('खर्चयोग्य'), findsOneWidget);
      expect(find.text('सुरक्षित/बचत'), findsOneWidget);
    });
  });

  group('Milestone 1 Adversarial: Layout Stability & Edge States', () {
    testWidgets('Zero-balance empty state without accounts renders clean setup hero', (tester) async {
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
      expect(find.text(r'$0.00'), findsOneWidget);
      expect(find.text('Add an account and this fills in.'), findsOneWidget);

      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      expect(spendableBoxes, findsNothing);
    });

    testWidgets('Zero-balance state with 0-balance accounts renders neutral bar & 0% pills', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday',
          type: AccountType.bank,
          openingBalanceMinor: 0,
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 0,
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
      expect(find.text(r'$0.00'), findsWidgets);
      expect(find.text('0%'), findsNWidgets(2));

      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      expect(spendableBoxes, findsNothing);
    });

    testWidgets('Negative net position collapses proportion bar safely without negative flex', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Overdrawn Checking',
          type: AccountType.bank,
          openingBalanceMinor: -250000,
          currencyCode: 'USD',
        );
        await debtRepo.add(
          personName: 'Loan Shark',
          type: DebtType.borrowed,
          amountMinor: 750000,
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
      expect(find.text(r'−$10,000.00'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(2));

      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      final reservedBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF64748B),
      );
      expect(spendableBoxes, findsNothing);
      expect(reservedBoxes, findsNothing);
    });

    testWidgets('Mixed polarity (positive cash, negative net position) collapses bar safely', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Cash',
          type: AccountType.cash,
          openingBalanceMinor: 200000,
          currencyCode: 'USD',
        );
        await debtRepo.add(
          personName: 'Bank Loan',
          type: DebtType.borrowed,
          amountMinor: 800000,
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
      expect(find.text(r'−$6,000.00'), findsOneWidget);
      expect(find.text('Spendable'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(2));

      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      expect(spendableBoxes, findsNothing);
    });

    testWidgets('100% usable balance displays 100% on spendable segment', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Everyday Bank',
          type: AccountType.bank,
          openingBalanceMinor: 500000,
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
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      final reservedBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF64748B),
      );
      expect(spendableBoxes, findsOneWidget);
      expect(reservedBoxes, findsNothing);
    });

    testWidgets('100% non-usable (savings) displays 100% on reserved segment', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Term Deposit',
          type: AccountType.savings,
          openingBalanceMinor: 800000,
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
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      final spendableBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF22C55E),
      );
      final reservedBoxes = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF64748B),
      );
      expect(spendableBoxes, findsNothing);
      expect(reservedBoxes, findsOneWidget);
    });
  });

  group('Milestone 1 Adversarial: Tap Target Integrity & Hit Testing', () {
    testWidgets('Spendable pill tap target navigates to accounts', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Checking',
          type: AccountType.bank,
          openingBalanceMinor: 100000,
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 200000,
          currencyCode: 'USD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      String currentRoute = AppRoutes.home;
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) {
              currentRoute = AppRoutes.accounts;
              return const Scaffold(body: Text('AccountsRouteConfirmed'));
            },
          ),
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) {
              currentRoute = AppRoutes.plan;
              return const Scaffold(body: Text('PlanRouteConfirmed'));
            },
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final spendablePill = find.ancestor(
        of: find.text('Spendable'),
        matching: find.byType(InkWell),
      );
      expect(spendablePill, findsOneWidget);

      await tester.tap(spendablePill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentRoute, equals(AppRoutes.accounts));
      expect(find.text('AccountsRouteConfirmed'), findsOneWidget);
    });

    testWidgets('Reserved pill tap target navigates to plan', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Checking',
          type: AccountType.bank,
          openingBalanceMinor: 100000,
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 200000,
          currencyCode: 'USD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      String currentRoute = AppRoutes.home;
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) {
              currentRoute = AppRoutes.accounts;
              return const Scaffold(body: Text('AccountsRouteConfirmed'));
            },
          ),
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) {
              currentRoute = AppRoutes.plan;
              return const Scaffold(body: Text('PlanRouteConfirmed'));
            },
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final reservedPill = find.ancestor(
        of: find.text('Reserved'),
        matching: find.byType(InkWell),
      );
      expect(reservedPill, findsOneWidget);

      await tester.tap(reservedPill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentRoute, equals(AppRoutes.plan));
      expect(find.text('PlanRouteConfirmed'), findsOneWidget);
    });

    testWidgets('Tapping between pills in the 8px gap does not misroute', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.add(
          name: 'Checking',
          type: AccountType.bank,
          openingBalanceMinor: 100000,
          currencyCode: 'USD',
        );
        await accountRepo.add(
          name: 'Savings',
          type: AccountType.savings,
          openingBalanceMinor: 200000,
          currencyCode: 'USD',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      String currentRoute = AppRoutes.home;
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) {
              currentRoute = AppRoutes.accounts;
              return const Scaffold(body: Text('AccountsRouteConfirmed'));
            },
          ),
          GoRoute(
            path: AppRoutes.plan,
            builder: (context, state) {
              currentRoute = AppRoutes.plan;
              return const Scaffold(body: Text('PlanRouteConfirmed'));
            },
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final spendableRect = tester.getRect(find.ancestor(
        of: find.text('Spendable'),
        matching: find.byType(InkWell),
      ));
      final reservedRect = tester.getRect(find.ancestor(
        of: find.text('Reserved'),
        matching: find.byType(InkWell),
      ));

      final gapPoint = Offset(
        (spendableRect.right + reservedRect.left) / 2,
        spendableRect.center.dy,
      );

      await tester.tapAt(gapPoint);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentRoute, equals(AppRoutes.home));
      expect(tester.takeException(), isNull);
    });
  });
}
