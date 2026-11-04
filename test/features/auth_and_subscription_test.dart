import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/auth/data/model/user_profile.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

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
  Future<String?> read({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async {
    return _data[key];
  }

  @override
  Future<void> delete({required String key, dynamic iOptions, dynamic aOptions, dynamic lOptions, dynamic mOptions, dynamic wOptions, dynamic webOptions}) async {
    _data.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockStorage storage;
  late AuthService authService;
  late SubscriptionService subService;

  setUp(() {
    storage = MockStorage();
    authService = AuthService(storage: storage);
    subService = SubscriptionService(authService: authService, storage: storage);
  });

  tearDown(() {
    authService.dispose();
    subService.dispose();
  });

  test('Guest login creates offline profile and initial free tier', () async {
    expect(authService.isGuest, isTrue);
    final user = await authService.signInAsGuest();
    expect(user.provider, equals(AuthProvider.guest));
    expect(user.isPro, isFalse);
    expect(authService.isAuthenticated, isTrue);
    expect(authService.isGuest, isTrue);
    expect(subService.isPro, isFalse);
  });

  test('Signing in with Google upgrades guest to authenticated permanent user', () async {
    await authService.signInAsGuest();
    expect(authService.isGuest, isTrue);

    final user = await authService.signInWithGoogle(email: 'user@hyprwise.com', displayName: 'Hyprwise User');
    expect(user!.provider, equals(AuthProvider.google));
    expect(authService.isGuest, isFalse);
    expect(authService.isAuthenticated, isTrue);
  });

  test('Subscribing to Pro plan activates Pro across SubscriptionService and AuthService', () async {
    await authService.signInAsGuest();
    expect(subService.isPro, isFalse);

    final plan = SubscriptionService.availablePlans[1]; // Annual plan
    final success = await subService.subscribe(plan);

    expect(success, isTrue);
    expect(subService.isPro, isTrue);
    expect(authService.currentUser?.isPro, isTrue);
    expect(subService.proExpiryDate, isNotNull);
  });

  test('Signing out clears currentUser and resets session in storage', () async {
    await authService.signInWithGoogle(email: 'dev@hyprwise.com', displayName: 'Hyprwise Dev');
    expect(authService.isAuthenticated, isTrue);
    expect(authService.currentUser?.email, equals('dev@hyprwise.com'));

    await authService.signOut();
    expect(authService.isAuthenticated, isFalse);
    expect(authService.currentUser, isNull);
  });

  test('Logging out and logging back in with the same Google account preserves canonical userId', () async {
    final firstLogin = await authService.signInWithGoogle(
      email: 'Canonical.User@Hyprwise.com',
      displayName: 'Canonical User',
    );
    final firstId = firstLogin!.id;
    expect(firstId, isNotEmpty);

    await authService.signOut();
    expect(authService.currentUser, isNull);

    final secondLogin = await authService.signInWithGoogle(
      email: 'canonical.user@hyprwise.com',
      displayName: 'Canonical User',
    );
    expect(secondLogin!.id, equals(firstId));
  });

  test('Returning user is detected on repeated login and retains onboarded state', () async {
    // 1. Initial sign in for user
    final user = await authService.signInWithGoogle(
      email: 'returning.user@hyprwise.com',
      displayName: 'Returning User',
    );
    expect(authService.isAuthenticated, isTrue);

    // 2. Complete onboarding & persist preferences
    await authService.markUserOnboarded(
      userId: user!.id,
      locale: 'ne',
      baseCurrency: 'AUD',
    );
    expect(authService.isReturningUser, isTrue);

    // 3. Log out
    await authService.signOut();
    expect(authService.isAuthenticated, isFalse);
    expect(authService.currentUser, isNull);

    // 4. Log back in with the same account -> immediately recognized as returning user
    final loginAgain = await authService.signInWithGoogle(
      email: 'returning.user@hyprwise.com',
      displayName: 'Returning User',
    );
    expect(loginAgain!.id, equals(user.id));
    expect(authService.isReturningUser, isTrue);

    final storedOnboarded = await storage.read(key: 'auth_user_onboarded_${user.id}');
    final storedCurrency = await storage.read(key: 'auth_user_currency_${user.id}');
    final storedLocale = await storage.read(key: 'auth_user_locale_${user.id}');
    expect(storedOnboarded, equals('true'));
    expect(storedCurrency, equals('AUD'));
    expect(storedLocale, equals('ne'));
  });

  test('Free users synchronize basic currency and language preferences to storage & backend', () async {
    final user = await authService.signInWithGoogle(
      email: 'free.sync@hyprwise.com',
      displayName: 'Free User',
    );
    expect(user!.isPro, isFalse);

    await authService.syncUserPreferences(
      locale: 'ja',
      baseCurrency: 'JPY',
    );

    final storedLocale = await storage.read(key: 'auth_user_locale_${user.id}');
    final storedCurrency = await storage.read(key: 'auth_user_currency_${user.id}');
    expect(storedLocale, equals('ja'));
    expect(storedCurrency, equals('JPY'));
  });

  test('RevenueCat dual-key configuration exposes Test Store key for debug', () {
    expect(SubscriptionService.testStoreKey, equals('test_gyjflYZzhqICSKhjUzpGpbmhnJu'));
    expect(SubscriptionService.playStoreKey, equals('goog_NyRCDaFXJiNwSTgzzDRRGkLKtyy'));
    expect(SubscriptionService.apiKey, isNotEmpty);
  });

  test('Supporter status updates notifiers and persists everSupported badge', () async {
    expect(subService.isSupporter, isFalse);
    expect(subService.everSupported, isFalse);
    expect(subService.isSupporterNotifier.value, isFalse);
    expect(subService.everSupportedNotifier.value, isFalse);

    // Simulate saved supporter in storage
    await storage.write(key: 'subscription_ever_supported', value: 'true');
    await subService.load();

    expect(subService.everSupported, isTrue);
    expect(subService.everSupportedNotifier.value, isTrue);

    await subService.resetOnLogout();
    expect(subService.everSupported, isFalse);
    expect(subService.everSupportedNotifier.value, isFalse);
  });

  test('Aborting Google or Apple sign in returns null without authentication bypass or Pro badge', () async {
    final result = await authService.signInWithGoogle();
    expect(result, isNull);
    expect(authService.isAuthenticated, isFalse);
    expect(authService.currentUser, isNull);
    expect(subService.isPro, isFalse);
    expect(subService.isSupporter, isFalse);
    expect(subService.everSupported, isFalse);

    final appleResult = await authService.signInWithApple();
    expect(appleResult, isNull);
    expect(authService.isAuthenticated, isFalse);
    expect(authService.currentUser, isNull);
    expect(subService.isPro, isFalse);
    expect(subService.isSupporter, isFalse);
    expect(subService.everSupported, isFalse);
  });

  test('New account does not auto-onboard and leaves isReturningUser false', () async {
    final uniqueEmail = 'brandnew_${DateTime.now().microsecondsSinceEpoch}@hyprwise.com';
    final newUser = await authService.signInWithGoogle(
      email: uniqueEmail,
      displayName: 'Brand New User',
    );
    expect(newUser, isNotNull);
    expect(authService.isReturningUser, isFalse);
    expect(authService.hasRestoredCloudData, isFalse);
  });

  test('AuthService.formatDisplayNameFromEmail creates human-friendly username', () {
    expect(
      AuthService.formatDisplayNameFromEmail('saugat.kandel@icloud.com'),
      equals('Saugat Kandel'),
    );
    expect(
      AuthService.formatDisplayNameFromEmail('john_doe@privaterelay.appleid.com'),
      equals('John Doe'),
    );
    expect(
      AuthService.formatDisplayNameFromEmail('alice-smith@domain.com'),
      equals('Alice Smith'),
    );
    expect(
      AuthService.formatDisplayNameFromEmail('developer@hyprwise.com'),
      equals('Developer'),
    );
  });

  test('AuthService.extractNameFromProfile handles nested, flat, and string profile formats', () {
    expect(
      AuthService.extractNameFromProfile({'name': 'Saugat Kandel'}),
      equals('Saugat Kandel'),
    );
    expect(
      AuthService.extractNameFromProfile({
        'name': {'firstName': 'Saugat', 'lastName': 'Kandel'},
      }),
      equals('Saugat Kandel'),
    );
    expect(
      AuthService.extractNameFromProfile({
        'firstName': 'Jane',
        'lastName': 'Doe',
      }),
      equals('Jane Doe'),
    );
    expect(
      AuthService.extractNameFromProfile(null),
      isNull,
    );
  });

  test('Signing in with Apple derives username from email and never defaults to Apple Account', () async {
    final appleUser = await authService.signInWithApple(
      email: 'saugat.kandel@icloud.com',
    );
    expect(appleUser, isNotNull);
    expect(appleUser!.provider, equals(AuthProvider.apple));
    expect(appleUser.email, equals('saugat.kandel@icloud.com'));
    expect(appleUser.displayName, equals('Saugat Kandel'));
    expect(appleUser.displayName, isNot(equals('Apple User')));
    expect(appleUser.displayName, isNot(equals('Apple Account')));

    // Signing in again without explicit name retains the cached username
    final returningAppleUser = await authService.signInWithApple(
      email: 'saugat.kandel@icloud.com',
    );
    expect(returningAppleUser, isNotNull);
    expect(returningAppleUser!.displayName, equals('Saugat Kandel'));
  });
}
