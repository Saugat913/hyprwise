import 'package:drift/drift.dart';

/// A financial account such as cash, checking, savings, or a credit account.
///
/// Amounts are stored as integer minor units to avoid floating-point errors.
/// The currency code is explicit so accounts can support multiple currencies.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Stable machine-readable account type, e.g. cash, bank, savings, credit.
  TextColumn get type => text().withLength(min: 1, max: 24)();

  /// Opening balance in the smallest unit of [currencyCode].
  IntColumn get openingBalanceMinor => integer()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
