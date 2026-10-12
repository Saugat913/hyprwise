import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/accounts.dart';
import 'tables/app_preferences.dart';
import 'tables/transactions.dart';
import 'tables/transfers.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [AppPreferences, Accounts, Transactions, Transfers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'finance_tracker'));

  @override
  int get schemaVersion => 4;

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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
