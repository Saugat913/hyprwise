import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

/// Repository for tracking loans, debts, and IOUs.
class DebtRepository {
  DebtRepository(this._db);

  final AppDatabase _db;

  Stream<List<Debt>> watchAll() => (_db.select(_db.debts)
    ..orderBy([
      (d) => OrderingTerm.asc(d.isSettled),
      (d) => OrderingTerm.asc(d.dueDate),
      (d) => OrderingTerm.desc(d.createdAt),
    ]))
      .watch();

  Future<List<Debt>> getAll() => (_db.select(_db.debts)
    ..orderBy([
      (d) => OrderingTerm.asc(d.isSettled),
      (d) => OrderingTerm.asc(d.dueDate),
      (d) => OrderingTerm.desc(d.createdAt),
    ]))
      .get();

  Future<int> add({
    required String personName,
    required DebtType type,
    required int amountMinor,
    required String currencyCode,
    DateTime? dueDate,
    String? note,
    int? accountId,
  }) {
    if (personName.trim().isEmpty) {
      throw ArgumentError.value(personName, 'personName', 'Person name cannot be empty');
    }
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'Amount must be positive');
    }
    return _db.into(_db.debts).insert(
      DebtsCompanion.insert(
        personName: personName.trim(),
        type: type.value,
        amountMinor: amountMinor,
        currencyCode: currencyCode.toUpperCase(),
        dueDate: Value(dueDate?.millisecondsSinceEpoch),
        note: Value(normalizeText(note)),
        accountId: Value(accountId),
        createdAt: nowMs(),
        updatedAt: nowMs(),
      ),
    );
  }

  Future<void> settle(int id) async {
    await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        isSettled: const Value(true),
        settledAt: Value(nowMs()),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> unsettle(int id) async {
    await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
      const DebtsCompanion(
        isSettled: Value(false),
        settledAt: Value(null),
      ),
    );
  }

  Future<void> update(
    int id, {
    required String personName,
    required DebtType type,
    required int amountMinor,
    required String currencyCode,
    DateTime? dueDate,
    String? note,
    int? accountId,
  }) async {
    if (personName.trim().isEmpty) {
      throw ArgumentError.value(personName, 'personName', 'Person name cannot be empty');
    }
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'Amount must be positive');
    }
    await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        personName: Value(personName.trim()),
        type: Value(type.value),
        amountMinor: Value(amountMinor),
        currencyCode: Value(currencyCode.toUpperCase()),
        dueDate: Value(dueDate?.millisecondsSinceEpoch),
        note: Value(normalizeText(note)),
        accountId: Value(accountId),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.debts)..where((d) => d.id.equals(id))).go();
}
