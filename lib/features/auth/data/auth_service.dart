import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/network/api_client.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/auth/data/model/user_profile.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AuthService extends ChangeNotifier {
  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _currentUser == null || _currentUser?.provider == AuthProvider.guest;
  bool get isLoading => _isLoading;

  static const _userKey = 'auth_user_profile';

  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _currentUser = UserProfile.fromJson(map);
        TelemetryService.instance.setUserId(_currentUser!.id);
        TelemetryService.instance.setUserProperty(name: 'is_pro', value: _currentUser!.isPro.toString());
        TelemetryService.instance.setUserProperty(name: 'auth_provider', value: _currentUser!.provider.name);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading auth profile: $e');
    }
  }

  Future<UserProfile> signInWithGoogle({String? email, String? displayName}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String userId = 'usr_google_demo_1';
      String userEmail = email ?? 'user.finance@gmail.com';
      String userName = displayName ?? 'Google User';
      String? photoUrl;
      String? idToken;

      if (_hasFirebase) {
        try {
          final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
          final GoogleSignInAccount? gUser = await googleSignIn.signIn();
          if (gUser != null) {
            userEmail = gUser.email;
            userName = gUser.displayName ?? userEmail.split('@')[0];
            photoUrl = gUser.photoUrl;

            final GoogleSignInAuthentication gAuth = await gUser.authentication;
            idToken = gAuth.idToken;

            final credential = GoogleAuthProvider.credential(
              accessToken: gAuth.accessToken,
              idToken: gAuth.idToken,
            );

            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            final fbUser = userCredential.user;
            if (fbUser != null) {
              userId = fbUser.uid;
              userEmail = fbUser.email ?? userEmail;
              userName = fbUser.displayName ?? userName;
              photoUrl = fbUser.photoURL ?? photoUrl;
              idToken = await fbUser.getIdToken();
            }
          }
        } catch (e) {
          debugPrint('[Auth] Google native sign-in fallback: $e');
        }
      }

      // Synchronize with Hyprwise Cloudflare Server
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
        isPro = serverUser?['isPro'] as bool? ?? false;
      } catch (_) {}

      // Link with RevenueCat customer identity
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

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'google');
      TelemetryService.instance.setUserProperty(name: 'auth_provider', value: 'google');
      TelemetryService.instance.setUserProperty(name: 'is_pro', value: isPro.toString());

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
      String userId = 'usr_apple_demo_1';
      String userEmail = email ?? 'user.finance@icloud.com';
      String userName = fullName ?? 'Apple User';
      String? idToken;

      if (_hasFirebase) {
        try {
          final appleProvider = AppleAuthProvider();
          final userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
          final fbUser = userCredential.user;
          if (fbUser != null) {
            userId = fbUser.uid;
            userEmail = fbUser.email ?? userEmail;
            userName = fbUser.displayName ?? userName;
            idToken = await fbUser.getIdToken();
          }
        } catch (e) {
          debugPrint('[Auth] Apple native sign-in fallback: $e');
        }
      }

      // Synchronize with Hyprwise Cloudflare Server
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
        isPro = serverUser?['isPro'] as bool? ?? false;
      } catch (_) {}

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

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'apple');
      TelemetryService.instance.setUserProperty(name: 'auth_provider', value: 'apple');
      TelemetryService.instance.setUserProperty(name: 'is_pro', value: isPro.toString());

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
      String userId = _currentUser?.id ?? 'usr_google_${DateTime.now().millisecondsSinceEpoch}';
      String userEmail = 'user.finance@gmail.com';
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

        userEmail = gUser.email;
        userName = gUser.displayName ?? userEmail.split('@')[0];
        photoUrl = gUser.photoUrl;

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
              userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            } else {
              rethrow;
            }
          }
        } else {
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        }

        final fbUser = userCredential.user;
        if (fbUser != null) {
          userId = fbUser.uid;
          userEmail = fbUser.email ?? userEmail;
          userName = fbUser.displayName ?? userName;
          photoUrl = fbUser.photoURL ?? photoUrl;
          idToken = await fbUser.getIdToken();
        }
      }

      // Synchronize with Cloudflare Server
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
        isPro = serverUser?['isPro'] as bool? ?? false;
      } catch (_) {}

      // Link with RevenueCat customer identity
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

      // Backup local Drift SQLite database to cloud
      await syncLocalDataToCloud();

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'google_linked');
      TelemetryService.instance.setUserProperty(name: 'auth_provider', value: 'google');
      TelemetryService.instance.setUserProperty(name: 'is_pro', value: isPro.toString());

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
      String userId = _currentUser?.id ?? 'usr_apple_${DateTime.now().millisecondsSinceEpoch}';
      String userEmail = 'user.finance@icloud.com';
      String userName = 'Apple User';
      String? idToken;

      if (_hasFirebase) {
        final appleProvider = AppleAuthProvider();
        final currentFbUser = FirebaseAuth.instance.currentUser;
        UserCredential userCredential;
        if (currentFbUser != null && currentFbUser.isAnonymous) {
          try {
            userCredential = await currentFbUser.linkWithProvider(appleProvider);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use') {
              userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
            } else {
              rethrow;
            }
          }
        } else {
          userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
        }

        final fbUser = userCredential.user;
        if (fbUser != null) {
          userId = fbUser.uid;
          userEmail = fbUser.email ?? userEmail;
          userName = fbUser.displayName ?? userName;
          idToken = await fbUser.getIdToken();
        }
      }

      // Synchronize with Cloudflare Server
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
        isPro = serverUser?['isPro'] as bool? ?? false;
      } catch (_) {}

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

      // Backup local Drift SQLite database to cloud
      await syncLocalDataToCloud();

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'apple_linked');
      TelemetryService.instance.setUserProperty(name: 'auth_provider', value: 'apple');
      TelemetryService.instance.setUserProperty(name: 'is_pro', value: isPro.toString());

      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exports local Drift SQLite database and synchronizes with Hyprwise Cloud
  Future<void> syncLocalDataToCloud() async {
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
      String userId = 'usr_guest_offline';
      if (_hasFirebase) {
        try {
          final userCredential = await FirebaseAuth.instance.signInAnonymously();
          if (userCredential.user != null) {
            userId = userCredential.user!.uid;
          }
        } catch (_) {}
      }

      final user = UserProfile(
        id: userId,
        email: 'guest@hyprwise.local',
        displayName: 'Guest User',
        provider: AuthProvider.guest,
        isPro: false,
      );
      _currentUser = user;
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      // Firebase Analytics Tracking
      TelemetryService.instance.setUserId(userId);
      TelemetryService.instance.logLogin(loginMethod: 'guest');
      TelemetryService.instance.setUserProperty(name: 'auth_provider', value: 'guest');
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

    // Firebase Analytics Tracking
    TelemetryService.instance.setUserId(null);
    TelemetryService.instance.trackEvent('auth_logout');

    notifyListeners();
  }

  void updateProStatus(bool isPro) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isPro: isPro);
      _storage.write(key: _userKey, value: jsonEncode(_currentUser!.toJson()));
      TelemetryService.instance.setUserProperty(name: 'is_pro', value: isPro.toString());
      notifyListeners();
    }
  }
}
