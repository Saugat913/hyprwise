import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/money/data/model/recurring.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

/// Recurring income, bills and subscriptions.
class RecurringRepository {
  RecurringRepository(this._db);

  final AppDatabase _db;

  Stream<List<RecurringRule>> watchAll() =>
      (_db.select(_db.recurringRules)
        ..orderBy([(r) => OrderingTerm.asc(r.nextDueAt)])).watch();

  Future<int> add({
    required String name,
    required RecurringKind kind,
    required int amountMinor,
    required String currencyCode,
    required String category,
    required RecurrenceFrequency frequency,
    required DateTime nextDueAt,
    int intervalCount = 1,
    int? accountId,
    DateTime? endAt,
    String? note,
  }) {
    _validate(name, amountMinor);
    return _db
        .into(_db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            name: name.trim(),
            kind: kind.value,
            amountMinor: amountMinor,
            currencyCode: currencyCode.toUpperCase(),
            accountId: Value(accountId),
            category: category,
            frequency: frequency.value,
            intervalCount: Value(intervalCount),
            nextDueAt: nextDueAt.millisecondsSinceEpoch,
            endAt: Value(endAt?.millisecondsSinceEpoch),
            note: Value(normalizeText(note)),
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Future<void> update(
    int id, {
    required String name,
    required RecurringKind kind,
    required int amountMinor,
    required String currencyCode,
    required String category,
    required RecurrenceFrequency frequency,
    required DateTime nextDueAt,
    int intervalCount = 1,
    int? accountId,
    DateTime? endAt,
    String? note,
  }) async {
    _validate(name, amountMinor);
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        name: Value(name.trim()),
        kind: Value(kind.value),
        amountMinor: Value(amountMinor),
        currencyCode: Value(currencyCode.toUpperCase()),
        accountId: Value(accountId),
        category: Value(category),
        frequency: Value(frequency.value),
        intervalCount: Value(intervalCount),
        nextDueAt: Value(nextDueAt.millisecondsSinceEpoch),
        endAt: Value(endAt?.millisecondsSinceEpoch),
        note: Value(normalizeText(note)),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> setActive(int id, {required bool active}) async {
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        isActive: Value(active),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.recurringRules)..where((r) => r.id.equals(id))).go();

  void _validate(String name, int amountMinor) {
    if (amountMinor <= 0) throw ArgumentError('Amount must be positive.');
    if (name.trim().isEmpty) throw ArgumentError('Name is required.');
  }
}
