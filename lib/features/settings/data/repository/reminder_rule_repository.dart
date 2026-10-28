import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';

enum ReminderType {
  shift('shift'),
  bill('bill'),
  debt('debt'),
  custom('custom');

  const ReminderType(this.value);

  final String value;

  static ReminderType fromValue(String value) =>
      ReminderType.values.firstWhere((t) => t.value == value, orElse: () => ReminderType.custom);
}

/// Drift access for user-defined reminder rules.
class ReminderRuleRepository {
  ReminderRuleRepository(this._db);

  final AppDatabase _db;

  Stream<List<ReminderRule>> watchAll() =>
      (_db.select(_db.reminderRules)..orderBy([(r) => OrderingTerm.asc(r.id)])).watch();

  Future<int> add({
    required ReminderType type,
    String title = '',
    int offsetMinutes = 0,
    int? timeOfDayMinutes,
    int repeatDays = 0,
    bool isEnabled = true,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.into(_db.reminderRules).insert(
          ReminderRulesCompanion.insert(
            type: type.value,
            title: Value(title.trim()),
            offsetMinutes: Value(offsetMinutes),
            timeOfDayMinutes: Value(timeOfDayMinutes),
            repeatDays: Value(repeatDays),
            isEnabled: Value(isEnabled),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(
    int id, {
    required ReminderType type,
    String title = '',
    int offsetMinutes = 0,
    int? timeOfDayMinutes,
    int repeatDays = 0,
    bool isEnabled = true,
  }) async {
    await (_db.update(_db.reminderRules)..where((r) => r.id.equals(id))).write(
      ReminderRulesCompanion(
        type: Value(type.value),
        title: Value(title.trim()),
        offsetMinutes: Value(offsetMinutes),
        timeOfDayMinutes: Value(timeOfDayMinutes),
        repeatDays: Value(repeatDays),
        isEnabled: Value(isEnabled),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setEnabled(int id, bool enabled) async {
    await (_db.update(_db.reminderRules)..where((r) => r.id.equals(id))).write(
      ReminderRulesCompanion(
        isEnabled: Value(enabled),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> delete(int id) => (_db.delete(_db.reminderRules)..where((r) => r.id.equals(id))).go();
}
