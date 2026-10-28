import 'package:finance_tracker/core/database/app_database.dart';

/// Lifecycle of a shift. Completed shifts are earned income; scheduled shifts
/// are expected income for forecasting; in-progress shifts (clocked in, no end
/// time yet) earn nothing until they are completed.
enum ShiftStatus {
  scheduled('scheduled', 'Scheduled'),
  inProgress('in_progress', 'In progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const ShiftStatus(this.value, this.label);

  final String value;
  final String label;

  static ShiftStatus fromValue(String value) => ShiftStatus.values.firstWhere(
    (status) => status.value == value,
    orElse: () => ShiftStatus.scheduled,
  );
}

/// The computed result for a shift: how long it ran and what it earned.
/// Pay is based on worked time (elapsed minus break), never on the scheduled
/// length. Minutes after the overtime threshold are paid at the overtime rate.
/// Shifts that are in progress earn nothing yet.
class ShiftEarnings {
  const ShiftEarnings({
    required this.workedMinutes,
    required this.earningsMinor,
    required this.hourlyRateMinor,
    this.regularMinutes = 0,
    this.overtimeMinutes = 0,
    this.overtimeRateMinor = 0,
    this.regularEarningsMinor = 0,
    this.overtimeEarningsMinor = 0,
  });

  final int workedMinutes;
  final int earningsMinor;
  final int hourlyRateMinor;
  final int regularMinutes;
  final int overtimeMinutes;
  final int overtimeRateMinor;
  final int regularEarningsMinor;
  final int overtimeEarningsMinor;

  double get hours => workedMinutes / 60;

  bool get hasOvertime => overtimeMinutes > 0;

  /// Splits [workedSeconds] into regular and overtime pay. Second precision
  /// lets live earnings tick every second.
  static ShiftEarnings compute({
    required int workedSeconds,
    required int rateMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
  }) {
    final worked = workedSeconds < 0 ? 0 : workedSeconds;
    final hasOt = overtimeThresholdMinutes != null && overtimeRateMinor != null;
    final thresholdSec = hasOt ? overtimeThresholdMinutes * 60 : worked;
    final regularSec = worked < thresholdSec ? worked : thresholdSec;
    final otSec = worked - regularSec;
    final regularPay = (rateMinor * regularSec / 3600).round();
    final otPay = hasOt ? (overtimeRateMinor * otSec / 3600).round() : 0;
    return ShiftEarnings(
      workedMinutes: worked ~/ 60,
      earningsMinor: regularPay + otPay,
      hourlyRateMinor: rateMinor,
      regularMinutes: regularSec ~/ 60,
      overtimeMinutes: otSec ~/ 60,
      overtimeRateMinor: hasOt ? overtimeRateMinor : 0,
      regularEarningsMinor: regularPay,
      overtimeEarningsMinor: otPay,
    );
  }

  static ShiftEarnings forShift(Shift shift, Job job) {
    final rate = shift.rateOverrideMinor ?? job.hourlyRateMinor;
    if (shift.endAt == null || shift.status == ShiftStatus.inProgress.value) {
      return ShiftEarnings(
        workedMinutes: 0,
        earningsMinor: 0,
        hourlyRateMinor: rate,
      );
    }
    final start = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
    final end = DateTime.fromMillisecondsSinceEpoch(shift.endAt!);
    final elapsedMinutes = end.difference(start).inMinutes - shift.breakMinutes;
    final worked = elapsedMinutes < 0 ? 0 : elapsedMinutes;
    return compute(
      workedSeconds: worked * 60,
      rateMinor: rate,
      overtimeThresholdMinutes: shift.overtimeThresholdMinutes,
      overtimeRateMinor: shift.overtimeRateMinor,
    );
  }
}

extension ShiftX on Shift {
  int get durationMinutes {
    if (endAt == null || status == ShiftStatus.inProgress.value) return 0;
    final diff = ((endAt! - startAt) ~/ 60000) - breakMinutes;
    return diff < 0 ? 0 : diff;
  }

  bool get isInProgress => status == ShiftStatus.inProgress.value;
}

extension JobX on Job {
  bool get longShiftAlertEnabled => longShiftAlertMinutes > 0;
}

/// Break segments of a shift, ordered by start, with total duration helpers.
class ShiftTimeline {
  const ShiftTimeline(this.breaks);

  final List<ShiftBreak> breaks;

  static int breakMinutesOf(ShiftBreak b, {DateTime? now}) {
    final end = b.endAt ?? (now ?? DateTime.now()).millisecondsSinceEpoch;
    final diff = (end - b.startAt) ~/ 60000;
    return diff < 0 ? 0 : diff;
  }

  int get trackedBreakMinutes => breaks.fold(0, (sum, b) => sum + breakMinutesOf(b));
}
