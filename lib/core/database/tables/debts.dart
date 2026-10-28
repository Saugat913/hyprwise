import 'package:drift/drift.dart';
import 'accounts.dart';

/// Tracks money lent to others or borrowed from others (debts & loans / IOUs).
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Person or entity (e.g. 'Sarah', 'Uncle Bob', 'Landlord').
  TextColumn get personName => text().withLength(min: 1, max: 80)();

  /// 'lent' (I gave money, they owe me) or 'borrowed' (they gave money, I owe them).
  TextColumn get type => text().withLength(min: 1, max: 12)();

  IntColumn get amountMinor => integer()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// Optional expected return/settlement date.
  IntColumn get dueDate => integer().nullable()();

  TextColumn get note => text().nullable().withLength(max: 500)();

  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();

  IntColumn get settledAt => integer().nullable()();

  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
