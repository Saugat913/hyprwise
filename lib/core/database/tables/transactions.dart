import 'package:drift/drift.dart';

import 'accounts.dart';

/// A recorded income or expense associated with one financial account.
///
/// Amounts are positive integer minor units. Direction is stored separately
/// in [type], so calculations never need to infer it from a signed amount.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get accountId => integer().references(Accounts, #id)();

  /// Stable machine-readable value: income or expense.
  TextColumn get type => text().withLength(min: 1, max: 16)();

  /// Positive amount in the smallest unit of the account's currency.
  IntColumn get amountMinor => integer()();

  /// Stable category key such as food, salary, or transport.
  TextColumn get category => text().withLength(min: 1, max: 40)();

  TextColumn get note => text().nullable().withLength(max: 500)();

  /// When the transaction happened, as Unix milliseconds.
  IntColumn get occurredAt => integer()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
