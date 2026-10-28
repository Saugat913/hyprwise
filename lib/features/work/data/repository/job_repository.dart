import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

class JobRepository {
  JobRepository(this._db);

  final AppDatabase _db;

  Stream<List<Job>> watchAll() =>
      (_db.select(_db.jobs)
        ..orderBy([(j) => OrderingTerm.asc(j.name)])).watch();

  Future<int> add({
    required String name,
    required int hourlyRateMinor,
    required String currencyCode,
    String? employer,
    int colorIndex = 0,
  }) {
    _validate(name, hourlyRateMinor);
    return _db
        .into(_db.jobs)
        .insert(
          JobsCompanion.insert(
            name: name.trim(),
            employer: Value(normalizeText(employer)),
            hourlyRateMinor: hourlyRateMinor,
            currencyCode: currencyCode.toUpperCase(),
            colorIndex: Value(colorIndex),
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Future<void> update(
    int id, {
    required String name,
    required int hourlyRateMinor,
    required String currencyCode,
    String? employer,
    int colorIndex = 0,
  }) async {
    _validate(name, hourlyRateMinor);
    await (_db.update(_db.jobs)..where((j) => j.id.equals(id))).write(
      JobsCompanion(
        name: Value(name.trim()),
        employer: Value(normalizeText(employer)),
        hourlyRateMinor: Value(hourlyRateMinor),
        currencyCode: Value(currencyCode.toUpperCase()),
        colorIndex: Value(colorIndex),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> setActive(int id, {required bool active}) async {
    await (_db.update(_db.jobs)..where((j) => j.id.equals(id))).write(
      JobsCompanion(isActive: Value(active), updatedAt: Value(nowMs())),
    );
  }

  void _validate(String name, int hourlyRateMinor) {
    if (name.trim().isEmpty) throw ArgumentError('Name is required.');
    if (hourlyRateMinor <= 0) throw ArgumentError('Rate must be positive.');
  }
}
