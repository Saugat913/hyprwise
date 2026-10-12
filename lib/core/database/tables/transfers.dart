import 'package:drift/drift.dart';

import 'accounts.dart';

/// Money moved between two accounts. Transfers are not income or expenses.
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sourceAccountId => integer().references(Accounts, #id)();

  IntColumn get destinationAccountId =>
      integer().references(Accounts, #id)();

  /// Positive amount in the smallest unit of both accounts' currency.
  IntColumn get amountMinor => integer()();

  TextColumn get note => text().nullable().withLength(max: 500)();

  IntColumn get occurredAt => integer()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
