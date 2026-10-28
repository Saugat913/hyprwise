import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

class ShiftRepository {
  ShiftRepository(this._db);

  final AppDatabase _db;

  Stream<List<Shift>> watchAll() =>
      (_db.select(_db.shifts)..orderBy([
        (s) => OrderingTerm.desc(s.startAt),
        (s) => OrderingTerm.desc(s.id),
      ])).watch();

  Future<int> add({
    required int jobId,
    required DateTime startAt,
    required ShiftStatus status,
    DateTime? endAt,
    int breakMinutes = 0,
    String? note,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
  }) => _db
      .into(_db.shifts)
      .insert(
        ShiftsCompanion.insert(
          jobId: jobId,
          startAt: startAt.millisecondsSinceEpoch,
          endAt: Value(endAt?.millisecondsSinceEpoch),
          breakMinutes: Value(breakMinutes),
          status: status.value,
          note: Value(normalizeText(note)),
          rateOverrideMinor: Value(rateOverrideMinor),
          overtimeThresholdMinutes: Value(overtimeThresholdMinutes),
          overtimeRateMinor: Value(overtimeRateMinor),
          longShiftAlertMinutes: Value(longShiftAlertMinutes),
          createdAt: nowMs(),
          updatedAt: nowMs(),
        ),
      );

  /// Clocks in now: creates an in-progress shift with no end time.
  Future<int> start({required int jobId}) => add(
    jobId: jobId,
    startAt: DateTime.now(),
    status: ShiftStatus.inProgress,
  );

  /// Clocks out an in-progress shift: sets the end time and completes it.
  Future<void> finish(int id, {int breakMinutes = 0, DateTime? endAt}) async {
    await (_db.update(_db.shifts)..where((s) => s.id.equals(id))).write(
      ShiftsCompanion(
        endAt: Value((endAt ?? DateTime.now()).millisecondsSinceEpoch),
        breakMinutes: Value(breakMinutes),
        status: Value(ShiftStatus.completed.value),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> update(
    int id, {
    int? jobId,
    DateTime? startAt,
    ShiftStatus? status,
    DateTime? endAt,
    int? breakMinutes,
    String? note,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
  }) async {
    await (_db.update(_db.shifts)..where((s) => s.id.equals(id))).write(
      ShiftsCompanion(
        jobId: jobId != null ? Value(jobId) : const Value.absent(),
        startAt: startAt != null ? Value(startAt.millisecondsSinceEpoch) : const Value.absent(),
        endAt: endAt != null ? Value(endAt.millisecondsSinceEpoch) : const Value.absent(),
        breakMinutes: breakMinutes != null ? Value(breakMinutes) : const Value.absent(),
        status: status != null ? Value(status.value) : const Value.absent(),
        note: note != null ? Value(normalizeText(note)) : const Value.absent(),
        rateOverrideMinor: rateOverrideMinor != null ? Value(rateOverrideMinor) : const Value.absent(),
        overtimeThresholdMinutes:
            overtimeThresholdMinutes != null ? Value(overtimeThresholdMinutes) : const Value.absent(),
        overtimeRateMinor: overtimeRateMinor != null ? Value(overtimeRateMinor) : const Value.absent(),
        longShiftAlertMinutes:
            longShiftAlertMinutes != null ? Value(longShiftAlertMinutes) : const Value.absent(),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> setStatus(int id, {required ShiftStatus status}) async {
    await (_db.update(_db.shifts)..where((s) => s.id.equals(id))).write(
      ShiftsCompanion(status: Value(status.value), updatedAt: Value(nowMs())),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.shiftBreaks)..where((b) => b.shiftId.equals(id))).go();
    await (_db.delete(_db.shifts)..where((s) => s.id.equals(id))).go();
  }

  Future<List<ShiftBreak>> breaksFor(int shiftId) =>
      (_db.select(_db.shiftBreaks)
            ..where((b) => b.shiftId.equals(shiftId))
            ..orderBy([(b) => OrderingTerm.asc(b.startAt)]))
          .get();

  /// Opens a break now and returns its id.
  Future<int> startBreak(int shiftId, DateTime at) => _db.into(_db.shiftBreaks).insert(
        ShiftBreaksCompanion.insert(shiftId: shiftId, startAt: at.millisecondsSinceEpoch),
      );

  Future<void> endBreak(int breakId, DateTime at) =>
      (_db.update(_db.shiftBreaks)..where((b) => b.id.equals(breakId)))
          .write(ShiftBreaksCompanion(endAt: Value(at.millisecondsSinceEpoch)));
}
