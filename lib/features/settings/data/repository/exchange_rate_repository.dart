import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

/// Manually entered exchange rates.
class ExchangeRateRepository {
  ExchangeRateRepository(this._db);

  final AppDatabase _db;

  Stream<List<ExchangeRate>> watchAll() =>
      (_db.select(_db.exchangeRates)
        ..orderBy([(r) => OrderingTerm.desc(r.asOf)])).watch();

  /// [rate] is the amount of [quoteCode] per one [baseCode].
  Future<int> add({
    required String baseCode,
    required String quoteCode,
    required double rate,
    DateTime? asOf,
  }) {
    if (rate <= 0) throw ArgumentError('Rate must be positive.');
    return _db
        .into(_db.exchangeRates)
        .insert(
          ExchangeRatesCompanion.insert(
            baseCode: baseCode.toUpperCase(),
            quoteCode: quoteCode.toUpperCase(),
            rateScaled: (rate * ExchangeRateQuote.scale).round(),
            asOf: (asOf ?? DateTime.now()).millisecondsSinceEpoch,
            createdAt: nowMs(),
          ),
        );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.exchangeRates)..where((r) => r.id.equals(id))).go();
}
