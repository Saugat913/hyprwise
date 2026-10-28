import 'package:drift/drift.dart';

/// A job with an hourly rate. Shifts belong to jobs and are turned into
/// earnings by the shift engine.
class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  TextColumn get employer => text().nullable().withLength(max: 80)();

  IntColumn get hourlyRateMinor => integer()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// Index into the categorical chart palette, for a stable per-job color.
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}

/// A work shift. Completed shifts count as earned income; scheduled shifts
/// feed forecasting as expected income.
class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get jobId => integer().references(Jobs, #id)();

  IntColumn get startAt => integer()();

  IntColumn get endAt => integer().nullable()();

  IntColumn get breakMinutes => integer().withDefault(const Constant(0))();

  /// scheduled | completed | cancelled
  TextColumn get status => text().withLength(min: 1, max: 12)();

  TextColumn get note => text().nullable().withLength(max: 500)();

  /// Rate override for this shift only; falls back to the job rate when null.
  IntColumn get rateOverrideMinor => integer().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
