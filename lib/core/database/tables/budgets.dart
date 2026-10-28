import 'package:drift/drift.dart';

/// A monthly spending target. The subscription target is modelled as a budget
/// with [categoryKey] = 'subscriptions'; everything else maps to a spending
/// category key.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get categoryKey => text().withLength(min: 1, max: 40)();

  IntColumn get monthlyLimitMinor => integer()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

/// A user-defined automation. Rules never change data by themselves in this
/// version; they surface alerts and reminders derived from the same engines
/// that power forecasting.
class AlertRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// spending_threshold | goal_at_risk | low_balance | upcoming_payment
  TextColumn get type => text().withLength(min: 1, max: 32)();

  IntColumn get thresholdMinor => integer().nullable()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  TextColumn get categoryKey => text().nullable().withLength(max: 40)();

  IntColumn get goalId => integer().nullable()();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  IntColumn get lastTriggeredAt => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
