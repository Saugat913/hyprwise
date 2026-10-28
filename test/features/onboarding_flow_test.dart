import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/onboarding/view/currency_first_run_screen.dart';
import 'package:finance_tracker/features/onboarding/view/welcome_screen.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SettingsRepository settingsRepo;
  late AccountRepository accountRepo;
  late AuthService authService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settingsRepo = SettingsRepository(db);
    await settingsRepo.load();
    accountRepo = AccountRepository(db);
    authService = AuthService();

    if (getIt.isRegistered<SettingsRepository>()) {
      getIt.unregister<SettingsRepository>();
    }
    if (getIt.isRegistered<AccountRepository>()) {
      getIt.unregister<AccountRepository>();
    }
    if (getIt.isRegistered<AuthService>()) {
      getIt.unregister<AuthService>();
    }

    getIt.registerSingleton<SettingsRepository>(settingsRepo);
    getIt.registerSingleton<AccountRepository>(accountRepo);
    getIt.registerSingleton<AuthService>(authService);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('WelcomeScreen renders clean pitch without top-right language switcher', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify clean WelcomeScreen without language toggle (language is asked after login)
    expect(find.text('English'), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Onboarding Wizard renders Language step first then advances to Currency step', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/currency',
      routes: [
        GoRoute(
          path: '/currency',
          builder: (context, state) => const CurrencyFirstRunScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Screen')),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: Language selection is presented
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('नेपाली'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Select Nepali
    await tester.tap(find.text('नेपाली'));
    await tester.pumpAndSettle();

    expect(settingsRepo.settings.localeCode, 'ne');
    expect(find.text('अगाडि बढ्नुहोस्'), findsOneWidget);

    // Tap Continue
    await tester.tap(find.text('अगाडि बढ्नुहोस्'));
    await tester.pumpAndSettle();

    // Step 2: Currency selection is presented
    expect(find.text('तपाईं कुन मुद्रा\nप्रयोग गर्नुहुन्छ?'), findsOneWidget);
    expect(find.text('सेटअप पूरा गर्नुहोस्'), findsOneWidget);

    // Select AUD
    await tester.tap(find.text('A\$ · Australian dollar'));
    await tester.pumpAndSettle();

    // Complete setup
    await tester.tap(find.text('सेटअप पूरा गर्नुहोस्'));
    await tester.pumpAndSettle();

    expect(settingsRepo.settings.onboarded, isTrue);
    expect(settingsRepo.settings.baseCurrency, 'AUD');
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
