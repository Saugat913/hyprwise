import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finance_tracker/app/app.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/notifications/shift_notification_service.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  await initializeDateFormatting();

  // Global uncaught Flutter error handler
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    TelemetryService.instance.captureException(
      details.exception,
      stackTrace: details.stack,
      reason: details.context?.toString() ?? 'Flutter framework error',
    );
  };

  // Global uncaught platform & async error handler
  PlatformDispatcher.instance.onError = (error, stack) {
    TelemetryService.instance.captureException(
      error,
      stackTrace: stack,
      reason: 'Uncaught platform/async error',
    );
    return true;
  };

  // 1. Initialize local critical offline-first dependencies (DB, settings, accounts)
  await configureDependencies();

  // 2. Launch UI immediately for an instantaneous, smooth app start
  runApp(const FinanceTrackerApp());

  // 3. Defer auxiliary, network, and background services without blocking UI paint
  unawaited(_initBackgroundServices());
}

/// Initializes auxiliary and external network services concurrently in the background.
Future<void> _initBackgroundServices() async {
  // A. Firebase Analytics, Crash Telemetry & App Check / Play Integrity
  try {
    await TelemetryService.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Startup] Background Telemetry/Firebase init error: $e');
    }
  }

  // B. RevenueCat Purchases SDK
  try {
    if (getIt.isRegistered<SubscriptionService>()) {
      await getIt<SubscriptionService>().initRevenueCat();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Startup] Background RevenueCat init error: $e');
    }
  }

  // C. Notification Channels & Timezone data
  try {
    await ShiftNotificationService.instance.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Startup] Background Notifications init error: $e');
    }
  }
}
