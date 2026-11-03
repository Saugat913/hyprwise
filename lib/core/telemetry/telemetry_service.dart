import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:finance_tracker/firebase_options.dart';

/// Lightweight telemetry, analytics, and diagnostics service backed by Firebase Analytics.
///
/// Tracks domain events (e.g. shift clock-ins, backup exports, goal completions,
/// transactions), screens, and errors while gracefully falling back to local debug logging
/// when Firebase is offline or not configured with project credentials.
class TelemetryService {
  TelemetryService._();

  static final TelemetryService instance = TelemetryService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static FirebaseAnalytics? _analytics;
  FirebaseAnalytics? get analytics => _analytics;
  static String? _currentUserId;
  static String? get currentUserId => _currentUserId;

  /// Returns a [NavigatorObserver] for route analytics.
  NavigatorObserver get navigationObserver => TelemetryNavigatorObserver();

  /// Initializes Firebase and Firebase Analytics.
  /// Pass [options] or rely on default/environment configuration.
  /// [runAppCallback] is supported for backward compatibility.
  static Future<void> init({
    FirebaseOptions? options,
    Future<void> Function()? runAppCallback,
  }) async {
    try {
      FirebaseOptions? effectiveOptions;
      try {
        effectiveOptions = options ?? DefaultFirebaseOptions.currentPlatform;
      } catch (_) {
        effectiveOptions = null;
      }
      if (Firebase.apps.isEmpty) {
        if (effectiveOptions != null && effectiveOptions.apiKey.isNotEmpty) {
          await Firebase.initializeApp(options: effectiveOptions);
        } else {
          // Attempt platform default initialization (e.g. from native google-services.json / GoogleService-Info.plist)
          await Firebase.initializeApp();
        }
      }

      _analytics = FirebaseAnalytics.instance;
      // Analytics collection enabled by default
      await _analytics?.setAnalyticsCollectionEnabled(true);
      _initialized = true;

      // Initialize Firebase App Check / Play Integrity to protect backend from external scrapers
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleDeviceCheckProvider(),
        );
        if (kDebugMode) {
          debugPrint('[AppCheck] Firebase App Check activated successfully.');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AppCheck] App Check init notice: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('[Telemetry] Firebase Analytics initialized successfully.');
      }
    } catch (e) {
      _initialized = false;
      _analytics = null;
      if (kDebugMode) {
        debugPrint('[Telemetry] Firebase not initialized (${e.toString()}); operating in local logging mode.');
      }
    }

    if (runAppCallback != null) {
      await runAppCallback();
    }
  }

  /// Logs a business event (e.g. 'shift_started', 'transaction_added').
  void trackEvent(String name, [Map<String, dynamic>? parameters]) {
    final sanitizedName = _sanitizeEventName(name);
    final sanitizedParams = parameters != null ? _sanitizeParameters(parameters) : null;

    if (kDebugMode) {
      debugPrint('[Telemetry][event] $sanitizedName ${sanitizedParams ?? ""}');
    }

    if (_initialized && _analytics != null) {
      try {
        _analytics!.logEvent(
          name: sanitizedName,
          parameters: sanitizedParams,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to logEvent to Firebase: $e');
        }
      }
    }
  }

  /// Logs screen transitions for UX analytics.
  void logScreenView(String screenName, {String? screenClass}) {
    if (kDebugMode) {
      debugPrint('[Telemetry][screen] $screenName');
    }

    if (_initialized && _analytics != null) {
      try {
        _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenClass ?? screenName,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to logScreenView: $e');
        }
      }
    }
  }

  /// Sets the user ID for Firebase Analytics user tracking.
  Future<void> setUserId(String? userId) async {
    _currentUserId = userId;
    if (kDebugMode) {
      debugPrint('[Telemetry][user_id] $userId');
    }
    if (_initialized && _analytics != null) {
      try {
        await _analytics!.setUserId(id: userId);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to setUserId: $e');
        }
      }
    }
  }

  /// Sets a user property for cohort analysis (e.g. 'base_currency', 'theme_mode', 'is_pro').
  Future<void> setUserProperty({required String name, required String? value}) async {
    if (kDebugMode) {
      debugPrint('[Telemetry][user_prop] $name=$value');
    }

    if (_initialized && _analytics != null) {
      try {
        await _analytics!.setUserProperty(name: name, value: value);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to setUserProperty: $e');
        }
      }
    }
  }

  /// Logs user login event to Firebase Analytics.
  Future<void> logLogin({required String loginMethod}) async {
    if (kDebugMode) {
      debugPrint('[Telemetry][login] method=$loginMethod');
    }
    if (_initialized && _analytics != null) {
      try {
        await _analytics!.logLogin(loginMethod: loginMethod);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to logLogin: $e');
        }
      }
    }
  }

  /// Logs user sign-up event to Firebase Analytics.
  Future<void> logSignUp({required String signUpMethod}) async {
    if (kDebugMode) {
      debugPrint('[Telemetry][signup] method=$signUpMethod');
    }
    if (_initialized && _analytics != null) {
      try {
        await _analytics!.logSignUp(signUpMethod: signUpMethod);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to logSignUp: $e');
        }
      }
    }
  }

  /// Logs purchase event to Firebase Analytics.
  Future<void> logPurchase({
    required String currency,
    required double value,
    String? transactionId,
    List<AnalyticsEventItem>? items,
  }) async {
    if (kDebugMode) {
      debugPrint('[Telemetry][purchase] currency=$currency value=$value transactionId=$transactionId');
    }
    if (_initialized && _analytics != null) {
      try {
        await _analytics!.logPurchase(
          currency: currency,
          value: value,
          transactionId: transactionId,
          items: items,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to logPurchase: $e');
        }
      }
    }
  }

  /// Clears analytics data on logout or account deletion.
  Future<void> resetAnalyticsData() async {
    if (kDebugMode) {
      debugPrint('[Telemetry] Resetting analytics data');
    }
    if (_initialized && _analytics != null) {
      try {
        await _analytics!.resetAnalyticsData();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Telemetry] Failed to reset analytics data: $e');
        }
      }
    }
  }

  /// Diagnostic breadcrumb or status log.
  void log(String message, {String category = 'app', Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('[Telemetry][$category] $message ${data ?? ""}');
    }
    // Forward as an analytics event if noteworthy category
    if (category != 'app') {
      trackEvent('${category}_$message', data);
    }
  }

  /// Captures an error or exception.
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? reason,
    Map<String, dynamic>? extra,
  }) async {
    if (kDebugMode) {
      debugPrint('[Telemetry] Exception: $exception ($reason)');
      if (stackTrace != null) debugPrint('$stackTrace');
    }

    if (_initialized && _analytics != null) {
      try {
        final params = <String, Object>{
          'description': (reason ?? exception.toString()).takeMax(100),
          'fatal': false,
        };
        if (extra != null) {
          for (final entry in extra.entries) {
            final val = entry.value;
            if (val is num || val is String) {
              params[entry.key] = val;
            } else if (val != null) {
              params[entry.key] = val.toString().takeMax(100);
            }
          }
        }
        await _analytics!.logEvent(
          name: 'app_exception',
          parameters: params,
        );
      } catch (_) {}
    }
  }

  static String _sanitizeEventName(String name) {
    // Firebase event names can be up to 40 characters and contain alphanumeric and underscores
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  static Map<String, Object> _sanitizeParameters(Map<String, dynamic> raw) {
    final sanitized = <String, Object>{};
    for (final entry in raw.entries) {
      final key = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final val = entry.value;
      if (val is num || val is String) {
        sanitized[key] = val;
      } else if (val != null) {
        sanitized[key] = val.toString();
      }
    }
    return sanitized;
  }
}

/// Navigation observer for route analytics.
class TelemetryNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _logRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _logRoute(previousRoute);
  }

  void _logRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      TelemetryService.instance.logScreenView(name);
    }
  }
}

extension on String {
  String takeMax(int max) => length > max ? substring(0, max) : this;
}
