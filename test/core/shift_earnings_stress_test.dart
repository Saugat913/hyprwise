import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

void main() {
  const baseJob = Job(
    id: 1,
    name: 'Consultant',
    hourlyRateMinor: 3600, // $36.00 / hr -> exactly 1 cent per second
    currencyCode: 'USD',
    colorIndex: 0,
    isActive: true,
    defaultBreakMinutes: 0,
    longShiftAlertMinutes: 480,
    createdAt: 0,
    updatedAt: 0,
  );

  group('Vector 1: Discrete Second Boundaries & Odd Seconds Stress Tests', () {
    test('Boundary: 0 seconds worked yields 0 earnings and 0 minutes', () {
      final res = ShiftEarnings.compute(workedSeconds: 0, rateMinor: 3600);
      expect(res.workedSeconds, equals(0));
      expect(res.workedMinutes, equals(0));
      expect(res.earningsMinor, equals(0));
      expect(res.regularEarningsMinor, equals(0));
      expect(res.overtimeEarningsMinor, equals(0));
    });

    test('Boundary: 1 single second worked at various rates evaluates exact rounding', () {
      // At $36.00/hr (3600 cents): 3600 * 1 / 3600 = 1.0 -> 1 cent
      final res36 = ShiftEarnings.compute(workedSeconds: 1, rateMinor: 3600);
      expect(res36.workedSeconds, equals(1));
      expect(res36.workedMinutes, equals(0));
      expect(res36.earningsMinor, equals(1));

      // At $72.00/hr (7200 cents): 7200 * 1 / 3600 = 2.0 -> 2 cents
      final res72 = ShiftEarnings.compute(workedSeconds: 1, rateMinor: 7200);
      expect(res72.workedSeconds, equals(1));
      expect(res72.earningsMinor, equals(2));

      // At $18.00/hr (1800 cents): 1800 * 1 / 3600 = 0.5 -> rounds up to 1 cent
      final res18 = ShiftEarnings.compute(workedSeconds: 1, rateMinor: 1800);
      expect(res18.workedSeconds, equals(1));
      expect(res18.earningsMinor, equals(1));

      // At $17.99/hr (1799 cents): 1799 * 1 / 3600 = 0.49972 -> rounds to 0 cents
      final res1799 = ShiftEarnings.compute(workedSeconds: 1, rateMinor: 1799);
      expect(res1799.workedSeconds, equals(1));
      expect(res1799.earningsMinor, equals(0));

      // At $5.25/hr (525 cents): 525 * 1 / 3600 = 0.1458 -> rounds to 0 cents
      final res525 = ShiftEarnings.compute(workedSeconds: 1, rateMinor: 525);
      expect(res525.workedSeconds, equals(1));
      expect(res525.earningsMinor, equals(0));
    });

    test('Odd seconds (17s, 43s, 73s, 137s) prorate without truncation', () {
      // 17 seconds at $120.50/hr (12050 cents):
      // 12050 * 17 / 3600 = 204850 / 3600 = 56.90277... -> 57 cents
      final res17 = ShiftEarnings.compute(workedSeconds: 17, rateMinor: 12050);
      expect(res17.workedSeconds, equals(17));
      expect(res17.workedMinutes, equals(0));
      expect(res17.earningsMinor, equals(57));

      // 43 seconds at $5.25/hr (525 cents):
      // 525 * 43 / 3600 = 22575 / 3600 = 6.27083... -> 6 cents
      final res43 = ShiftEarnings.compute(workedSeconds: 43, rateMinor: 525);
      expect(res43.workedSeconds, equals(43));
      expect(res43.workedMinutes, equals(0));
      expect(res43.earningsMinor, equals(6));

      // 73 seconds (1m 13s) at $24.75/hr (2475 cents):
      // 2475 * 73 / 3600 = 180675 / 3600 = 50.1875 -> 50 cents
      final res73 = ShiftEarnings.compute(workedSeconds: 73, rateMinor: 2475);
      expect(res73.workedSeconds, equals(73));
      expect(res73.workedMinutes, equals(1));
      expect(res73.earningsMinor, equals(50));

      // 137 seconds (2m 17s) at $33.33/hr (3333 cents):
      // 3333 * 137 / 3600 = 456621 / 3600 = 126.83916... -> 127 cents
      final res137 = ShiftEarnings.compute(workedSeconds: 137, rateMinor: 3333);
      expect(res137.workedSeconds, equals(137));
      expect(res137.workedMinutes, equals(2));
      expect(res137.earningsMinor, equals(127));
    });

    test('Minute boundaries: 58s, 59s, 60s, 61s transition correctly', () {
      // 58s
      final res58 = ShiftEarnings.compute(workedSeconds: 58, rateMinor: 3600);
      expect(res58.workedSeconds, equals(58));
      expect(res58.workedMinutes, equals(0));
      expect(res58.earningsMinor, equals(58));

      // 59s
      final res59 = ShiftEarnings.compute(workedSeconds: 59, rateMinor: 3600);
      expect(res59.workedSeconds, equals(59));
      expect(res59.workedMinutes, equals(0));
      expect(res59.earningsMinor, equals(59));

      // 60s (exactly 1 minute)
      final res60 = ShiftEarnings.compute(workedSeconds: 60, rateMinor: 3600);
      expect(res60.workedSeconds, equals(60));
      expect(res60.workedMinutes, equals(1));
      expect(res60.earningsMinor, equals(60));

      // 61s
      final res61 = ShiftEarnings.compute(workedSeconds: 61, rateMinor: 3600);
      expect(res61.workedSeconds, equals(61));
      expect(res61.workedMinutes, equals(1));
      expect(res61.earningsMinor, equals(61));
    });

    test('Hour boundaries: 3598s, 3599s, 3600s, 3601s transition correctly', () {
      // 3598s
      final res3598 = ShiftEarnings.compute(workedSeconds: 3598, rateMinor: 3600);
      expect(res3598.workedSeconds, equals(3598));
      expect(res3598.workedMinutes, equals(59));
      expect(res3598.earningsMinor, equals(3598));

      // 3599s (59 min 59 sec)
      final res3599 = ShiftEarnings.compute(workedSeconds: 3599, rateMinor: 3600);
      expect(res3599.workedSeconds, equals(3599));
      expect(res3599.workedMinutes, equals(59));
      expect(res3599.earningsMinor, equals(3599));

      // 3600s (exactly 1 hour)
      final res3600 = ShiftEarnings.compute(workedSeconds: 3600, rateMinor: 3600);
      expect(res3600.workedSeconds, equals(3600));
      expect(res3600.workedMinutes, equals(60));
      expect(res3600.earningsMinor, equals(3600));

      // 3601s (1 hour 1 sec)
      final res3601 = ShiftEarnings.compute(workedSeconds: 3601, rateMinor: 3600);
      expect(res3601.workedSeconds, equals(3601));
      expect(res3601.workedMinutes, equals(60));
      expect(res3601.earningsMinor, equals(3601));
    });

    test('Automated Randomized Property Test: 1,000 cases match exact mathematical oracle', () {
      final random = Random(42);
      for (var i = 0; i < 1000; i++) {
        // Random seconds between 0 and 86400 (24 hours)
        final seconds = random.nextInt(86401);
        // Random rate between 1 and 200,000 cents ($2,000/hr)
        final rate = 1 + random.nextInt(200000);

        final earnings = ShiftEarnings.compute(workedSeconds: seconds, rateMinor: rate);
        final expectedPay = (rate * seconds / 3600.0).round();

        expect(earnings.workedSeconds, equals(seconds));
        expect(earnings.workedMinutes, equals(seconds ~/ 60));
        expect(earnings.earningsMinor, equals(expectedPay));
        expect(earnings.regularEarningsMinor, equals(expectedPay));
        expect(earnings.overtimeEarningsMinor, equals(0));
      }
    });
  });

  group('Vector 2: Extreme Hourly Rates & Currencies Stress Tests', () {
    test('Zero rate (\$0.00/hr) yields 0 earnings for any duration', () {
      expect(ShiftEarnings.compute(workedSeconds: 1, rateMinor: 0).earningsMinor, equals(0));
      expect(ShiftEarnings.compute(workedSeconds: 3600, rateMinor: 0).earningsMinor, equals(0));
      expect(ShiftEarnings.compute(workedSeconds: 86400, rateMinor: 0).earningsMinor, equals(0));
    });

    test('Micro-rate (\$0.01/hr = 1 minor unit/hr)', () {
      // 1800 seconds = 0.5 hours -> 1 * 1800 / 3600 = 0.5 -> 1 cent
      final resHalf = ShiftEarnings.compute(workedSeconds: 1800, rateMinor: 1);
      expect(resHalf.earningsMinor, equals(1));

      // 1799 seconds -> 1799 / 3600 = 0.4997 -> 0 cents
      final resUnder = ShiftEarnings.compute(workedSeconds: 1799, rateMinor: 1);
      expect(resUnder.earningsMinor, equals(0));

      // 3600 seconds -> 1 cent
      final resHour = ShiftEarnings.compute(workedSeconds: 3600, rateMinor: 1);
      expect(resHour.earningsMinor, equals(1));
    });

    test('Standard and statutory minimum wage rates', () {
      // US federal minimum wage: $7.25/hr (725 cents)
      // 2h 15m 30s = 8130 seconds
      // 725 * 8130 / 3600 = 5894250 / 3600 = 1637.2916... -> 1637 cents ($16.37)
      final usMin = ShiftEarnings.compute(workedSeconds: 8130, rateMinor: 725);
      expect(usMin.earningsMinor, equals(1637));

      // AU minimum wage: $23.23/hr (2323 cents)
      // 4h 32m 17s = 16337 seconds
      // 2323 * 16337 / 3600 = 37950851 / 3600 = 10541.903... -> 10542 cents ($105.42)
      final auMin = ShiftEarnings.compute(workedSeconds: 16337, rateMinor: 2323);
      expect(auMin.earningsMinor, equals(10542));
    });

    test('High consulting / executive rates: \$120.50, \$1,500.00, \$10,000.00', () {
      // $120.50/hr (12050 cents) for 3h 12m 45s (11565s)
      // 12050 * 11565 / 3600 = 139358250 / 3600 = 38710.625 -> 38711 cents ($387.11)
      final res120 = ShiftEarnings.compute(workedSeconds: 11565, rateMinor: 12050);
      expect(res120.earningsMinor, equals(38711));

      // $1,500.00/hr (150000 cents) for 1h 45m 22s (6322s)
      // 150000 * 6322 / 3600 = 948300000 / 3600 = 263416.666... -> 263417 cents ($2,634.17)
      final res1500 = ShiftEarnings.compute(workedSeconds: 6322, rateMinor: 150000);
      expect(res1500.earningsMinor, equals(263417));

      // $10,000.00/hr (1,000,000 cents) for 10s
      // 1000000 * 10 / 3600 = 2777.777... -> 2778 cents ($27.78)
      final res10k = ShiftEarnings.compute(workedSeconds: 10, rateMinor: 1000000);
      expect(res10k.earningsMinor, equals(2778));
    });

    test('Astronomical rate (\$1,000,000.00/hr = 100,000,000 minor) maintains precision', () {
      // 3600 seconds -> 100,000,000 cents
      final res1m = ShiftEarnings.compute(workedSeconds: 3600, rateMinor: 100000000);
      expect(res1m.earningsMinor, equals(100000000));

      // 1 second -> (100000000 * 1 / 3600).round() = 27778 cents ($277.78)
      final res1m1s = ShiftEarnings.compute(workedSeconds: 1, rateMinor: 100000000);
      expect(res1m1s.earningsMinor, equals(27778));
    });
  });

  group('Vector 3: Overtime Second-Precision & Threshold Boundaries', () {
    const rate = 3600; // $36.00/hr regular ($0.01/s)
    const otRate = 5400; // $54.00/hr 1.5x overtime ($0.015/s)
    const thresholdMin = 480; // 8 hours = 28,800 seconds

    test('Threshold T (28,800s): exact match, 0 overtime', () {
      final res = ShiftEarnings.compute(
        workedSeconds: 28800,
        rateMinor: rate,
        overtimeThresholdMinutes: thresholdMin,
        overtimeRateMinor: otRate,
      );
      expect(res.regularMinutes, equals(480));
      expect(res.overtimeMinutes, equals(0));
      expect(res.hasOvertime, isFalse);
      expect(res.regularEarningsMinor, equals(28800));
      expect(res.overtimeEarningsMinor, equals(0));
      expect(res.earningsMinor, equals(28800));
    });

    test('Threshold T-1s (28,799s): 1 second before threshold, 0 overtime', () {
      final res = ShiftEarnings.compute(
        workedSeconds: 28799,
        rateMinor: rate,
        overtimeThresholdMinutes: thresholdMin,
        overtimeRateMinor: otRate,
      );
      expect(res.regularMinutes, equals(479));
      expect(res.overtimeMinutes, equals(0));
      expect(res.hasOvertime, isFalse);
      expect(res.regularEarningsMinor, equals(28799));
      expect(res.overtimeEarningsMinor, equals(0));
      expect(res.earningsMinor, equals(28799));
    });

    test('Threshold T+1s (28,801s): exactly 1 second overtime is paid prorated', () {
      final res = ShiftEarnings.compute(
        workedSeconds: 28801,
        rateMinor: rate,
        overtimeThresholdMinutes: thresholdMin,
        overtimeRateMinor: otRate,
      );
      expect(res.regularMinutes, equals(480));
      expect(res.overtimeMinutes, equals(0)); // 1 sec < 1 minute
      expect(res.hasOvertime, isFalse); // overtimeMinutes is 0, but overtime earnings exist!
      expect(res.regularEarningsMinor, equals(28800));
      // Overtime: (5400 * 1 / 3600).round() = 1.5 -> rounds to 2 cents
      expect(res.overtimeEarningsMinor, equals(2));
      expect(res.earningsMinor, equals(28802));
    });

    test('Threshold T+59s (28,859s): 59 seconds overtime', () {
      final res = ShiftEarnings.compute(
        workedSeconds: 28859,
        rateMinor: rate,
        overtimeThresholdMinutes: thresholdMin,
        overtimeRateMinor: otRate,
      );
      expect(res.regularMinutes, equals(480));
      expect(res.overtimeMinutes, equals(0));
      expect(res.regularEarningsMinor, equals(28800));
      // Overtime: (5400 * 59 / 3600).round() = (318600 / 3600).round() = 88.5 -> 89 cents
      expect(res.overtimeEarningsMinor, equals(89));
      expect(res.earningsMinor, equals(28889));
    });

    test('Threshold T+60s (28,860s): exactly 1 minute overtime', () {
      final res = ShiftEarnings.compute(
        workedSeconds: 28860,
        rateMinor: rate,
        overtimeThresholdMinutes: thresholdMin,
        overtimeRateMinor: otRate,
      );
      expect(res.regularMinutes, equals(480));
      expect(res.overtimeMinutes, equals(1));
      expect(res.hasOvertime, isTrue);
      expect(res.regularEarningsMinor, equals(28800));
      // Overtime: (5400 * 60 / 3600).round() = 90 cents
      expect(res.overtimeEarningsMinor, equals(90));
      expect(res.earningsMinor, equals(28890));
    });

    test('Overtime threshold = 0 minutes makes every second overtime', () {
      final res = ShiftEarnings.compute(
        workedSeconds: 120,
        rateMinor: rate,
        overtimeThresholdMinutes: 0,
        overtimeRateMinor: otRate,
      );
      expect(res.regularMinutes, equals(0));
      expect(res.overtimeMinutes, equals(2));
      expect(res.regularEarningsMinor, equals(0));
      // 5400 * 120 / 3600 = 180 cents ($1.80)
      expect(res.overtimeEarningsMinor, equals(180));
      expect(res.earningsMinor, equals(180));
    });

    test('Overtime threshold greater than worked time produces 0 overtime', () {
      final res = ShiftEarnings.compute(
        workedSeconds: 3600, // 1 hour
        rateMinor: rate,
        overtimeThresholdMinutes: 480, // 8 hours
        overtimeRateMinor: otRate,
      );
      expect(res.regularMinutes, equals(60));
      expect(res.overtimeMinutes, equals(0));
      expect(res.regularEarningsMinor, equals(3600));
      expect(res.overtimeEarningsMinor, equals(0));
      expect(res.earningsMinor, equals(3600));
    });

    test('Partial Overtime configurations fall back to regular pay gracefully', () {
      // Overtime threshold set, but overtime rate is null
      final resNoRate = ShiftEarnings.compute(
        workedSeconds: 36000,
        rateMinor: rate,
        overtimeThresholdMinutes: 480,
        overtimeRateMinor: null,
      );
      expect(resNoRate.regularMinutes, equals(600));
      expect(resNoRate.overtimeMinutes, equals(0));
      expect(resNoRate.earningsMinor, equals(36000));

      // Overtime rate set, but threshold is null
      final resNoThresh = ShiftEarnings.compute(
        workedSeconds: 36000,
        rateMinor: rate,
        overtimeThresholdMinutes: null,
        overtimeRateMinor: 5400,
      );
      expect(resNoThresh.regularMinutes, equals(600));
      expect(resNoThresh.overtimeMinutes, equals(0));
      expect(resNoThresh.earningsMinor, equals(36000));
    });

    test('Overtime with break deduction: break absorbs clock time before overtime', () {
      // Total elapsed clock time: 9 hours 0 min 15 sec = 32,415 seconds
      // Unpaid break: 60 minutes = 3,600 seconds
      // Net worked: 32,415 - 3,600 = 28,815 seconds (8h 0m 15s)
      // Threshold: 8 hours (28,800 seconds)
      // Regular: 28,800s ($288.00), Overtime: 15s (5400 * 15 / 3600 = 22.5 -> 23 cents)
      final start = DateTime(2026, 10, 14, 8, 0, 0);
      final end = DateTime(2026, 10, 14, 17, 0, 15);
      final shift = Shift(
        id: 301,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 60,
        overtimeThresholdMinutes: 480,
        overtimeRateMinor: 5400,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(28815));
      expect(earnings.regularEarningsMinor, equals(28800));
      expect(earnings.overtimeEarningsMinor, equals(23));
      expect(earnings.earningsMinor, equals(28823));
    });
  });

  group('Vector 4: Multi-Day Shifts, Extended Durations & Calendar Boundaries', () {
    test('24-hour continuous shift (86,400s) calculates exact earnings', () {
      final start = DateTime(2026, 10, 14, 0, 0, 0);
      final end = DateTime(2026, 10, 15, 0, 0, 0);
      final shift = Shift(
        id: 401,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(86400));
      expect(earnings.workedMinutes, equals(1440));
      // 3600 * 86400 / 3600 = 86400 cents ($864.00)
      expect(earnings.earningsMinor, equals(86400));
      expect(shift.durationSeconds, equals(86400));
    });

    test('48-hour continuous shift (172,800s) calculates exact earnings', () {
      final start = DateTime(2026, 10, 14, 8, 0, 0);
      final end = DateTime(2026, 10, 16, 8, 0, 0);
      final shift = Shift(
        id: 402,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 120, // 2 hours break = 7200s
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      // 172800 - 7200 = 165,600s
      expect(earnings.workedSeconds, equals(165600));
      expect(earnings.earningsMinor, equals(165600));
      expect(shift.durationSeconds, equals(165600));
    });

    test('7-day extended shift (604,800s) without overflow', () {
      final res = ShiftEarnings.compute(workedSeconds: 604800, rateMinor: 5000);
      expect(res.workedSeconds, equals(604800));
      // 5000 * 604800 / 3600 = 840,000 cents ($8,400.00)
      expect(res.earningsMinor, equals(840000));
    });

    test('Midnight boundary crossing: 23:59:45 to 00:00:15 next day (30 seconds)', () {
      final start = DateTime(2026, 10, 14, 23, 59, 45);
      final end = DateTime(2026, 10, 15, 0, 0, 15);
      final shift = Shift(
        id: 403,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(30));
      expect(earnings.earningsMinor, equals(30));
      expect(shift.durationSeconds, equals(30));
    });

    test('Month boundary crossing: Oct 31 23:45:10 to Nov 1 04:15:25', () {
      final start = DateTime(2026, 10, 31, 23, 45, 10);
      final end = DateTime(2026, 11, 1, 4, 15, 25);
      final shift = Shift(
        id: 404,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 15, // 900s break
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      // Total clock: 4h 30m 15s = 16215s
      // Net worked: 16215 - 900 = 15315s
      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(15315));
      expect(earnings.earningsMinor, equals(15315));
      expect(shift.durationSeconds, equals(15315));
    });

    test('Year boundary crossing: Dec 31 23:50:00 to Jan 1 00:30:30', () {
      final start = DateTime(2026, 12, 31, 23, 50, 0);
      final end = DateTime(2027, 1, 1, 0, 30, 30);
      final shift = Shift(
        id: 405,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      // Total clock: 40m 30s = 2430s
      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(2430));
      expect(earnings.earningsMinor, equals(2430));
      expect(shift.durationSeconds, equals(2430));
    });

    test('Sub-second millisecond residuals are truncated to integer seconds consistently', () {
      // start at 1000ms, end at 6499ms -> 5499ms difference
      // In seconds: 5 seconds
      final shift = Shift(
        id: 406,
        jobId: 1,
        startAt: 1000,
        endAt: 6499,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(5));
      expect(shift.durationSeconds, equals(5));
      expect(earnings.earningsMinor, equals(5));
    });
  });

  group('Vector 5: Negative, Zero, and Skewed Inputs Robustness', () {
    test('Clock skew: endAt before startAt cleanly clamps to 0 in forShift and durationSeconds', () {
      final shift = Shift(
        id: 501,
        jobId: 1,
        startAt: 2000000,
        endAt: 1000000, // 1000 seconds in past
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.workedMinutes, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('Negative workedSeconds passed directly to compute clamps to 0', () {
      final res = ShiftEarnings.compute(workedSeconds: -999, rateMinor: 3600);
      expect(res.workedSeconds, equals(0));
      expect(res.workedMinutes, equals(0));
      expect(res.earningsMinor, equals(0));
      expect(res.regularEarningsMinor, equals(0));
      expect(res.overtimeEarningsMinor, equals(0));
    });

    test('Break duration exactly equal to shift length produces 0', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 9, 15, 0); // 15 min
      final shift = Shift(
        id: 502,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 15, // 15 min break
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('Break duration exceeding shift length clamps to 0', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 9, 10, 0); // 10 min
      final shift = Shift(
        id: 503,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 60, // 60 min break > 10 min
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('Astronomical break duration (10,000 hours break) clamps safely to 0', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 17, 0, 0); // 8 hours
      final shift = Shift(
        id: 504,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 600000, // 10,000 hours break
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('In-progress shift yields 0 earnings regardless of endAt existence', () {
      final shift = Shift(
        id: 505,
        jobId: 1,
        startAt: 1000000,
        endAt: 2000000,
        breakMinutes: 0,
        status: ShiftStatus.inProgress.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });

    test('Null endAt yields 0 earnings even if status is completed', () {
      final shift = Shift(
        id: 506,
        jobId: 1,
        startAt: 1000000,
        endAt: null,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(0));
      expect(earnings.earningsMinor, equals(0));
      expect(shift.durationSeconds, equals(0));
    });
  });

  group('Vector 6: Invariant & Cross-Consistency Checks', () {
    test('ShiftX.durationSeconds matches ShiftEarnings.forShift workedSeconds across 100 variations', () {
      final random = Random(12345);
      final baseTime = DateTime(2026, 10, 14, 8, 0, 0).millisecondsSinceEpoch;

      for (var i = 0; i < 100; i++) {
        final durationSec = random.nextInt(36000); // up to 10 hours
        final breakMin = random.nextInt(120); // up to 2 hours
        final shift = Shift(
          id: 600 + i,
          jobId: 1,
          startAt: baseTime,
          endAt: baseTime + (durationSec * 1000),
          breakMinutes: breakMin,
          status: ShiftStatus.completed.value,
          createdAt: 0,
          updatedAt: 0,
        );

        final earnings = ShiftEarnings.forShift(shift, baseJob);
        expect(shift.durationSeconds, equals(earnings.workedSeconds),
            reason: 'Mismatch at durationSec=$durationSec, breakMin=$breakMin');
      }
    });

    test('ShiftEarnings sum invariant: regularEarningsMinor + overtimeEarningsMinor == earningsMinor', () {
      final random = Random(54321);
      for (var i = 0; i < 200; i++) {
        final workedSec = random.nextInt(50000);
        final rate = 1000 + random.nextInt(10000);
        final otRate = rate + random.nextInt(10000);
        final threshMin = random.nextInt(600);

        final earnings = ShiftEarnings.compute(
          workedSeconds: workedSec,
          rateMinor: rate,
          overtimeThresholdMinutes: threshMin,
          overtimeRateMinor: otRate,
        );

        expect(
          earnings.regularEarningsMinor + earnings.overtimeEarningsMinor,
          equals(earnings.earningsMinor),
          reason: 'Sum invariant violated for workedSec=$workedSec, thresh=$threshMin',
        );
      }
    });
  });

  group('Vector 7: Leap Year & Astronomical Date Boundaries', () {
    test('Leap year boundary crossing: Feb 28 to Feb 29 leap day', () {
      final start = DateTime(2028, 2, 28, 23, 59, 50);
      final end = DateTime(2028, 2, 29, 0, 0, 10); // 20 seconds
      final shift = Shift(
        id: 701,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(20));
      expect(earnings.earningsMinor, equals(20));
      expect(shift.durationSeconds, equals(20));
    });

    test('Leap day boundary crossing: Feb 29 to March 1', () {
      final start = DateTime(2028, 2, 29, 23, 59, 50);
      final end = DateTime(2028, 3, 1, 0, 0, 10); // 20 seconds
      final shift = Shift(
        id: 702,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(20));
      expect(earnings.earningsMinor, equals(20));
      expect(shift.durationSeconds, equals(20));
    });
  });

  group('Vector 8: Rate Override & Unpaid Shift Handling', () {
    test('Volunteer / unpaid shift with rateOverrideMinor = 0 results in 0 pay', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 17, 0, 0); // 8 hours
      final shift = Shift(
        id: 801,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        rateOverrideMinor: 0, // Volunteer shift
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(28800));
      expect(earnings.hourlyRateMinor, equals(0));
      expect(earnings.earningsMinor, equals(0));
    });

    test('Custom higher rate override prorates down to the second', () {
      final start = DateTime(2026, 10, 14, 9, 0, 0);
      final end = DateTime(2026, 10, 14, 10, 30, 45); // 5445 seconds
      final shift = Shift(
        id: 802,
        jobId: 1,
        startAt: start.millisecondsSinceEpoch,
        endAt: end.millisecondsSinceEpoch,
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        rateOverrideMinor: 9000, // $90.00/hr ($0.025/sec)
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, baseJob);
      expect(earnings.workedSeconds, equals(5445));
      expect(earnings.hourlyRateMinor, equals(9000));
      // 9000 * 5445 / 3600 = 13612.5 -> 13613 cents ($136.13)
      expect(earnings.earningsMinor, equals(13613));
    });
  });

  group('Vector 9: WorkViewModel.endShift Live Lifecycle Second Precision', () {
    late AppDatabase db;
    late FinanceStore store;
    late WorkViewModel workVm;
    late JobRepository jobRepo;
    late ShiftRepository shiftRepo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final accountRepo = AccountRepository(db);
      final txRepo = TransactionRepository(db);
      final recRepo = RecurringRepository(db);
      jobRepo = JobRepository(db);
      shiftRepo = ShiftRepository(db);
      final goalRepo = GoalRepository(db);
      final debtRepo = DebtRepository(db);
      final ratesRepo = ExchangeRateRepository(db);
      final settingsRepo = SettingsRepository(db);
      await settingsRepo.load();

      store = FinanceStore(
        accountsRepo: accountRepo,
        transactionsRepo: txRepo,
        recurringRepo: recRepo,
        jobsRepo: jobRepo,
        shiftsRepo: shiftRepo,
        goalsRepo: goalRepo,
        debtsRepo: debtRepo,
        ratesRepo: ratesRepo,
        settingsRepo: settingsRepo,
      );
      store.start();

      workVm = WorkViewModel(
        financeStore: store,
        jobRepo: jobRepo,
        shiftRepo: shiftRepo,
      );
    });

    tearDown(() async {
      workVm.dispose();
      store.dispose();
      await db.close();
    });

    test('endShift computes and returns exact second-accurate earnings', () async {
      // 1. Create a job at $42.50/hr (4250 cents)
      final jobId = await workVm.addJob(
        name: 'DevOps Specialist',
        hourlyRateMinor: 4250,
        currencyCode: 'USD',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      final job = workVm.jobs.firstWhere((j) => j.id == jobId);

      // 2. Start shift at a fixed time
      final startTime = DateTime(2026, 10, 14, 10, 0, 0);
      final shiftId = await shiftRepo.start(jobId: job.id);
      await Future.delayed(const Duration(milliseconds: 50));

      // Update startAt to fixed startTime
      await shiftRepo.update(shiftId, startAt: startTime);
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. End shift 1 hour 30 min 37 seconds later (5437s elapsed) with a 15 min break (900s)
      final endTime = startTime.add(const Duration(hours: 1, minutes: 30, seconds: 37));
      final returnedEarnings = await workVm.endShift(
        shiftId,
        breakMinutes: 15,
        endAt: endTime,
      );

      // Net worked seconds = 5437 - 900 = 4537 seconds
      // 4250 * 4537 / 3600 = 19282250 / 3600 = 5356.1805... -> 5356 cents ($53.56)
      expect(returnedEarnings.workedSeconds, equals(4537));
      expect(returnedEarnings.workedMinutes, equals(75)); // 4537 ~/ 60 = 75
      expect(returnedEarnings.earningsMinor, equals(5356));

      // 4. Verify the database record directly
      final refreshedShift = (await db.select(db.shifts).get()).first;
      expect(refreshedShift.status, equals(ShiftStatus.completed.value));
      expect(refreshedShift.breakMinutes, equals(15));
      expect(refreshedShift.endAt, equals(endTime.millisecondsSinceEpoch));

      // Re-run ShiftEarnings.forShift on the persisted record
      final persistedEarnings = ShiftEarnings.forShift(refreshedShift, job);
      expect(persistedEarnings.workedSeconds, equals(4537));
      expect(persistedEarnings.earningsMinor, equals(5356));
      expect(refreshedShift.durationSeconds, equals(4537));
    });
  });
}

