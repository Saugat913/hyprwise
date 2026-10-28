import 'package:drift/drift.dart';

import 'accounts.dart';

/// Money moved between two accounts. Transfers are not income or expenses.
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sourceAccountId => integer().references(Accounts, #id)();

  IntColumn get destinationAccountId => integer().references(Accounts, #id)();

  /// Positive amount in the smallest unit of the source account's currency.
  IntColumn get amountMinor => integer()();

  /// Amount received in the destination account's currency. Equals
  /// [amountMinor] for same-currency transfers; differs when a rate applies.
  IntColumn get destinationAmountMinor => integer().nullable()();

  /// quote per 1 source unit, scaled by 1,000,000. Null for same currency.
  IntColumn get exchangeRateScaled => integer().nullable()();

  TextColumn get note => text().nullable().withLength(max: 500)();

  IntColumn get occurredAt => integer()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
