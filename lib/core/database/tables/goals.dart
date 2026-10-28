import 'package:drift/drift.dart';

import 'accounts.dart';

/// A financial goal such as a tuition target, emergency fund or a trip.
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  IntColumn get targetAmountMinor => integer()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// Deadline used by the forecasting engine to measure the safety margin.
  IntColumn get targetDate => integer().nullable()();

  /// An account whose balance counts toward this goal, when set.
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  /// low | normal | high
  TextColumn get priority => text().withDefault(const Constant('normal'))();

  TextColumn get note => text().nullable().withLength(max: 500)();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

/// A contribution made toward a goal. Contributions are additive history and
/// are never deleted by editing the goal.
class GoalContributions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get goalId => integer().references(Goals, #id)();

  IntColumn get amountMinor => integer()();

  IntColumn get occurredAt => integer()();

  TextColumn get note => text().nullable().withLength(max: 500)();

  IntColumn get createdAt => integer()();
}
