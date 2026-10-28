import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finance_tracker/app/app.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';

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

  await TelemetryService.init(
    runAppCallback: () async {
      await configureDependencies();
      runApp(const FinanceTrackerApp());
    },
  );
}
