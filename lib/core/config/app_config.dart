import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Centralized application build-time configuration.
/// Values are injected at compile time via terminal using:
///   `--dart-define-from-file=.env`
/// or
///   `--dart-define=SERVER_URL=https://...`
class AppConfig {
  AppConfig._();

  /// Primary Cloudflare / Hono server endpoint
  static const String serverUrl = String.fromEnvironment('SERVER_URL');

  /// Active environment identifier (production, staging, development)
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  /// RevenueCat Google Play API Key
  static const String revenueCatGoogleKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'goog_NyRCDaFXJiNwSTgzzDRRGkLKtyy',
  );

  /// RevenueCat Apple App Store API Key
  static const String revenueCatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: '',
  );

  /// Default Play Store public API key for Hyprwise
  static const String defaultRevenueCatKey = 'goog_NyRCDaFXJiNwSTgzzDRRGkLKtyy';

  /// Whether the required build-time variables have been supplied
  static bool get isConfigured => serverUrl.isNotEmpty;

  /// Verifies that all required build-time environment variables are present.
  /// Throws [StateError] if missing, preventing the app from executing with invalid state.
  static void validate() {
    // In unit testing, allow fallback to avoid breaking isolated logic tests
    final isTesting = const bool.fromEnvironment('FLUTTER_TEST') ||
        (kDebugMode && WidgetsBinding.instance is! WidgetsFlutterBinding);
    if (isTesting) return;

    if (serverUrl.trim().isEmpty) {
      throw StateError(
        'CRITICAL BUILD CONFIGURATION ERROR: SERVER_URL is missing!\n'
        'Hyprwise requires build-time environment variables loaded from terminal.\n\n'
        'Please build or run the application with:\n'
        '  flutter run --dart-define-from-file=.env\n'
        '  flutter build appbundle --dart-define-from-file=.env\n\n'
        'Ensure .env exists with SERVER_URL=https://...',
      );
    }
  }
}
