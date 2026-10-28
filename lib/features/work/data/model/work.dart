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
/// Pay is based on worked minutes (elapsed minus break), never on the
/// scheduled length. Shifts that are in progress earn nothing yet.
class ShiftEarnings {
  const ShiftEarnings({
    required this.workedMinutes,
    required this.earningsMinor,
    required this.hourlyRateMinor,
  });

  final int workedMinutes;
  final int earningsMinor;
  final int hourlyRateMinor;

  double get hours => workedMinutes / 60;

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
    final earnings = (rate * worked / 60).round();
    return ShiftEarnings(
      workedMinutes: worked,
      earningsMinor: earnings,
      hourlyRateMinor: rate,
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
