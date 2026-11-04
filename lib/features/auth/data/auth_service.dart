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
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
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
  bool _hasRestoredCloudData = false;
  bool _isReturningUser = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest =>
      _currentUser == null || _currentUser?.provider == AuthProvider.guest;
  bool get isLoading => _isLoading;
  bool get isCloudSyncing => _isCloudSyncing;
  bool get hasRestoredCloudData => _hasRestoredCloudData;
  bool get isReturningUser => _isReturningUser;

  static const _userKey = 'auth_user_profile';
  static const _tokenKey = 'auth_api_token';
  static const _deviceGuestIdKey = 'auth_device_guest_id';
  static const _appleCachedNameKey = 'auth_apple_cached_name';
  static const _appleCachedEmailKey = 'auth_apple_cached_email';
  static const _lastLoggedInUserIdKey = 'auth_last_logged_in_user_id';
  static String _keyUserOnboarded(String userId) => 'auth_user_onboarded_$userId';
  static String _keyUserCurrency(String userId) => 'auth_user_currency_$userId';
  static String _keyUserLocale(String userId) => 'auth_user_locale_$userId';

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

  /// Formats a human-readable display name from an email address prefix
  /// (e.g. "saugat.kandel@icloud.com" -> "Saugat Kandel", "jane_doe@..." -> "Jane Doe")
  static String formatDisplayNameFromEmail(String email) {
    if (!email.contains('@')) return email.isNotEmpty ? email : 'User';
    final prefix = email.split('@').first.trim();
    final parts = prefix.split(RegExp(r'[._\-]')).where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.map((p) => p[0].toUpperCase() + (p.length > 1 ? p.substring(1) : '')).join(' ');
    }
    return prefix.isNotEmpty ? prefix : 'User';
  }

  /// Safely extracts JWT claims from an ID token without external dependencies
  static Map<String, dynamic>? decodeJwtPayload(String? jwt) {
    if (jwt == null || !jwt.contains('.')) return null;
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      var normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payloadString) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Extracts user full name from OAuth additionalUserInfo profile
  static String? extractNameFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    if (profile['name'] is String && (profile['name'] as String).trim().isNotEmpty) {
      return (profile['name'] as String).trim();
    }
    if (profile['name'] is Map) {
      final nameMap = profile['name'] as Map;
      final first = (nameMap['firstName'] ?? nameMap['givenName'] ?? '').toString().trim();
      final last = (nameMap['lastName'] ?? nameMap['familyName'] ?? '').toString().trim();
      final combined = '$first $last'.trim();
      if (combined.isNotEmpty) return combined;
    }
    final first = (profile['firstName'] ?? profile['givenName'] ?? '').toString().trim();
    final last = (profile['lastName'] ?? profile['familyName'] ?? '').toString().trim();
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    return null;
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

  Future<UserProfile?> signInWithGoogle({
    String? email,
    String? displayName,
  }) async {
    String? userEmail;
    String? userId;
    String? userName;
    String? photoUrl;
    String? idToken;

    if (_hasFirebase) {
      try {
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final GoogleSignInAccount? gUser = await googleSignIn.signIn();
        if (gUser == null) {
          // User aborted / backed off Google Sign In - DO NOT BYPASS!
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
      } catch (e) {
        debugPrint('[Auth] Google native sign-in error or cancelled: $e');
        if (email == null) {
          return null;
        }
      }
    }

    if (email != null) {
      userEmail ??= email.trim().toLowerCase();
      userId ??= deterministicUserIdFromEmail(userEmail, prefix: 'usr_g_');
      userName ??= displayName ?? userEmail.split('@')[0];
    }

    if (userEmail == null || userId == null) {
      return null;
    }

    final String finalUserId = userId;
    final String finalEmail = userEmail;
    final String finalName = userName ?? finalEmail.split('@')[0];

    _isLoading = true;
    notifyListeners();
    try {
      final currentLocale = getIt.isRegistered<SettingsRepository>()
          ? getIt<SettingsRepository>().localeCode
          : null;
      final currentCurrency = getIt.isRegistered<SettingsRepository>()
          ? getIt<SettingsRepository>().baseCurrency
          : null;

      // Synchronize with Hyprwise Cloudflare Server and adopt canonical account identity
      bool isPro = false;
      Map<String, dynamic>? serverRes;
      try {
        serverRes = await ApiClient.instance.authenticateFirebase(
          uid: finalUserId,
          idToken: idToken,
          email: finalEmail,
          displayName: finalName,
          photoUrl: photoUrl,
          provider: 'google',
          locale: currentLocale,
          baseCurrency: currentCurrency,
        );
        final serverUser = serverRes?['user'] as Map<String, dynamic>?;
        if (serverUser != null) {
          isPro = serverUser['isPro'] as bool? ?? false;
        }
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(userId: finalUserId, email: finalEmail);

      // Link with RevenueCat customer identity using canonical userId
      try {
        final logInResult = await Purchases.logIn(finalUserId);
        if (logInResult.customerInfo.entitlements.active.containsKey('hyprwise_pro')) {
          isPro = true;
        }
      } catch (_) {}

      final user = UserProfile(
        id: finalUserId,
        email: finalEmail,
        displayName: finalName,
        photoUrl: photoUrl,
        provider: AuthProvider.google,
        isPro: isPro,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      await _handlePostSignInSetup(userId: finalUserId, serverRes: serverRes, isPro: isPro);

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(finalUserId);
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

  Future<UserProfile?> signInWithApple({String? email, String? fullName}) async {
    String? userEmail = email?.trim().toLowerCase();
    String? userId = userEmail != null ? deterministicUserIdFromEmail(userEmail, prefix: 'usr_a_') : null;
    String? userName = (fullName != null &&
            fullName.trim().isNotEmpty &&
            fullName.trim() != 'Apple User' &&
            fullName.trim() != 'Apple Account')
        ? fullName.trim()
        : null;
    String? idToken;

    if (_hasFirebase) {
      try {
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        final userCredential = await FirebaseAuth.instance.signInWithProvider(
          appleProvider,
        );
        final fbUser = userCredential.user;
        if (fbUser != null) {
          userId = fbUser.uid;
          idToken = await fbUser.getIdToken();

          // 1. Try extracting email and name from additionalUserInfo.profile
          final profile = userCredential.additionalUserInfo?.profile;
          if (profile != null) {
            final profileEmail = profile['email'] as String?;
            if (profileEmail != null && profileEmail.isNotEmpty) {
              userEmail ??= profileEmail.trim().toLowerCase();
            }
            final extractedName = extractNameFromProfile(profile);
            if (extractedName != null && extractedName.isNotEmpty) {
              userName ??= extractedName;
            }
          }

          // 2. Try extracting from fbUser.providerData
          for (final p in fbUser.providerData) {
            if ((userEmail == null || userEmail.isEmpty) && p.email != null && p.email!.isNotEmpty) {
              userEmail = p.email!.trim().toLowerCase();
            }
            if ((userName == null || userName.isEmpty || userName == 'Apple User' || userName == 'Apple Account') &&
                p.displayName != null &&
                p.displayName!.trim().isNotEmpty &&
                p.displayName!.trim() != 'Apple User' &&
                p.displayName!.trim() != 'Apple Account') {
              userName = p.displayName!.trim();
            }
          }

          // 3. Try extracting from idToken JWT claims
          if (idToken != null) {
            final claims = decodeJwtPayload(idToken);
            if (claims != null) {
              if (userEmail == null || userEmail.isEmpty) {
                final tokenEmail = claims['email'] as String?;
                if (tokenEmail != null && tokenEmail.isNotEmpty) {
                  userEmail = tokenEmail.trim().toLowerCase();
                }
              }
              if (userName == null || userName.isEmpty || userName == 'Apple User' || userName == 'Apple Account') {
                final tokenName = claims['name'] as String?;
                if (tokenName != null && tokenName.isNotEmpty && tokenName != 'Apple User') {
                  userName = tokenName.trim();
                }
              }
            }
          }

          // 4. Check direct fbUser properties
          if (fbUser.email != null && fbUser.email!.isNotEmpty) {
            userEmail ??= fbUser.email!.trim().toLowerCase();
          }
          if (fbUser.displayName != null &&
              fbUser.displayName!.trim().isNotEmpty &&
              fbUser.displayName!.trim() != 'Apple User' &&
              fbUser.displayName!.trim() != 'Apple Account') {
            userName ??= fbUser.displayName!.trim();
          }

          // 5. Restore from secure storage cache by userId, then global fallback
          userEmail ??= await _storage.read(key: 'auth_apple_email_$userId');
          userEmail ??= await _storage.read(key: _appleCachedEmailKey);

          userName ??= await _storage.read(key: 'auth_apple_name_$userId');
          userName ??= await _storage.read(key: _appleCachedNameKey);

          // 6. Cache valid email and name back to storage
          if (userEmail != null && userEmail.isNotEmpty) {
            await _storage.write(key: 'auth_apple_email_$userId', value: userEmail);
            await _storage.write(key: _appleCachedEmailKey, value: userEmail);
          }
          if (userName != null &&
              userName.isNotEmpty &&
              userName != 'Apple User' &&
              userName != 'Apple Account') {
            await _storage.write(key: 'auth_apple_name_$userId', value: userName);
            await _storage.write(key: _appleCachedNameKey, value: userName);
          }
        } else {
          return null;
        }
      } catch (e) {
        debugPrint('[Auth] Apple native sign-in error or cancelled: $e');
        if (email == null) {
          return null;
        }
      }
    }

    if (email != null) {
      userEmail ??= email.trim().toLowerCase();
      userId ??= deterministicUserIdFromEmail(userEmail, prefix: 'usr_a_');
      if (fullName != null &&
          fullName.trim().isNotEmpty &&
          fullName.trim() != 'Apple User' &&
          fullName.trim() != 'Apple Account') {
        userName ??= fullName.trim();
      }
    }

    if (userEmail == null || userId == null) {
      return null;
    }

    // If userName is still absent or generic, format human-friendly username from email prefix
    if (userName == null ||
        userName.trim().isEmpty ||
        userName.trim() == 'Apple User' ||
        userName.trim() == 'Apple Account') {
      userName = formatDisplayNameFromEmail(userEmail);
    }

    final String finalUserId = userId;
    String finalEmail = userEmail;
    String finalName = userName;

    // Persist final resolved identity to secure storage cache
    await _storage.write(key: 'auth_apple_email_$finalUserId', value: finalEmail);
    await _storage.write(key: _appleCachedEmailKey, value: finalEmail);
    await _storage.write(key: 'auth_apple_name_$finalUserId', value: finalName);
    await _storage.write(key: _appleCachedNameKey, value: finalName);

    // Update Firebase user displayName on-device if possible
    if (_hasFirebase) {
      try {
        final currentFb = FirebaseAuth.instance.currentUser;
        if (currentFb != null &&
            (currentFb.displayName == null ||
             currentFb.displayName!.isEmpty ||
             currentFb.displayName == 'Apple User')) {
          await currentFb.updateDisplayName(finalName);
        }
      } catch (_) {}
    }

    _isLoading = true;
    notifyListeners();
    try {
      final currentLocale = getIt.isRegistered<SettingsRepository>()
          ? getIt<SettingsRepository>().localeCode
          : null;
      final currentCurrency = getIt.isRegistered<SettingsRepository>()
          ? getIt<SettingsRepository>().baseCurrency
          : null;

      // Synchronize with Hyprwise Cloudflare Server and adopt canonical account identity
      bool isPro = false;
      Map<String, dynamic>? serverRes;
      try {
        serverRes = await ApiClient.instance.authenticateFirebase(
          uid: finalUserId,
          idToken: idToken,
          email: finalEmail,
          displayName: finalName,
          provider: 'apple',
          locale: currentLocale,
          baseCurrency: currentCurrency,
        );
        final serverUser = serverRes?['user'] as Map<String, dynamic>?;
        if (serverUser != null) {
          isPro = serverUser['isPro'] as bool? ?? false;
          final sName = serverUser['displayName'] as String?;
          if (sName != null &&
              sName.trim().isNotEmpty &&
              sName.trim() != 'Apple User' &&
              sName.trim() != 'Apple Account') {
            finalName = sName.trim();
          }
          final sEmail = serverUser['email'] as String?;
          if (sEmail != null && sEmail.trim().isNotEmpty && !sEmail.startsWith('guest@')) {
            finalEmail = sEmail.trim().toLowerCase();
          }
        }
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(userId: finalUserId, email: finalEmail);

      // Link with RevenueCat
      try {
        final logInResult = await Purchases.logIn(finalUserId);
        if (logInResult.customerInfo.entitlements.active.containsKey('hyprwise_pro')) {
          isPro = true;
        }
      } catch (_) {}

      final user = UserProfile(
        id: finalUserId,
        email: finalEmail,
        displayName: finalName,
        provider: AuthProvider.apple,
        isPro: isPro,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      await _handlePostSignInSetup(userId: finalUserId, serverRes: serverRes, isPro: isPro);

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(finalUserId);
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
      String? userEmail;
      String? userId;
      String? userName;
      String? idToken;

      if (_hasFirebase) {
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
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
          idToken = await fbUser.getIdToken();

          // 1. Extract from profile
          final profile = userCredential.additionalUserInfo?.profile;
          if (profile != null) {
            final profileEmail = profile['email'] as String?;
            if (profileEmail != null && profileEmail.isNotEmpty) {
              userEmail = profileEmail.trim().toLowerCase();
            }
            final extractedName = extractNameFromProfile(profile);
            if (extractedName != null && extractedName.isNotEmpty) {
              userName = extractedName;
            }
          }

          // 2. Extract from providerData
          for (final p in fbUser.providerData) {
            if ((userEmail == null || userEmail.isEmpty) && p.email != null && p.email!.isNotEmpty) {
              userEmail = p.email!.trim().toLowerCase();
            }
            if ((userName == null || userName.isEmpty || userName == 'Apple User' || userName == 'Apple Account') &&
                p.displayName != null &&
                p.displayName!.trim().isNotEmpty &&
                p.displayName!.trim() != 'Apple User' &&
                p.displayName!.trim() != 'Apple Account') {
              userName = p.displayName!.trim();
            }
          }

          // 3. Extract from JWT claims
          if (idToken != null) {
            final claims = decodeJwtPayload(idToken);
            if (claims != null) {
              if (userEmail == null || userEmail.isEmpty) {
                final tokenEmail = claims['email'] as String?;
                if (tokenEmail != null && tokenEmail.isNotEmpty) {
                  userEmail = tokenEmail.trim().toLowerCase();
                }
              }
              if (userName == null || userName.isEmpty || userName == 'Apple User' || userName == 'Apple Account') {
                final tokenName = claims['name'] as String?;
                if (tokenName != null && tokenName.isNotEmpty && tokenName != 'Apple User') {
                  userName = tokenName.trim();
                }
              }
            }
          }

          // 4. Direct fbUser
          if (fbUser.email != null && fbUser.email!.isNotEmpty) {
            userEmail ??= fbUser.email!.trim().toLowerCase();
          }
          if (fbUser.displayName != null &&
              fbUser.displayName!.trim().isNotEmpty &&
              fbUser.displayName!.trim() != 'Apple User' &&
              fbUser.displayName!.trim() != 'Apple Account') {
            userName ??= fbUser.displayName!.trim();
          }

          // 5. Secure storage fallback
          userEmail ??= await _storage.read(key: 'auth_apple_email_$userId');
          userEmail ??= await _storage.read(key: _appleCachedEmailKey);

          userName ??= await _storage.read(key: 'auth_apple_name_$userId');
          userName ??= await _storage.read(key: _appleCachedNameKey);
        }
      }

      userEmail ??= await _storage.read(key: _appleCachedEmailKey);
      userId ??= userEmail != null
          ? deterministicUserIdFromEmail(userEmail, prefix: 'usr_a_')
          : 'usr_a_unknown';
      if (userEmail == null || userEmail.isEmpty) {
        userEmail = 'user.finance@icloud.com';
      }

      if (userName == null ||
          userName.trim().isEmpty ||
          userName.trim() == 'Apple User' ||
          userName.trim() == 'Apple Account') {
        userName = formatDisplayNameFromEmail(userEmail);
      }

      final String finalUserId = userId;
      String finalEmail = userEmail;
      String finalName = userName;

      // Cache to storage
      await _storage.write(key: 'auth_apple_email_$finalUserId', value: finalEmail);
      await _storage.write(key: _appleCachedEmailKey, value: finalEmail);
      await _storage.write(key: 'auth_apple_name_$finalUserId', value: finalName);
      await _storage.write(key: _appleCachedNameKey, value: finalName);

      // Update Firebase user displayName on-device if possible
      if (_hasFirebase) {
        try {
          final currentFb = FirebaseAuth.instance.currentUser;
          if (currentFb != null &&
              (currentFb.displayName == null ||
               currentFb.displayName!.isEmpty ||
               currentFb.displayName == 'Apple User')) {
            await currentFb.updateDisplayName(finalName);
          }
        } catch (_) {}
      }

      // Synchronize with Cloudflare Server and adopt canonical account identity
      bool isPro = false;
      try {
        final serverRes = await ApiClient.instance.authenticateFirebase(
          uid: finalUserId,
          idToken: idToken,
          email: finalEmail,
          displayName: finalName,
          provider: 'apple',
        );
        final serverUser = serverRes?['user'] as Map<String, dynamic>?;
        if (serverUser != null) {
          final sName = serverUser['displayName'] as String?;
          if (sName != null &&
              sName.trim().isNotEmpty &&
              sName.trim() != 'Apple User' &&
              sName.trim() != 'Apple Account') {
            finalName = sName.trim();
          }
          final sEmail = serverUser['email'] as String?;
          if (sEmail != null && sEmail.trim().isNotEmpty && !sEmail.startsWith('guest@')) {
            finalEmail = sEmail.trim().toLowerCase();
          }
          isPro = serverUser['isPro'] as bool? ?? false;
        }
        await _applyServerSyncResult(serverRes);
      } catch (_) {}

      ApiClient.instance.setAuthContext(userId: finalUserId, email: finalEmail);

      // Link with RevenueCat
      try {
        await Purchases.logIn(finalUserId);
      } catch (_) {}

      final user = UserProfile(
        id: finalUserId,
        email: finalEmail,
        displayName: finalName,
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

  /// Records onboarding completion for this user in secure storage and backend
  Future<void> markUserOnboarded({
    required String userId,
    required String locale,
    required String baseCurrency,
  }) async {
    _isReturningUser = true;
    final email = _currentUser?.email.trim().toLowerCase() ?? '';
    await _storage.write(key: _lastLoggedInUserIdKey, value: userId);
    await _storage.write(key: _keyUserOnboarded(userId), value: 'true');
    await _storage.write(key: _keyUserLocale(userId), value: locale);
    await _storage.write(key: _keyUserCurrency(userId), value: baseCurrency);
    if (email.isNotEmpty) {
      await _storage.write(key: 'auth_user_locale_$email', value: locale);
      await _storage.write(key: 'auth_user_currency_$email', value: baseCurrency);
      await _storage.write(key: 'auth_user_onboarded_$email', value: 'true');
    }
    await _storage.write(key: 'auth_last_known_locale', value: locale);
    await _storage.write(key: 'auth_last_known_currency', value: baseCurrency);

    unawaited(ApiClient.instance.updatePreferences(
      userId: userId,
      email: email,
      locale: locale,
      baseCurrency: baseCurrency,
    ));
  }

  /// Synchronizes lightweight preferences (locale, baseCurrency) with Hyprwise Server
  /// ensuring free and Pro accounts alike have basic cross-device remembrance.
  Future<void> syncUserPreferences({
    String? locale,
    String? baseCurrency,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final effectiveLocale = locale ??
        (getIt.isRegistered<SettingsRepository>()
            ? getIt<SettingsRepository>().localeCode
            : 'en');
    final effectiveCurrency = baseCurrency ??
        (getIt.isRegistered<SettingsRepository>()
            ? getIt<SettingsRepository>().baseCurrency
            : 'USD');

    await _storage.write(
      key: _keyUserLocale(user.id),
      value: effectiveLocale,
    );
    await _storage.write(
      key: _keyUserCurrency(user.id),
      value: effectiveCurrency,
    );
    final email = user.email.trim().toLowerCase();
    if (email.isNotEmpty) {
      await _storage.write(key: 'auth_user_locale_$email', value: effectiveLocale);
      await _storage.write(key: 'auth_user_currency_$email', value: effectiveCurrency);
    }
    await _storage.write(key: 'auth_last_known_locale', value: effectiveLocale);
    await _storage.write(key: 'auth_last_known_currency', value: effectiveCurrency);

    unawaited(ApiClient.instance.updatePreferences(
      userId: user.id,
      email: email,
      locale: effectiveLocale,
      baseCurrency: effectiveCurrency,
    ));
  }

  /// Coordinates post-sign-in state, distinguishing returning users from first-time sign-ups
  Future<void> _handlePostSignInSetup({
    required String userId,
    Map<String, dynamic>? serverRes,
    bool isPro = false,
  }) async {
    // 1. Account switching check:
    // If a different user was previously active on this device, erase the old user's local database
    final lastUserId = await _storage.read(key: _lastLoggedInUserIdKey);
    if (lastUserId != null && lastUserId.isNotEmpty && lastUserId != userId) {
      if (getIt.isRegistered<DataRepository>()) {
        await getIt<DataRepository>().eraseAll();
      }
    }
    await _storage.write(key: _lastLoggedInUserIdKey, value: userId);

    final emailKey = _currentUser?.email.trim().toLowerCase() ?? '';

    // 2. Identify if user is returning or brand new:
    // a) Cloudflare server explicit flag (isNewUser == false)
    // b) Server preferences object (onboarded == true)
    // c) Local secure storage key for this specific user ID or email
    final isNewUserFromServer = serverRes?['isNewUser'] as bool?;
    final serverPrefs = serverRes?['preferences'] as Map<String, dynamic>?;
    final serverOnboarded = serverPrefs?['onboarded'] as bool?;
    final localOnboarded = await _storage.read(key: _keyUserOnboarded(userId)) ??
        (emailKey.isNotEmpty ? await _storage.read(key: 'auth_user_onboarded_$emailKey') : null);

    final bool isReturning = (isNewUserFromServer == false && (serverOnboarded == true || serverPrefs != null)) ||
        (localOnboarded == 'true');

    _isReturningUser = isReturning;

    if (!isReturning) {
      // NEW USER:
      // Do NOT complete onboarding or pull cloud data.
      // Reset onboarding flag so user enters the language and currency onboarding wizard.
      _hasRestoredCloudData = false;
      if (getIt.isRegistered<SettingsRepository>()) {
        await getIt<SettingsRepository>().resetOnboarding();
      }
    } else {
      // OLD (RETURNING) USER:
      // Download preferences and restore settings
      final serverLocale = (serverPrefs?['locale'] as String?)?.trim();
      final serverCurrency = (serverPrefs?['baseCurrency'] as String?)?.trim();
      final localLocale = await _storage.read(key: _keyUserLocale(userId)) ??
          (emailKey.isNotEmpty ? await _storage.read(key: 'auth_user_locale_$emailKey') : null) ??
          await _storage.read(key: 'auth_last_known_locale');
      final localCurrency = await _storage.read(key: _keyUserCurrency(userId)) ??
          (emailKey.isNotEmpty ? await _storage.read(key: 'auth_user_currency_$emailKey') : null) ??
          await _storage.read(key: 'auth_last_known_currency');

      final preferredLocale = (serverLocale != null && serverLocale.isNotEmpty)
          ? serverLocale
          : (localLocale != null && localLocale.isNotEmpty ? localLocale : 'en');

      final preferredCurrency = (serverCurrency != null && serverCurrency.isNotEmpty)
          ? serverCurrency
          : (localCurrency != null && localCurrency.isNotEmpty ? localCurrency : 'USD');

      if (getIt.isRegistered<SettingsRepository>()) {
        final settingsRepo = getIt<SettingsRepository>();
        if (preferredLocale != settingsRepo.localeCode) {
          await settingsRepo.setLocaleCode(preferredLocale);
        }
        if (preferredCurrency != settingsRepo.baseCurrency) {
          await settingsRepo.setBaseCurrency(preferredCurrency);
        }
        await settingsRepo.completeOnboarding();
      }

      if (getIt.isRegistered<AccountRepository>()) {
        await getIt<AccountRepository>().ensureFixedTwoAccounts(preferredCurrency);
      }

      // Persist user-specific flags to storage
      await _storage.write(key: _keyUserOnboarded(userId), value: 'true');
      await _storage.write(key: _keyUserCurrency(userId), value: preferredCurrency);
      await _storage.write(key: _keyUserLocale(userId), value: preferredLocale);
      if (emailKey.isNotEmpty) {
        await _storage.write(key: 'auth_user_onboarded_$emailKey', value: 'true');
        await _storage.write(key: 'auth_user_currency_$emailKey', value: preferredCurrency);
        await _storage.write(key: 'auth_user_locale_$emailKey', value: preferredLocale);
      }
      await _storage.write(key: 'auth_last_known_locale', value: preferredLocale);
      await _storage.write(key: 'auth_last_known_currency', value: preferredCurrency);

      // Re-sync final resolved preferences to server in background
      unawaited(ApiClient.instance.updatePreferences(
        userId: userId,
        email: emailKey,
        locale: preferredLocale,
        baseCurrency: preferredCurrency,
      ));

      // PRO vs NON-PRO data sync:
      // If user is PRO, restore previous data from Cloudflare server
      final isProUser = _currentUser?.isPro ?? isPro;
      if (isProUser) {
        _hasRestoredCloudData = await pullCloudDataToLocal();
      } else {
        _hasRestoredCloudData = false;
      }
    }

    // Trigger auto-sync if Pro
    triggerProAutoSync();

    if (getIt.isRegistered<AssistantViewModel>()) {
      unawaited(getIt<AssistantViewModel>().syncQuotaFromServer());
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
    _isReturningUser = false;
    _hasRestoredCloudData = false;
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _tokenKey);
    ApiClient.instance.clearAuthContext();

    if (getIt.isRegistered<SubscriptionService>()) {
      await getIt<SubscriptionService>().resetOnLogout();
    }

    if (getIt.isRegistered<SettingsRepository>()) {
      await getIt<SettingsRepository>().resetOnboarding();
    }

    // Local-First: We preserve encrypted local SQLite database data across sign-outs.
    // If a different user later signs in, account switching logic clears old data.

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
