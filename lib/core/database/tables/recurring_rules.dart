import 'package:drift/drift.dart';

import 'accounts.dart';

/// Recurring financial events: salary, rent, subscriptions, bills.
///
/// [kind] is one of income, expense, bill or subscription. A recurring rule is
/// a template; the forecasting engine expands it into future occurrences
/// without writing each one to the transactions table.
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// income | expense | bill | subscription
  TextColumn get kind => text().withLength(min: 1, max: 16)();

  IntColumn get amountMinor => integer()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// Optional: many bills are paid from whichever account suits.
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  TextColumn get category => text().withLength(min: 1, max: 40)();

  /// daily | weekly | monthly | yearly
  TextColumn get frequency => text().withLength(min: 1, max: 12)();

  IntColumn get intervalCount => integer().withDefault(const Constant(1))();

  IntColumn get nextDueAt => integer()();

  IntColumn get endAt => integer().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get note => text().nullable().withLength(max: 500)();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
