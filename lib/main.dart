import 'package:flutter/widgets.dart';
import 'package:finance_tracker/app/app.dart';
import 'package:finance_tracker/app/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const FinanceTrackerApp());
}
