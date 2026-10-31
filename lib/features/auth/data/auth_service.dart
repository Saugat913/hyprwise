import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/network/api_client.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/auth/data/model/user_profile.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AuthService extends ChangeNotifier {
  AuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _isCloudSyncing = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest =>
      _currentUser == null || _currentUser?.provider == AuthProvider.guest;
  bool get isLoading => _isLoading;
  bool get isCloudSyncing => _isCloudSyncing;

  static const _userKey = 'auth_user_profile';
  static const _tokenKey = 'auth_api_token';
  static const _deviceGuestIdKey = 'auth_device_guest_id';

  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  /// Deterministic canonical fallback user ID from normalized email
  /// so the same email address always maps to the same user ID even before server sync.
  static String deterministicUserIdFromEmail(
    String email, {
    String prefix = 'usr_g_',
  }) {
    final norm = email.trim().toLowerCase();
    int h1 = 0x811c9dc5;
    int h2 = 0x01000193;
    for (final code in norm.codeUnits) {
      h1 ^= code;
      h1 = (h1 * 0x01000193) & 0xFFFFFFFF;
      h2 ^= (code * 31) & 0xFF;
      h2 = (h2 * 0x85ebca6b) & 0xFFFFFFFF;
    }
    final hex =
        '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}';
    return '$prefix$hex';
  }

  Future<void> _applyServerSyncResult(Map<String, dynamic>? serverRes) async {
    if (serverRes == null) return;
    final token = serverRes['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: _tokenKey, value: token);
    }
    final serverUser = serverRes['user'] as Map<String, dynamic>?;
    if (serverUser != null) {
      final used = serverUser['dailyAiQueriesUsed'] as int?;
      final left = serverUser['dailyAiQueriesLeft'] as int?;
      if (getIt.isRegistered<AssistantViewModel>() &&
          (used != null || left != null)) {
        getIt<AssistantViewModel>().updateQuotaFromServer(
          used: used ?? (left != null ? (5 - left).clamp(0, 5) : 0),
          left: left,
        );
      }
      final isPro = serverUser['isPro'] as bool? ?? false;
      if (getIt.isRegistered<SubscriptionService>()) {
        await getIt<SubscriptionService>().setServerProStatus(isPro);
      }
    }
  }

  Future<void> load() async {
    try {
      final savedToken = await _storage.read(key: _tokenKey);
      final raw = await _storage.read(key: _userKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _currentUser = UserProfile.fromJson(map);
        ApiClient.instance.setAuthContext(
          token: savedToken,
          userId: _currentUser!.id,
          email: _currentUser!.email,
        );
        TelemetryService.instance.setUserId(_currentUser!.id);
        TelemetryService.instance.setUserProperty(
          name: 'is_pro',
          value: _currentUser!.isPro.toString(),
        );
        TelemetryService.instance.setUserProperty(
          name: 'auth_provider',
          value: _currentUser!.provider.name,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading auth profile: $e');
    }
  }

  Future<UserProfile> signInWithGoogle({
    String? email,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      String userEmail =
          (email ?? 'user.finance@gmail.com').trim().toLowerCase();
      String userId = deterministicUserIdFromEmail(userEmail, prefix: 'usr_g_');
      String userName = displayName ?? 'Google User';
      String? photoUrl;
      String? idToken;

      if (_hasFirebase) {
        try {
          final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
          final GoogleSignInAccount? gUser = await googleSignIn.signIn();
          if (gUser != null) {
            userEmail = gUser.email.trim().toLowerCase();
            userName = gUser.displayName ?? userEmail.split('@')[0];
            photoUrl = gUser.photoUrl;
            userId = deterministicUserIdFromEmail(userEmail, prefix: 'usr_g_');

            final GoogleSignInAuthentication gAuth = await gUser.authentication;
            idToken = gAuth.idToken;

            final credential = GoogleAuthProvider.credential(
              accessToken: gAuth.accessToken,
              idToken: gAuth.idToken,
            );

            final userCredential = await FirebaseAuth.instance
                .signInWithCredential(credential);
            final fbUser = userCredential.user;
            if (fbUser != null) {
              userId = fbUser.uid;
              userEmail = (fbUser.email ?? userEmail).trim().toLowerCase();
              userName = fbUser.displayName ?? userName;
              photoUrl = fbUser.photoURL ?? photoUrl;
              idToken = await fbUser.getIdToken();
            }
          }
        } catch (e) {
          debugPrint('[Auth] Google native sign-in fallback: $e');
        }
      }

      // Synchronize with Hyprwise Cloudflare Server and adopt canonical account identity
      bool isPro = false;
      try {
        final serverRes = await ApiClient.instance.authenticateFirebase(
          uid: userId,
          idToken: idToken,
          email: userEmail,
          displayName: userName,
          photoUrl: photoUrl,
          provider: 'google',
        );
        final serverUser = serverRes?['user'] as Map<String, dynamic>?;
        if (serverUser != null) {
          userId = (serverUser['id'] as String?) ?? userId;
          userEmail = (serverUser['email'] as String?) ?? userEmail;
          userName = (serverUser['displayName'] as String?) ?? userName;
          isPro = serverUser['isPro'] as bool? ?? false;
        }
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(userId: userId, email: userEmail);

      // Link with RevenueCat customer identity using canonical userId
      try {
        final logInResult = await Purchases.logIn(userId);
        if (logInResult.customerInfo.entitlements.active.containsKey('hyprwise_pro')) {
          isPro = true;
        }
      } catch (_) {}

      final user = UserProfile(
        id: userId,
        email: userEmail,
        displayName: userName,
        photoUrl: photoUrl,
        provider: AuthProvider.google,
        isPro: isPro,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      // Pull latest cloud data automatically on login
      await pullCloudDataToLocal();

      // Ensure returning/authenticated user skips first-run onboarding screen
      if (getIt.isRegistered<SettingsRepository>()) {
        await getIt<SettingsRepository>().completeOnboarding();
      }

      // If user is Pro, trigger Pro auto-sync
      triggerProAutoSync();

      if (getIt.isRegistered<AssistantViewModel>()) {
        unawaited(getIt<AssistantViewModel>().syncQuotaFromServer());
      }

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'google');
      TelemetryService.instance.setUserProperty(
        name: 'auth_provider',
        value: 'google',
      );
      TelemetryService.instance.setUserProperty(
        name: 'is_pro',
        value: isPro.toString(),
      );

      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserProfile> signInWithApple({String? email, String? fullName}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String userEmail =
          (email ?? 'user.finance@icloud.com').trim().toLowerCase();
      String userId = deterministicUserIdFromEmail(userEmail, prefix: 'usr_a_');
      String userName = fullName ?? 'Apple User';
      String? idToken;

      if (_hasFirebase) {
        try {
          final appleProvider = AppleAuthProvider();
          final userCredential = await FirebaseAuth.instance.signInWithProvider(
            appleProvider,
          );
          final fbUser = userCredential.user;
          if (fbUser != null) {
            userId = fbUser.uid;
            userEmail = (fbUser.email ?? userEmail).trim().toLowerCase();
            userName = fbUser.displayName ?? userName;
            idToken = await fbUser.getIdToken();
          }
        } catch (e) {
          debugPrint('[Auth] Apple native sign-in fallback: $e');
        }
      }

      // Synchronize with Hyprwise Cloudflare Server and adopt canonical account identity
      bool isPro = false;
      try {
        final serverRes = await ApiClient.instance.authenticateFirebase(
          uid: userId,
          idToken: idToken,
          email: userEmail,
          displayName: userName,
          provider: 'apple',
        );
        final serverUser = serverRes?['user'] as Map<String, dynamic>?;
        if (serverUser != null) {
          userId = (serverUser['id'] as String?) ?? userId;
          userEmail = (serverUser['email'] as String?) ?? userEmail;
          userName = (serverUser['displayName'] as String?) ?? userName;
          isPro = serverUser['isPro'] as bool? ?? false;
        }
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(userId: userId, email: userEmail);

      // Link with RevenueCat
      try {
        final logInResult = await Purchases.logIn(userId);
        if (logInResult.customerInfo.entitlements.active.containsKey('hyprwise_pro')) {
          isPro = true;
        }
      } catch (_) {}

      final user = UserProfile(
        id: userId,
        email: userEmail,
        displayName: userName,
        provider: AuthProvider.apple,
        isPro: isPro,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      // Pull latest cloud data automatically on login
      await pullCloudDataToLocal();

      // Ensure returning/authenticated user skips first-run onboarding screen
      if (getIt.isRegistered<SettingsRepository>()) {
        await getIt<SettingsRepository>().completeOnboarding();
      }

      // If user is Pro, trigger Pro auto-sync
      triggerProAutoSync();

      if (getIt.isRegistered<AssistantViewModel>()) {
        unawaited(getIt<AssistantViewModel>().syncQuotaFromServer());
      }

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'apple');
      TelemetryService.instance.setUserProperty(
        name: 'auth_provider',
        value: 'apple',
      );
      TelemetryService.instance.setUserProperty(
        name: 'is_pro',
        value: isPro.toString(),
      );

      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Links an existing anonymous/guest session with Google credentials and backs up local data to cloud
  Future<UserProfile?> linkGuestWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      String userEmail = 'user.finance@gmail.com';
      String userId = deterministicUserIdFromEmail(userEmail, prefix: 'usr_g_');
      String userName = 'Google User';
      String? photoUrl;
      String? idToken;

      if (_hasFirebase) {
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final GoogleSignInAccount? gUser = await googleSignIn.signIn();
        if (gUser == null) {
          // User aborted Google sign in
          return null;
        }

        userEmail = gUser.email.trim().toLowerCase();
        userName = gUser.displayName ?? userEmail.split('@')[0];
        photoUrl = gUser.photoUrl;
        userId = deterministicUserIdFromEmail(userEmail, prefix: 'usr_g_');

        final GoogleSignInAuthentication gAuth = await gUser.authentication;
        idToken = gAuth.idToken;

        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        final currentFbUser = FirebaseAuth.instance.currentUser;
        UserCredential userCredential;
        if (currentFbUser != null && currentFbUser.isAnonymous) {
          try {
            userCredential = await currentFbUser.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use') {
              userCredential = await FirebaseAuth.instance.signInWithCredential(
                credential,
              );
            } else {
              rethrow;
            }
          }
        } else {
          userCredential = await FirebaseAuth.instance.signInWithCredential(
            credential,
          );
        }

        final fbUser = userCredential.user;
        if (fbUser != null) {
          userId = fbUser.uid;
          userEmail = (fbUser.email ?? userEmail).trim().toLowerCase();
          userName = fbUser.displayName ?? userName;
          photoUrl = fbUser.photoURL ?? photoUrl;
          idToken = await fbUser.getIdToken();
        }
      }

      // Synchronize with Cloudflare Server and adopt canonical account identity
      bool isPro = false;
      try {
        final serverRes = await ApiClient.instance.authenticateFirebase(
          uid: userId,
          idToken: idToken,
          email: userEmail,
          displayName: userName,
          photoUrl: photoUrl,
          provider: 'google',
        );
        final serverUser = serverRes?['user'] as Map<String, dynamic>?;
        if (serverUser != null) {
          userId = (serverUser['id'] as String?) ?? userId;
          userEmail = (serverUser['email'] as String?) ?? userEmail;
          userName = (serverUser['displayName'] as String?) ?? userName;
          isPro = serverUser['isPro'] as bool? ?? false;
        }
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(userId: userId, email: userEmail);

      // Link with RevenueCat customer identity using canonical userId
      try {
        await Purchases.logIn(userId);
      } catch (_) {}

      final user = UserProfile(
        id: userId,
        email: userEmail,
        displayName: userName,
        photoUrl: photoUrl,
        provider: AuthProvider.google,
        isPro: isPro,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      await _restoreProCloudAfterSignIn();

      // Backup local Drift SQLite database to cloud
      await syncLocalDataToCloud();

      if (getIt.isRegistered<AssistantViewModel>()) {
        unawaited(getIt<AssistantViewModel>().syncQuotaFromServer());
      }

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'google_linked');
      TelemetryService.instance.setUserProperty(
        name: 'auth_provider',
        value: 'google',
      );
      TelemetryService.instance.setUserProperty(
        name: 'is_pro',
        value: isPro.toString(),
      );

      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Links an existing anonymous/guest session with Apple credentials and backs up local data
  Future<UserProfile?> linkGuestWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      String userEmail = 'user.finance@icloud.com';
      String userId = deterministicUserIdFromEmail(userEmail, prefix: 'usr_a_');
      String userName = 'Apple User';
      String? idToken;

      if (_hasFirebase) {
        final appleProvider = AppleAuthProvider();
        final currentFbUser = FirebaseAuth.instance.currentUser;
        UserCredential userCredential;
        if (currentFbUser != null && currentFbUser.isAnonymous) {
          try {
            userCredential = await currentFbUser.linkWithProvider(
              appleProvider,
            );
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use') {
              userCredential = await FirebaseAuth.instance.signInWithProvider(
                appleProvider,
              );
            } else {
              rethrow;
            }
          }
        } else {
          userCredential = await FirebaseAuth.instance.signInWithProvider(
            appleProvider,
          );
        }

        final fbUser = userCredential.user;
        if (fbUser != null) {
          userId = fbUser.uid;
          userEmail = (fbUser.email ?? userEmail).trim().toLowerCase();
          userName = fbUser.displayName ?? userName;
          idToken = await fbUser.getIdToken();
        }
      }

      // Synchronize with Cloudflare Server and adopt canonical account identity
      bool isPro = false;
      try {
        final serverRes = await ApiClient.instance.authenticateFirebase(
          uid: userId,
          idToken: idToken,
          email: userEmail,
          displayName: userName,
          provider: 'apple',
        );
        final serverUser = serverRes?['user'] as Map<String, dynamic>?;
        if (serverUser != null) {
          userId = (serverUser['id'] as String?) ?? userId;
          userEmail = (serverUser['email'] as String?) ?? userEmail;
          userName = (serverUser['displayName'] as String?) ?? userName;
          isPro = serverUser['isPro'] as bool? ?? false;
        }
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(userId: userId, email: userEmail);

      // Link with RevenueCat
      try {
        await Purchases.logIn(userId);
      } catch (_) {}

      final user = UserProfile(
        id: userId,
        email: userEmail,
        displayName: userName,
        provider: AuthProvider.apple,
        isPro: isPro,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      await _restoreProCloudAfterSignIn();

      // Backup local Drift SQLite database to cloud
      await syncLocalDataToCloud();

      if (getIt.isRegistered<AssistantViewModel>()) {
        unawaited(getIt<AssistantViewModel>().syncQuotaFromServer());
      }

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'apple_linked');
      TelemetryService.instance.setUserProperty(
        name: 'auth_provider',
        value: 'apple',
      );
      TelemetryService.instance.setUserProperty(
        name: 'is_pro',
        value: isPro.toString(),
      );

      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Timer? _autoSyncDebounce;

  /// Pulls the latest cloud backup from Hyprwise Cloud and restores into Drift SQLite
  Future<bool> pullCloudDataToLocal() async {
    _isCloudSyncing = true;
    notifyListeners();
    try {
      final result = await ApiClient.instance.pullSync();
      if (result == null || result['empty'] == true || result['data'] == null) {
        return false;
      }
      final dataPayload = result['data'];
      final jsonString =
          dataPayload is String ? dataPayload : jsonEncode(dataPayload);
      final dataRepo = getIt<DataRepository>();
      await dataRepo.importJson(jsonString);
      if (getIt.isRegistered<SettingsRepository>()) {
        // DataRepository writes directly to Drift; refresh the cached settings
        // so routing and the app theme/language see the restored preferences.
        await getIt<SettingsRepository>().load();
      }
      debugPrint('[Auth] Automatically pulled and synced cloud data.');
      return true;
    } catch (e) {
      debugPrint('[Auth] Auto sync pull notice: $e');
      return false;
    } finally {
      _isCloudSyncing = false;
      notifyListeners();
    }
  }

  /// Restores a Pro customer's encrypted snapshot after identity is known.
  /// A successful restore brings back `onboarded`, language, currency and
  /// notification preferences; a new account without a snapshot still sees
  /// onboarding normally.
  Future<void> _restoreProCloudAfterSignIn() async {
    final subscription =
        getIt.isRegistered<SubscriptionService>()
            ? getIt<SubscriptionService>()
            : null;
    final hasProAccess =
        _currentUser?.isPro == true || (subscription?.isPro ?? false);
    if (!hasProAccess) return;

    await pullCloudDataToLocal();
  }

  /// Called when local data changes to automatically back up to cloud if user is Pro
  void triggerProAutoSync() {
    final isPro =
        _currentUser?.isPro == true ||
        (getIt.isRegistered<SubscriptionService>() &&
            getIt<SubscriptionService>().isPro);
    if (!isPro || !isAuthenticated) return;

    _autoSyncDebounce?.cancel();
    _autoSyncDebounce = Timer(const Duration(seconds: 4), () {
      unawaited(syncLocalDataToCloud());
    });
  }

  /// Exports local Drift SQLite database and synchronizes with Hyprwise Cloud
  Future<void> syncLocalDataToCloud() async {
    final subscription =
        getIt.isRegistered<SubscriptionService>()
            ? getIt<SubscriptionService>()
            : null;
    final hasProAccess =
        _currentUser?.isPro == true || (subscription?.isPro ?? false);
    if (!isAuthenticated || !hasProAccess) return;

    try {
      final dataRepo = getIt<DataRepository>();
      final jsonString = await dataRepo.exportJson();
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      await ApiClient.instance.pushSync(map);
    } catch (e) {
      debugPrint('[Auth] Auto sync local data notice: $e');
    }
  }

  Future<UserProfile> signInAsGuest() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Reuse persistent device guest ID so logging out and logging in as guest on the same device
      // keeps the same server quota identity.
      String? storedGuestId = await _storage.read(key: _deviceGuestIdKey);
      String userId = storedGuestId ?? '';

      if (userId.isEmpty && _hasFirebase) {
        try {
          final userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          if (userCredential.user != null) {
            userId = userCredential.user!.uid;
          }
        } catch (_) {}
      }
      if (userId.isEmpty) {
        userId = 'usr_guest_device_1';
      }
      await _storage.write(key: _deviceGuestIdKey, value: userId);

      try {
        final serverRes = await ApiClient.instance.authenticateFirebase(
          uid: userId,
          email: 'guest@hyprwise.local',
          displayName: 'Guest User',
          provider: 'offline',
        );
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(
        userId: userId,
        email: 'guest@hyprwise.local',
      );

      final user = UserProfile(
        id: userId,
        email: 'guest@hyprwise.local',
        displayName: 'Guest User',
        provider: AuthProvider.guest,
        isPro: false,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      if (getIt.isRegistered<AssistantViewModel>()) {
        unawaited(getIt<AssistantViewModel>().syncQuotaFromServer());
      }

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'guest');
      TelemetryService.instance.setUserProperty(
        name: 'auth_provider',
        value: 'guest',
      );
      TelemetryService.instance.setUserProperty(name: 'is_pro', value: 'false');

      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_hasFirebase) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    try {
      await Purchases.logOut();
    } catch (_) {}

    _currentUser = null;
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _tokenKey);
    ApiClient.instance.clearAuthContext();

    if (getIt.isRegistered<SubscriptionService>()) {
      await getIt<SubscriptionService>().resetOnLogout();
    }

    // Firebase Analytics Tracking
    TelemetryService.instance.setUserId(null);
    TelemetryService.instance.trackEvent('auth_logout');

    notifyListeners();
  }

  void updateProStatus(bool isPro) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isPro: isPro);
      _storage.write(key: _userKey, value: jsonEncode(_currentUser!.toJson()));
      TelemetryService.instance.setUserProperty(
        name: 'is_pro',
        value: isPro.toString(),
      );
      notifyListeners();
    }
  }
}
