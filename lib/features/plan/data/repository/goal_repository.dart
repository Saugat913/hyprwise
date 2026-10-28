import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/plan/data/model/goals.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

/// Savings goals and the contributions made towards them.
class GoalRepository {
  GoalRepository(this._db);

  final AppDatabase _db;

  Stream<List<Goal>> watchGoals() =>
      (_db.select(_db.goals)..orderBy([
        (g) => OrderingTerm.asc(g.isArchived),
        (g) => OrderingTerm.asc(g.targetDate),
      ])).watch();

  Stream<List<GoalContribution>> watchContributions() =>
      (_db.select(_db.goalContributions)
        ..orderBy([(c) => OrderingTerm.desc(c.occurredAt)])).watch();

  Future<int> add({
    required String name,
    required int targetAmountMinor,
    required String currencyCode,
    DateTime? targetDate,
    int? accountId,
    GoalPriority priority = GoalPriority.normal,
    String? note,
  }) {
    _validate(name, targetAmountMinor);
    return _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            name: name.trim(),
            targetAmountMinor: targetAmountMinor,
            currencyCode: currencyCode.toUpperCase(),
            targetDate: Value(targetDate?.millisecondsSinceEpoch),
            accountId: Value(accountId),
            priority: Value(priority.value),
            note: Value(normalizeText(note)),
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Future<void> update(
    int id, {
    required String name,
    required int targetAmountMinor,
    required String currencyCode,
    DateTime? targetDate,
    int? accountId,
    GoalPriority priority = GoalPriority.normal,
    String? note,
  }) async {
    _validate(name, targetAmountMinor);
    await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(
        name: Value(name.trim()),
        targetAmountMinor: Value(targetAmountMinor),
        currencyCode: Value(currencyCode.toUpperCase()),
        targetDate: Value(targetDate?.millisecondsSinceEpoch),
        accountId: Value(accountId),
        priority: Value(priority.value),
        note: Value(normalizeText(note)),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> setArchived(int id, {required bool archived}) async {
    await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(
      GoalsCompanion(isArchived: Value(archived), updatedAt: Value(nowMs())),
    );
  }

  /// Returns the contribution id so the UI can Undo via [deleteContribution].
  Future<int> addContribution({
    required int goalId,
    required int amountMinor,
    String? note,
    DateTime? occurredAt,
  }) {
    if (amountMinor <= 0) throw ArgumentError('Amount must be positive.');
    return _db
        .into(_db.goalContributions)
        .insert(
          GoalContributionsCompanion.insert(
            goalId: goalId,
            amountMinor: amountMinor,
            occurredAt: (occurredAt ?? DateTime.now()).millisecondsSinceEpoch,
            note: Value(normalizeText(note)),
            createdAt: nowMs(),
          ),
        );
  }

  Future<void> deleteContribution(int id) =>
      (_db.delete(_db.goalContributions)..where((c) => c.id.equals(id))).go();

  void _validate(String name, int targetAmountMinor) {
    if (name.trim().isEmpty) throw ArgumentError('Name is required.');
    if (targetAmountMinor <= 0) {
      throw ArgumentError('Target must be positive.');
    }
  }
}
