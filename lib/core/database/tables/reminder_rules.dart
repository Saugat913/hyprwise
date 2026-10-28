import 'package:drift/drift.dart';

/// User-defined reminder rules, scheduled as local notifications.
///
/// [type] is shift | bill | debt | custom. [offsetMinutes] is how long before
/// the event the reminder fires. [timeOfDayMinutes] (minutes since midnight)
/// pins the time for bill/debt/custom rules. [repeatDays] is a weekday bitmask
/// (bit 0 = Monday ... bit 6 = Sunday); 0 means no weekday restriction.
class ReminderRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text().withLength(min: 1, max: 16)();

  TextColumn get title => text().withDefault(const Constant('')).withLength(max: 80)();

  IntColumn get offsetMinutes => integer().withDefault(const Constant(0))();

  IntColumn get timeOfDayMinutes => integer().nullable()();

  IntColumn get repeatDays => integer().withDefault(const Constant(0))();

  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
