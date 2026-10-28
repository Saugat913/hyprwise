import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

void main() {
  group('ShiftEarnings', () {
    const testJob = Job(
      id: 1,
      name: 'Barista',
      hourlyRateMinor: 3000, // $30.00 / hour
      currencyCode: 'AUD',
      colorIndex: 0,
      isActive: true,
      createdAt: 0,
      updatedAt: 0,
    );

    test('3-hour scheduled shift worked only 2 hours with 30 min break', () {
      final start = DateTime(2026, 10, 14, 9, 0);
      final end = DateTime(2026, 10, 14, 11, 0); // 2 hours worked = 120 min

      final shift = Shift(
        id: 10,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 30, // 30 min break -> 90 min worked
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, testJob);

      expect(earnings.workedMinutes, 90);
      expect(earnings.hours, 1.5);
      // 30.00 * 1.5 = 45.00 -> 4500 minor units
      expect(earnings.earningsMinor, 4500);
    });

    test('In-progress shift earns 0 until completed', () {
      final start = DateTime(2026, 10, 14, 9, 0);
      final shift = Shift(
        id: 11,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: null,
        breakMinutes: 0,
        status: ShiftStatus.inProgress.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, testJob);
      expect(earnings.workedMinutes, 0);
      expect(earnings.earningsMinor, 0);
    });
  });
}
