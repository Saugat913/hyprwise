import 'package:drift/drift.dart';

/// A stored exchange rate. Rates are integers scaled by [rateScale] to avoid
/// floating point drift. Historical rates are preserved so past transactions
/// keep the rate that applied when they happened.
class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get baseCode => text().withLength(min: 3, max: 3)();

  TextColumn get quoteCode => text().withLength(min: 3, max: 3)();

  /// quote per 1 base, scaled by 1,000,000.
  IntColumn get rateScaled => integer()();

  IntColumn get asOf => integer()();

  /// manual | provider
  TextColumn get source => text().withDefault(const Constant('manual'))();

  IntColumn get createdAt => integer()();
}
