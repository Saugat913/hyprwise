import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

void main() {
  group('R3: Second-Accurate Earnings Calculation (Tier 1 Feature Coverage)', () {
    const baseJob = Job(
      id: 1,
      name: 'Software Engineer',
      hourlyRateMinor: 3600, // $36.00 / hr -> 1 cent per second
      currencyCode: 'USD',
      colorIndex: 0,
      isActive: true,
      defaultBreakMinutes: 0,
      longShiftAlertMinutes: 480,
      createdAt: 0,
      updatedAt: 0,
    );

    test('T1.1: 1 hr 30 sec worked (3630s) prorates earnings down to the second', () {
      final earnings = ShiftEarnings.compute(
        workedSeconds: 3630,
        rateMinor: 3600,
      );

      expect(earnings.workedMinutes, equals(60));
      expect(earnings.workedSeconds, equals(3630));
      // 3600 * 3630 / 3600 = 3630 cents ($36.30)
      expect(earnings.earningsMinor, equals(3630));
      expect(earnings.regularEarningsMinor, equals(3630));
    });

    test('T1.2: Sub-minute shift duration (45 seconds) computes exact second prorated pay', () {
      final earnings = ShiftEarnings.compute(
        workedSeconds: 45,
        rateMinor: 3600,
      );

      expect(earnings.workedMinutes, equals(0));
      expect(earnings.workedSeconds, equals(45));
      // 3600 * 45 / 3600 = 45 cents ($0.45)
      expect(earnings.earningsMinor, equals(45));
    });

    test('T1.3: Overtime threshold with second accuracy (8 hours + 30 seconds overtime)', () {
      // 8 hours = 480 min = 28,800 sec; worked 28,830 sec
      final earnings = ShiftEarnings.compute(
        workedSeconds: 28830,
        rateMinor: 3600,
        overtimeThresholdMinutes: 480,
        overtimeRateMinor: 5400, // 1.5x overtime rate = $54.00/hr = 1.5 cents/sec
      );

      expect(earnings.regularMinutes, equals(480));
      expect(earnings.overtimeMinutes, equals(0)); // 30 sec < 1 min, but paid
      expect(earnings.regularEarningsMinor, equals(28800)); // 8 hr * $36
      // Overtime: (5400 * 30 / 3600).round() = 45 cents
      expect(earnings.overtimeEarningsMinor, equals(45));
      expect(earnings.earningsMinor, equals(28845));
    });

    test('T1.4: Rate override applied with second precision', () {
      final start = DateTime(2026, 10, 14, 10, 0, 0);
      final end = DateTime(2026, 10, 14, 11, 30, 45); // 1h 30m 45s = 5445s
      final shift = Shift(
        id: 101,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        rateOverrideMinor: 7200, // $72.00/hr = 2 cents/sec
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(5445));
      // 7200 * 5445 / 3600 = 10890 cents ($108.90)
      expect(earnings.earningsMinor, equals(10890));
    });

    test('T1.5: Unpaid break deducted down to exact seconds in forShift', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 10, 0, 15); // 3615 seconds elapsed
      final shift = Shift(
        id: 102,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 15, // 15 min break = 900 seconds
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      // Worked = 3615 - 900 = 2715 seconds
      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(2715));
      // 3600 * 2715 / 3600 = 2715 cents ($27.15)
      expect(earnings.earningsMinor, equals(2715));
      expect(shift.durationSeconds, equals(2715));
    });
  });

  group('R3: Second-Accurate Earnings Calculation (Tier 2 Boundary & Corner Cases)', () {
    const job = Job(
      id: 2,
      name: 'Retail Specialist',
      hourlyRateMinor: 3600, // $36.00/hr = 1 cent/sec
      currencyCode: 'AUD',
      colorIndex: 1,
      isActive: true,
      defaultBreakMinutes: 0,
      longShiftAlertMinutes: 480,
      createdAt: 0,
      updatedAt: 0,
    );

    test('T2.1: 0 worked seconds results in 0 earnings', () {
      final earnings = ShiftEarnings.compute(
        workedSeconds: 0,
        rateMinor: 3600,
      );
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.workedMinutes, equals(0));
      expect(earnings.earningsMinor, equals(0));
    });

    test('T2.2: 1 single second worked computes non-zero prorated payment', () {
      final earnings = ShiftEarnings.compute(
        workedSeconds: 1,
        rateMinor: 3600,
      );
      expect(earnings.workedSeconds, equals(1));
      // (3600 * 1 / 3600).round() = 1 cent
      expect(earnings.earningsMinor, equals(1));
    });

    test('T2.3: 59 seconds worked (boundary right before minute)', () {
      final earnings = ShiftEarnings.compute(
        workedSeconds: 59,
        rateMinor: 3600,
      );
      expect(earnings.workedSeconds, equals(59));
      expect(earnings.workedMinutes, equals(0));
      expect(earnings.earningsMinor, equals(59));
    });

    test('T2.4: 3599 seconds worked (boundary right before full hour)', () {
      final earnings = ShiftEarnings.compute(
        workedSeconds: 3599,
        rateMinor: 3600,
      );
      expect(earnings.workedSeconds, equals(3599));
      expect(earnings.workedMinutes, equals(59));
      expect(earnings.earningsMinor, equals(3599));
    });

    test('T2.5: Overnight shift spanning midnight with odd seconds', () {
      final start = DateTime(2026, 10, 14, 22, 0, 0);
      final end = DateTime(2026, 10, 15, 6, 0, 27); // 8 hours 27 seconds = 28,827s
      final shift = Shift(
        id: 205,
        jobId: 2,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 30, // 30 min break = 1800s
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      // Worked = 28,827 - 1800 = 27,027s
      final earnings = ShiftEarnings.forShift(shift, job);
      expect(earnings.workedSeconds, equals(27027));
      expect(earnings.earningsMinor, equals(27027));
      expect(shift.durationSeconds, equals(27027));
    });

    test('T2.6: Unpaid break duration exactly equal to shift length produces 0 earnings', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 9, 30, 0); // 30 min shift
      final shift = Shift(
        id: 206,
        jobId: 2,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 30, // 30 min break
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, job);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
    });

    test('T2.7: Unpaid break duration exceeding shift length is clamped to 0 (no negative earnings)', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 9, 20, 0); // 20 min elapsed
      final shift = Shift(
        id: 207,
        jobId: 2,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 45, // 45 min break > 20 min
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, job);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('T2.8: In-progress shift produces 0 earnings and 0 worked seconds', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final shift = Shift(
        id: 208,
        jobId: 2,
        startAt: start.millisecondsSinceEpoch,
        endAt: null,
        breakMinutes: 0,
        status: ShiftStatus.inProgress.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, job);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.workedMinutes, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('T2.9: Shift with negative elapsed time (end before start) safely clamps to 0', () {
      final start = DateTime(2026, 10, 14, 12, 0, 0);
      final end = DateTime(2026, 10, 14, 11, 0, 0); // Invalid clock skew
      final shift = Shift(
        id: 209,
        jobId: 2,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, job);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('T2.10: High earning rate (\$1,000/hr) calculates with full precision without overflow', () {
      // 100,000 minor units/hr = $1,000.00/hr
      // 7200 seconds (2 hours) worked + 15 seconds
      final earnings = ShiftEarnings.compute(
        workedSeconds: 7215,
        rateMinor: 100000,
      );

      expect(earnings.workedSeconds, equals(7215));
      // (100000 * 7215 / 3600).round() = 200417 cents ($2,004.17)
      expect(earnings.earningsMinor, equals(200417));
    });
  });
}
