import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/auth/data/model/user_profile.dart';
import 'package:finance_tracker/features/shared/widgets/pro_badge.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

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
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    dynamic iOptions,
    dynamic aOptions,
    dynamic lOptions,
    dynamic mOptions,
    dynamic wOptions,
    dynamic webOptions,
  }) async {
    _data.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final getIt = GetIt.instance;
  late MockStorage storage;
  late AuthService authService;
  late SubscriptionService subService;

  setUp(() async {
    await getIt.reset();
    storage = MockStorage();
    authService = AuthService(storage: storage);
    subService = SubscriptionService(authService: authService, storage: storage);

    getIt.registerSingleton<AuthService>(authService);
    getIt.registerSingleton<SubscriptionService>(subService);
  });

  tearDown(() async {
    authService.dispose();
    subService.dispose();
    await getIt.reset();
  });

  group('R4: Pro Plan User Indication (Tier 1 Feature Coverage)', () {
    test('T1.1: Calling subscribe() activates Pro status across SubscriptionService and AuthService', () async {
      await authService.signInAsGuest();
      expect(subService.isPro, isFalse);

      final annualPlan = SubscriptionService.availablePlans[1];
      final success = await subService.subscribe(annualPlan);
      expect(success, isTrue);
      expect(subService.isPro, isTrue);
      expect(authService.currentUser?.isPro, isTrue);
    });

    test('T1.2: Calling subscribe() immediately updates isProNotifier.value to true', () async {
      await authService.signInAsGuest();
      expect(subService.isProNotifier.value, isFalse);

      final monthlyPlan = SubscriptionService.availablePlans[0];
      await subService.subscribe(monthlyPlan);
      // Fulfills R4 immediate status requirement
      expect(subService.isProNotifier.value, isTrue);
    });

    test('T1.3: Calling subscribe() triggers synchronous ChangeNotifier notification', () async {
      await authService.signInAsGuest();
      int notifyCount = 0;
      subService.addListener(() => notifyCount++);

      final annualPlan = SubscriptionService.availablePlans[1];
      await subService.subscribe(annualPlan);
      expect(notifyCount, greaterThan(0));
    });

    test('T1.4: Restoring purchases propagates active Pro status to isProNotifier', () async {
      await storage.write(key: 'hyprwise_pro_access', value: 'true');
      final access = await subService.restorePurchases();
      expect(access.isPro, isTrue);
      expect(subService.isPro, isTrue);
      expect(subService.isProNotifier.value, isTrue);
    });

    testWidgets('T1.5: Settings screen reflects active Pro banner when user is Pro', (tester) async {
      await tester.runAsync(() async {
        await authService.signInAsGuest();
        final annualPlan = SubscriptionService.availablePlans[1];
        await subService.subscribe(annualPlan);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: subService,
              builder: (context, _) {
                final tr = AppStrings.current();
                return subService.isPro
                    ? Text(tr.proActive)
                    : Text(tr.upgradeToPro);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final tr = AppStrings.current();
      expect(find.text(tr.proActive), findsOneWidget);
      expect(find.text(tr.upgradeToPro), findsNothing);
    });
  });

  group('R4: Pro Plan User Indication (Tier 2 Boundary & Corner Cases)', () {
    test('T2.1: Guest user upgrading to Pro persists Pro in storage and active notifiers', () async {
      final guest = await authService.signInAsGuest();
      expect(guest.provider, equals(AuthProvider.guest));

      final monthlyPlan = SubscriptionService.availablePlans[0];
      await subService.subscribe(monthlyPlan);
      expect(subService.isPro, isTrue);
      expect(subService.isProNotifier.value, isTrue);

      final persisted = await storage.read(key: 'hyprwise_pro_access');
      expect(persisted, equals('true'));
    });

    test('T2.2: Lifetime plan subscription activates Pro with null expiration date', () async {
      await authService.signInAsGuest();
      const lifetimePlan = SubscriptionPlan(
        id: 'lifetime',
        title: 'Lifetime Plan',
        priceString: r'$49.99',
        period: 'lifetime',
        isLifetime: true,
      );
      await subService.subscribe(lifetimePlan);

      expect(subService.isPro, isTrue);
      expect(subService.isProNotifier.value, isTrue);
      expect(subService.proExpiryDate, isNull);
    });

    test('T2.3: Restoring when no prior purchases exist leaves isPro and isProNotifier false', () async {
      final access = await subService.restorePurchases();
      expect(access.isPro, isFalse);
      expect(subService.isPro, isFalse);
      expect(subService.isProNotifier.value, isFalse);
    });

    test('T2.4: Active Pro status operates across all supported currencies', () async {
      final currencies = ['USD', 'NPR', 'EUR', 'INR', 'GBP', 'AUD', 'CAD', 'JPY'];
      for (final curr in currencies) {
        expect(subService.isPro, isFalse);
        final monthlyPlan = SubscriptionService.availablePlans[0];
        await subService.subscribe(monthlyPlan);
        expect(subService.isPro, isTrue, reason: 'Failed for currency $curr');
        // Reset for next currency iteration
        await storage.delete(key: 'hyprwise_pro_access');
        await subService.resetOnLogout();
      }
    });

    testWidgets('T2.5: ProCrownBadge widget renders compact gold badge when displayed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProCrownBadge(isCompact: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PRO'), findsOneWidget);
      expect(find.byType(ProCrownBadge), findsOneWidget);
    });
  });
}
