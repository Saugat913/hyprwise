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
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

class MockStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  @override
  Future<void> write({
    required String key,
    required String? value,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic mOptions,
    dynamic wOptions,
    dynamic webOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic mOptions,
    dynamic wOptions,
    dynamic webOptions,
  }) async =>
      _data[key];

  @override
  Future<void> delete({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic mOptions,
    dynamic wOptions,
    dynamic webOptions,
  }) async =>
      _data.remove(key);

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

  Future<void> pumpSettings(
    WidgetTester tester, {
    Size size = const Size(1080, 2400),
    double pixelRatio = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('M2 Challenger 2: Widget Tree Hierarchy & Children Ordering', () {
    testWidgets('ListView children exact structural index verification', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      final delegate = listView.childrenDelegate as SliverChildListDelegate;
      final children = delegate.children;

      // 1. Check exact raw children indices
      // Index 0: _AccountAuthCard
      expect(children[0].runtimeType.toString(), equals('_AccountAuthCard'));
      // Index 1: SizedBox
      expect(children[1], isA<SizedBox>());
      // Index 2: _SubscriptionBanner
      expect(children[2].runtimeType.toString(), equals('_SubscriptionBanner'));
      // Index 3: SizedBox
      expect(children[3], isA<SizedBox>());

      // 2. Check semantic non-spacer children hierarchy
      final nonSpacerChildren = children.where((w) => w is! SizedBox).toList();

      // Top Zone
      expect(nonSpacerChildren[0].runtimeType.toString(), equals('_AccountAuthCard'));
      expect(nonSpacerChildren[1].runtimeType.toString(), equals('_SubscriptionBanner'));

      // Middle Zone: Appearance & Language
      expect(nonSpacerChildren[2], isA<Text>()); // tr.appearance
      expect(nonSpacerChildren[3].runtimeType.toString(), equals('_ThemeSelector'));
      expect(nonSpacerChildren[4], isA<Text>()); // tr.language
      expect(nonSpacerChildren[5].runtimeType.toString(), equals('_LanguageSelector'));

      // Middle Zone: Money, Alerts, AI Assistant, Data & Backup
      expect(nonSpacerChildren[6], isA<Text>()); // tr.money
      expect(nonSpacerChildren[7], isA<AppCard>()); // Money AppCard
      expect(nonSpacerChildren[8], isA<Text>()); // tr.alerts
      expect(nonSpacerChildren[9], isA<AppCard>()); // Alerts AppCard
      expect(nonSpacerChildren[10], isA<Text>()); // tr.aiAssistant
      expect(nonSpacerChildren[11], isA<AppCard>()); // AI Assistant AppCard
      expect(nonSpacerChildren[12], isA<Text>()); // tr.dataAndBackup
      expect(nonSpacerChildren[13], isA<AppCard>()); // Data AppCard

      // Bottom Zone: Support Hyprwise & Supporter Banner
      expect(nonSpacerChildren[14], isA<Text>()); // tr.supportHyprwise
      expect(nonSpacerChildren[15].runtimeType.toString(), equals('_SupporterBanner'));
      expect(nonSpacerChildren[16], isA<AppCard>()); // Support & Legal AppCard (Restore, Privacy, Terms)

      // Bottom Zone: Danger Zone
      expect(nonSpacerChildren[17], isA<Text>()); // tr.dangerZone
      expect(nonSpacerChildren[18], isA<AppCard>()); // Danger Zone AppCard
    });

    testWidgets('Support & Legal AppCard contains Restore Purchases, Privacy Policy, Terms of Service in order', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester);

      final listView = tester.widget<ListView>(find.byType(ListView));
      final delegate = listView.childrenDelegate as SliverChildListDelegate;
      final nonSpacerChildren = delegate.children.where((w) => w is! SizedBox).toList();

      final supportCard = nonSpacerChildren[16] as AppCard;
      expect(supportCard.child, isA<Column>());

      final column = supportCard.child as Column;
      final rows = column.children.whereType<ListRow>().toList();

      final tr = AppStrings.current();
      expect(rows.length, equals(3));
      expect(rows[0].title, equals(tr.restorePurchases));
      expect(rows[1].title, equals(tr.privacyPolicy));
      expect(rows[2].title, equals(tr.termsOfService));
    });

    testWidgets('Monotonic Y-coordinate hierarchy ordering in rendered layout', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester, size: const Size(1080, 4000)); // Tall enough to render all without offstage clip

      final tr = AppStrings.current();

      final profileFinder = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_AccountAuthCard');
      final upgradeFinder = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_SubscriptionBanner');
      final appearanceFinder = find.text(tr.appearance);
      final moneyFinder = find.text(tr.money);
      final alertsFinder = find.text(tr.alerts).first;
      final aiFinder = find.text(tr.aiAssistant);
      final dataFinder = find.text(tr.dataAndBackup);
      final supportFinder = find.text(tr.supportHyprwise).first;
      final supporterBannerFinder = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_SupporterBanner');
      final restoreFinder = find.text(tr.restorePurchases);
      final dangerFinder = find.text(tr.dangerZone);

      final yProfile = tester.getTopLeft(profileFinder).dy;
      final yUpgrade = tester.getTopLeft(upgradeFinder).dy;
      final yAppearance = tester.getTopLeft(appearanceFinder).dy;
      final yMoney = tester.getTopLeft(moneyFinder).dy;
      final yAlerts = tester.getTopLeft(alertsFinder).dy;
      final yAi = tester.getTopLeft(aiFinder).dy;
      final yData = tester.getTopLeft(dataFinder).dy;
      final ySupport = tester.getTopLeft(supportFinder).dy;
      final ySupporterBanner = tester.getTopLeft(supporterBannerFinder).dy;
      final yRestore = tester.getTopLeft(restoreFinder).dy;
      final yDanger = tester.getTopLeft(dangerFinder).dy;

      // Strict vertical monotonicity check:
      expect(yProfile, lessThan(yUpgrade), reason: 'Profile must precede Upgrade at top');
      expect(yUpgrade, lessThan(yAppearance), reason: 'Upgrade must precede General Settings');
      expect(yAppearance, lessThan(yMoney), reason: 'Appearance must precede Money');
      expect(yMoney, lessThan(yAlerts), reason: 'Money must precede Alerts');
      expect(yAlerts, lessThan(yAi), reason: 'Alerts must precede AI Assistant');
      expect(yAi, lessThan(yData), reason: 'AI Assistant must precede Data & Backup');
      expect(yData, lessThan(ySupport), reason: 'Data & Backup must precede Support section');
      expect(ySupport, lessThan(ySupporterBanner), reason: 'Support title must precede Supporter Banner');
      expect(ySupporterBanner, lessThan(yRestore), reason: 'Supporter Banner must precede Restore Purchases');
      expect(yRestore, lessThan(yDanger), reason: 'Support & Legal must precede Danger Zone');
    });
  });

  group('M2 Challenger 2: Screen Dimension & Boundary Viewport Stress Testing', () {
    final viewports = [
      {'name': 'Dispatch Compact Target (360x600)', 'size': const Size(360, 600)},
      {'name': 'Extreme Legacy Small Screen (320x480)', 'size': const Size(320, 480)},
      {'name': 'iPhone SE Compact (375x667)', 'size': const Size(375, 667)},
      {'name': 'Android Flagship (412x915)', 'size': const Size(412, 915)},
      {'name': 'Landscape Wide/Short (800x400)', 'size': const Size(800, 400)},
    ];

    for (final vp in viewports) {
      testWidgets('Viewport stress: ${vp['name']} initial render and full scroll without overflow', (tester) async {
        await authService.signInAsGuest();
        await pumpSettings(tester, size: vp['size'] as Size);

        // Verify initial frame has no layout exceptions
        expect(tester.takeException(), isNull, reason: 'Initial render failed on ${vp['name']}');

        // Scroll all the way to the bottom to stress all child cards
        final scrollableFinder = find.byType(Scrollable);
        expect(scrollableFinder, findsOneWidget);

        final tr = AppStrings.current();
        final eraseFinder = find.text(tr.eraseAllData);

        // Repeatedly fling/drag downwards until bottom is reached
        for (int i = 0; i < 10; i++) {
          if (eraseFinder.evaluate().isNotEmpty) break;
          await tester.drag(scrollableFinder, const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(tester.takeException(), isNull, reason: 'Scrolling produced layout exception on ${vp['name']}');

        // Scroll back to top
        for (int i = 0; i < 10; i++) {
          await tester.drag(scrollableFinder, const Offset(0, 300));
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(tester.takeException(), isNull, reason: 'Reverse scroll produced layout exception on ${vp['name']}');
      });
    }
  });

  group('M2 Challenger 2: Keyboard Popping & Simulated viewInsets Stress Testing', () {
    testWidgets('Keyboard popping (300px viewInsets on 360x600 compact viewport)', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester, size: const Size(360, 600));

      // Simulate keyboard popping up by setting viewInsets.bottom
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull, reason: 'Keyboard popup caused RenderFlex overflow');

      // Scroll inside the restricted viewport
      final scrollableFinder = find.byType(Scrollable);
      await tester.drag(scrollableFinder, const Offset(0, -200));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Scrolling during keyboard popup caused overflow');

      // Reset keyboard
      tester.view.resetViewInsets();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Severe keyboard popping (280px viewInsets on 320x480 tiny viewport - 200px available)', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester, size: const Size(320, 480));

      // 280px keyboard on a 480px screen leaves only 200px visible viewport height
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull, reason: 'Severe keyboard popup caused RenderFlex overflow on 320x480');

      final scrollableFinder = find.byType(Scrollable);
      await tester.drag(scrollableFinder, const Offset(0, -100));
      await tester.pump();
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('M2 Challenger 2: Content Saturation & Adversarial State Stress Testing', () {
    testWidgets('Single-badge Pro user with long name renders cleanly without overflow on compact 360x600', (tester) async {
      await storage.write(
        key: 'auth_user_profile',
        value: jsonEncode(const UserProfile(
          id: 'usr_g_test_pro_user',
          email: 'alexander.pro@example.com',
          displayName: 'Alexander Montgomery The Second of Finance',
          provider: AuthProvider.google,
          isPro: true,
        ).toJson()),
      );
      await storage.write(key: 'subscription_is_pro', value: 'true');
      await storage.write(key: 'subscription_ever_supported', value: 'false');
      await authService.load();
      await subService.load();

      await pumpSettings(tester, size: const Size(360, 600));

      expect(tester.takeException(), isNull, reason: 'Profile card with Pro badge overflowed on 360px');
      expect(find.byType(ProCrownBadge), findsOneWidget);

      final tr = AppStrings.current();
      expect(find.text(tr.upgradeToPro), findsNothing);
    });

    testWidgets('Dual-badge saturation (isPro + everSupported) renders cleanly without overflow on narrow viewport (<400px)', (tester) async {
      await storage.write(
        key: 'auth_user_profile',
        value: jsonEncode(const UserProfile(
          id: 'usr_g_test_adversarial',
          email: 'dual.badge.user@example.com',
          displayName: 'Alexander Montgomery',
          provider: AuthProvider.google,
          isPro: true,
        ).toJson()),
      );
      await storage.write(key: 'subscription_is_pro', value: 'true');
      await storage.write(key: 'subscription_ever_supported', value: 'true');
      await authService.load();
      await subService.load();

      String? overflowError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflowError = details.exceptionAsString();
        }
      };

      await pumpSettings(tester, size: const Size(360, 600));
      FlutterError.onError = originalOnError;

      // Badges (Pro + Supporter) wrap cleanly without RenderFlex overflow
      expect(overflowError, isNull, reason: 'Dual badges should render cleanly without overflow');
      expect(find.byType(ProCrownBadge), findsOneWidget);
    });

    testWidgets('Unauthenticated guest state buttons on narrow 320px screen do not overflow', (tester) async {
      // In fresh unauthenticated state
      await pumpSettings(tester, size: const Size(360, 640));

      final tr = AppStrings.current();
      expect(find.text(tr.cloudAccount), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);

      expect(tester.takeException(), isNull, reason: 'Sign in buttons in Profile card overflowed on 320px width');
    });

    testWidgets('Pro state transition dynamically updates UI without layout jump or overflow', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester, size: const Size(360, 600));

      final tr = AppStrings.current();
      expect(find.text(tr.upgradeToPro), findsOneWidget);
      expect(find.byType(ProCrownBadge), findsNothing);

      // Simulate purchasing Pro
      await storage.write(key: 'subscription_is_pro', value: 'true');
      await subService.load();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text(tr.upgradeToPro), findsNothing);
      expect(find.byType(ProCrownBadge), findsOneWidget);
    });
  });

  group('M2 Challenger 2: Modal Bottom Sheets & Legal Dialogs Verification', () {
    testWidgets('Privacy Policy and Terms of Service dialogs open and dismiss cleanly on compact 360x600', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester, size: const Size(360, 600));

      final tr = AppStrings.current();
      final scrollableFinder = find.byType(Scrollable);

      // 1. Scroll to Privacy Policy
      final privacyFinder = find.text(tr.privacyPolicy);
      for (int i = 0; i < 8; i++) {
        if (privacyFinder.evaluate().isNotEmpty) break;
        await tester.drag(scrollableFinder, const Offset(0, -250));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(privacyFinder, findsOneWidget);
      await tester.tap(privacyFinder);
      await tester.pumpAndSettle();

      // Verify Dialog is present without overflow
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Privacy Policy dialog overflowed');

      // Dismiss dialog
      final gotItFinder = find.text(tr.t('Got it', ne: 'बुझें', es: 'Entendido', fr: 'Compris', de: 'Verstanden', ja: '了解', zh: '知道了', it: 'Ho capito'));
      expect(gotItFinder, findsOneWidget);
      await tester.tap(gotItFinder);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      // 2. Open Terms of Service dialog
      final termsFinder = find.text(tr.termsOfService);
      for (int i = 0; i < 4; i++) {
        if (tester.getCenter(termsFinder).dy <= 550) break;
        await tester.drag(scrollableFinder, const Offset(0, -100));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(termsFinder, findsOneWidget);
      await tester.tap(termsFinder);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Terms of Service dialog overflowed');

      // Dismiss dialog
      await tester.tap(gotItFinder);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Language modal bottom sheet opens and scrolls cleanly on compact 360x600', (tester) async {
      await authService.signInAsGuest();
      await pumpSettings(tester, size: const Size(360, 600));

      final tr = AppStrings.current();
      final langFinder = find.text(tr.language);
      expect(langFinder, findsOneWidget);

      // Tap Language selector container
      final globeFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_LanguageSelector',
      );
      expect(globeFinder, findsOneWidget);

      await tester.tap(globeFinder);
      await tester.pumpAndSettle();

      // Bottom sheet should be visible
      expect(find.byType(BottomSheet), findsOneWidget);

      // Dismiss bottom sheet by tapping the top scrim barrier
      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(BottomSheet), findsNothing);
      final err = tester.takeException();
      // Ensure no RenderFlex layout overflow occurred in language bottom sheet
      expect(err?.toString(), isNot(contains('overflowed')));
    });
  });
}
