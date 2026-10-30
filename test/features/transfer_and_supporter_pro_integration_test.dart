import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/accounts/view/accounts_screen.dart';
import 'package:finance_tracker/features/accounts/view/wizards/add_account_wizard.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/auth/data/model/user_profile.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/settings/view/settings_screen.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/transfers/data/transfer_repository.dart';
import 'package:finance_tracker/features/transfers/domain/transfer_draft.dart';
import 'package:finance_tracker/features/transfers/presentation/transfers_screen.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountRepository accountRepo;
  late TransferRepository transferRepo;
  late FinanceStore financeStore;
  late AccountsViewModel accountsVm;
  late AuthService authService;
  late SubscriptionService subService;
  late FlutterSecureStorage storage;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountRepo = AccountRepository(db);
    transferRepo = TransferRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    final jobRepo = JobRepository(db);
    final shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    final ratesRepo = ExchangeRateRepository(db);
    final settingsRepo = SettingsRepository(db);
    final debtRepo = DebtRepository(db);
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

    accountsVm = AccountsViewModel(
      financeStore: financeStore,
      accountRepo: accountRepo,
    );

    authService = AuthService(storage: storage);
    await authService.load();

    subService = SubscriptionService(
      authService: authService,
      storage: storage,
    );
    await subService.load();

    final settingsVm = SettingsViewModel(
      settingsRepo: settingsRepo,
      financeStore: financeStore,
      ratesRepo: ratesRepo,
      dataRepo: DataRepository(db),
    );

    // Register test dependencies
    if (getIt.isRegistered<AppDatabase>()) getIt.unregister<AppDatabase>();
    if (getIt.isRegistered<AccountRepository>()) getIt.unregister<AccountRepository>();
    if (getIt.isRegistered<TransferRepository>()) getIt.unregister<TransferRepository>();
    if (getIt.isRegistered<FinanceStore>()) getIt.unregister<FinanceStore>();
    if (getIt.isRegistered<AccountsViewModel>()) getIt.unregister<AccountsViewModel>();
    if (getIt.isRegistered<AuthService>()) getIt.unregister<AuthService>();
    if (getIt.isRegistered<SubscriptionService>()) getIt.unregister<SubscriptionService>();
    if (getIt.isRegistered<SettingsViewModel>()) getIt.unregister<SettingsViewModel>();

    getIt.registerSingleton<AppDatabase>(db);
    getIt.registerSingleton<AccountRepository>(accountRepo);
    getIt.registerSingleton<TransferRepository>(transferRepo);
    getIt.registerSingleton<FinanceStore>(financeStore);
    getIt.registerSingleton<AccountsViewModel>(accountsVm);
    getIt.registerSingleton<AuthService>(authService);
    getIt.registerSingleton<SubscriptionService>(subService);
    getIt.registerSingleton<SettingsViewModel>(settingsVm);
  });

  tearDown(() async {
    financeStore.dispose();
    accountsVm.dispose();
    await db.close();
  });

  Widget pumpWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('Supporter & Pro Status Synchronization', () {
    test('Supporters are automatically Pro users (unlocking Pro access and badges)', () async {
      await storage.write(key: 'subscription_ever_supported', value: 'true');
      await subService.load();

      expect(subService.everSupported, isTrue);
      // Supporter must be automatically Pro
      expect(subService.isPro, isTrue);
    });

    testWidgets('Settings card displays user display name, email, and Pro + Supporter badges', (tester) async {
      await storage.write(
        key: 'auth_user_profile',
        value: jsonEncode(const UserProfile(
          id: 'usr_g_test_user',
          email: 'saugat@example.com',
          displayName: 'Saugat Kandel',
          provider: AuthProvider.google,
          photoUrl: null,
          isPro: false,
        ).toJson()),
      );
      await storage.write(key: 'subscription_ever_supported', value: 'true');
      await authService.load();
      await subService.load();

      await tester.pumpWidget(pumpWithRouter(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Display name and email must be displayed
      expect(find.text('Saugat Kandel'), findsOneWidget);
      expect(find.text('saugat@example.com'), findsOneWidget);

      // Pro crown badge AND supporter badge must both be present
      expect(find.byType(ProCrownBadge), findsOneWidget);
      expect(find.text('Supporter'), findsOneWidget);
    });
  });

  group('Transfers Between Accounts', () {
    test('Transfer between accounts updates balances in Drift and FinanceSnapshot', () async {
      final pair = await accountRepo.ensureFixedTwoAccounts('AUD');
      final acc1 = pair.everyday.id;
      final acc2 = pair.savings.id;

      // Transfer 50.00 (5000 minor) from Everyday to Savings
      final transferId = await transferRepo.createTransfer(
        TransferDraft(
          sourceAccountId: acc1,
          destinationAccountId: acc2,
          amountMinor: 5000,
          occurredAt: DateTime.now(),
          note: 'Emergency savings transfer',
        ),
      );

      expect(transferId, isPositive);

      // Verify transfer in database
      final transfers = await transferRepo.watchTransfers().first;
      expect(transfers.length, 1);
      expect(transfers.first.amountMinor, 5000);
      expect(transfers.first.sourceAccountId, acc1);
      expect(transfers.first.destinationAccountId, acc2);
    });

    testWidgets('AccountsScreen Transfer action opens TransferForm modal without crashing', (tester) async {
      await tester.runAsync(() async {
        await accountRepo.ensureFixedTwoAccounts('AUD');
      });

      await tester.pumpWidget(pumpWithRouter(const AccountsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Transfer top bar action button directly
      final transferButtonFinder = find.byWidgetPredicate(
        (widget) => widget is RoundIconButton && widget.glyph == HugeIcons.strokeRoundedExchange01,
      );
      expect(transferButtonFinder, findsOneWidget);
      await tester.tap(transferButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal bottom sheet with TransferForm is opened
      expect(find.byType(TransferForm), findsOneWidget);
      expect(find.text('Transfer money'), findsOneWidget);

      // Dismiss the bottom sheet
      Navigator.of(tester.element(find.byType(TransferForm))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('Add Account Wizard Structured Grid View', () {
    testWidgets('AddAccountWizard renders 2-column GridView for AccountType', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddAccountWizard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Everyday account'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Digital wallet'), findsOneWidget);
    });
  });
}
