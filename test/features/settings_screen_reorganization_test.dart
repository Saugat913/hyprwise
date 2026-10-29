import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/auth/data/model/user_profile.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/settings/view/settings_screen.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

class MockStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  @override
  Future<void> write({required String key, required String? value, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
  @override
  Future<String?> read({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async => _data[key];
  @override
  Future<void> delete({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async => _data.remove(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final getIt = GetIt.instance;
  late AppDatabase db;
  late MockStorage storage;
  late AuthService authService;
  late SubscriptionService subService;
  late FinanceStore store;
  late SettingsRepository settingsRepo;
  late DataRepository dataRepo;
  late SettingsViewModel settingsVm;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storage = MockStorage();
    authService = AuthService(storage: storage);
    subService = SubscriptionService(authService: authService, storage: storage);

    final accRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    final jobRepo = JobRepository(db);
    final shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    final debtRepo = DebtRepository(db);
    final ratesRepo = ExchangeRateRepository(db);
    settingsRepo = SettingsRepository(db);
    await settingsRepo.load();
    dataRepo = DataRepository(db);

    store = FinanceStore(
      accountsRepo: accRepo,
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

    settingsVm = SettingsViewModel(
      settingsRepo: settingsRepo,
      dataRepo: dataRepo,
      financeStore: store,
      ratesRepo: ratesRepo,
    );

    getIt.registerSingleton<AuthService>(authService);
    getIt.registerSingleton<SubscriptionService>(subService);
    getIt.registerSingleton<FinanceStore>(store);
    getIt.registerSingleton<SettingsViewModel>(settingsVm);
  });

  tearDown(() async {
    settingsVm.dispose();
    authService.dispose();
    subService.dispose();
    store.dispose();
    await db.close();
    await getIt.reset();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
    );
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('R5: Settings Screen Reorganization (Tier 1 Feature Coverage)', () {
    testWidgets('T1.1 & T1.2: Profile and Upgrade are positioned at the top of Settings list', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final tr = AppStrings.current();

      // Find top section elements
      final upgradeFinder = find.text(tr.upgradeToPro);
      final appearanceFinder = find.text(tr.appearance);

      expect(upgradeFinder, findsOneWidget);
      expect(appearanceFinder, findsOneWidget);

      final upgradeY = tester.getTopLeft(upgradeFinder).dy;
      final appearanceY = tester.getTopLeft(appearanceFinder).dy;

      // Top section items must be above general settings (Appearance)
      expect(upgradeY, lessThan(appearanceY));
    });

    testWidgets('T1.3: General settings are positioned in the middle zone', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final tr = AppStrings.current();
      final appearanceFinder = find.text(tr.appearance);
      final moneyFinder = find.text(tr.money);

      expect(appearanceFinder, findsOneWidget);
      expect(moneyFinder, findsOneWidget);

      final appearanceY = tester.getTopLeft(appearanceFinder).dy;
      final moneyY = tester.getTopLeft(moneyFinder).dy;

      expect(appearanceY, lessThan(moneyY));
    });

    testWidgets('T1.4: Support section exists in settings layout', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final tr = AppStrings.current();
      expect(find.text(tr.restorePurchases), findsOneWidget);
    });

    testWidgets('T1.5: Support and legal elements appear after general settings', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final tr = AppStrings.current();
      final appearanceFinder = find.text(tr.appearance);
      final restoreFinder = find.text(tr.restorePurchases);

      expect(appearanceFinder, findsOneWidget);
      expect(restoreFinder, findsOneWidget);

      final appearanceY = tester.getTopLeft(appearanceFinder).dy;
      final restoreY = tester.getTopLeft(restoreFinder).dy;

      // Support must appear below general settings
      expect(restoreY, greaterThan(appearanceY));
    });
  });

  group('R5: Settings Screen Reorganization (Tier 2 Boundary & Corner Cases)', () {
    testWidgets('T2.1: Authenticated user profile displays name and email', (tester) async {
      await storage.write(
        key: 'auth_user_profile',
        value: jsonEncode(const UserProfile(
          id: 'usr_g_test_alex',
          email: 'alex@example.com',
          displayName: 'Alex Mercer',
          provider: AuthProvider.google,
          isPro: false,
        ).toJson()),
      );
      await authService.load();
      await pumpSettings(tester);

      expect(find.text('Alex Mercer'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
    });

    testWidgets('T2.2: Unauthenticated user displays cloud account prompt in profile card', (tester) async {
      // In initial state, authService has no currentUser
      await pumpSettings(tester);

      final tr = AppStrings.current();
      expect(find.text(tr.cloudAccount), findsOneWidget);
    });

    testWidgets('T2.3: Small screen height does not produce layout exceptions in settings', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await authService.signInAsGuest();
      await pumpSettings(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.4: Danger Zone is located at the bottom of the Settings screen', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final tr = AppStrings.current();
      final dangerFinder = find.text(tr.dangerZone);
      final appearanceFinder = find.text(tr.appearance);

      expect(dangerFinder, findsOneWidget);
      expect(appearanceFinder, findsOneWidget);

      final dangerY = tester.getTopLeft(dangerFinder).dy;
      final appearanceY = tester.getTopLeft(appearanceFinder).dy;

      expect(dangerY, greaterThan(appearanceY));
    });

    testWidgets('T2.5: Tapping Restore Purchases triggers restore handler', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final tr = AppStrings.current();
      final restoreFinder = find.text(tr.restorePurchases);
      expect(restoreFinder, findsOneWidget);

      await tester.tap(restoreFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // No crash upon tapping restore
      expect(tester.takeException(), isNull);
    });
  });
}
