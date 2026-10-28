import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/accounts.dart';
import 'tables/app_preferences.dart';
import 'tables/budgets.dart';
import 'tables/debts.dart';
import 'tables/exchange_rates.dart';
import 'tables/goals.dart';
import 'tables/recurring_rules.dart';
import 'tables/transactions.dart';
import 'tables/transfers.dart';
import 'tables/work.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppPreferences,
    Accounts,
    Transactions,
    Transfers,
    RecurringRules,
    Jobs,
    Shifts,
    Goals,
    GoalContributions,
    Budgets,
    AlertRules,
    ExchangeRates,
    Debts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'finance_tracker'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(accounts);
      }
      if (from < 3) {
        await migrator.createTable(transactions);
      }
      if (from < 4) {
        await migrator.createTable(transfers);
      }
      if (from < 5) {
        await migrator.createTable(recurringRules);
        await migrator.createTable(jobs);
        await migrator.createTable(shifts);
        await migrator.createTable(goals);
        await migrator.createTable(goalContributions);
        await migrator.createTable(budgets);
        await migrator.createTable(alertRules);
        await migrator.createTable(exchangeRates);
        await migrator.addColumn(transfers, transfers.destinationAmountMinor);
        await migrator.addColumn(transfers, transfers.exchangeRateScaled);
      }
      if (from < 6) {
        await migrator.createTable(debts);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
