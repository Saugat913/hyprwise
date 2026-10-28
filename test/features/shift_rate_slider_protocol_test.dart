import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/view/widgets/shift_rate_slider_protocol.dart';

void main() {
  group('ShiftRateSliderProtocol & ShiftRateConfig', () {
    test('Non-custom rate defaults to baseHourlyRateMinor and null override', () {
      const config = ShiftRateConfig(
        isCustom: false,
        customHourlyRate: 25.0,
      );

      final effectiveRate = config.calculateEffectiveHourlyRateMinor(
        baseHourlyRateMinor: 2500,
        durationHours: 8.0,
      );
      final rateOverride = config.getRateOverrideMinor(
        baseHourlyRateMinor: 2500,
        durationHours: 8.0,
      );

      expect(effectiveRate, 2500);
      expect(rateOverride, isNull);
    });

    test('Custom rate without overtime scales directly', () {
      const config = ShiftRateConfig(
        isCustom: true,
        customHourlyRate: 35.50,
        hasOvertime: false,
      );

      final effectiveRate = config.calculateEffectiveHourlyRateMinor(
        baseHourlyRateMinor: 2500,
        durationHours: 8.0,
      );
      final rateOverride = config.getRateOverrideMinor(
        baseHourlyRateMinor: 2500,
        durationHours: 8.0,
      );

      expect(effectiveRate, 3550);
      expect(rateOverride, 3550);
    });

    test('Custom rate with overtime computes weighted hourly rate accurately', () {
      // 10 hour shift:
      // Base: $30/h
      // Overtime after: 8.0 hrs
      // Overtime multiplier: 1.5x -> $45/h
      // Expected total pay: (8 * 30) + (2 * 45) = 240 + 90 = $330
      // Effective hourly rate: 330 / 10 = $33.00/h -> 3300 minor
      const config = ShiftRateConfig(
        isCustom: true,
        customHourlyRate: 30.0,
        hasOvertime: true,
        overtimeThresholdHours: 8.0,
        overtimeMultiplier: 1.5,
      );

      final effectiveRate = config.calculateEffectiveHourlyRateMinor(
        baseHourlyRateMinor: 3000,
        durationHours: 10.0,
      );
      final rateOverride = config.getRateOverrideMinor(
        baseHourlyRateMinor: 3000,
        durationHours: 10.0,
      );

      expect(effectiveRate, 3300);
      expect(rateOverride, 3300);

      // Verify ShiftEarnings calculation respects rateOverride
      final shift = Shift(
        id: 1,
        jobId: 10,
        startAt: DateTime(2026, 10, 1, 8, 0).millisecondsSinceEpoch,
        endAt: DateTime(2026, 10, 1, 18, 0).millisecondsSinceEpoch, // 10 hrs
        breakMinutes: 0,
        status: ShiftStatus.completed.value,
        rateOverrideMinor: rateOverride,
        createdAt: 0,
        updatedAt: 0,
      );
      final job = Job(
        id: 10,
        name: 'Warehouse Specialist',
        hourlyRateMinor: 3000,
        currencyCode: 'NPR',
        colorIndex: 0,
        isActive: true,
        defaultBreakMinutes: 0,
        longShiftAlertMinutes: 360,
        createdAt: 0,
        updatedAt: 0,
      );

      final earnings = ShiftEarnings.forShift(shift, job);
      expect(earnings.hourlyRateMinor, 3300);
      expect(earnings.earningsMinor, 33000); // 10 hours * 33.00 = 330.00
    });

    test('Custom rate with fixed overtime rate applies flat rate for overtime hours', () {
      // 10 hour shift:
      // Base: $30/h
      // Overtime after: 8.0 hrs
      // Fixed Overtime rate: $50.00/h flat rate
      // Expected total pay: (8 * 30) + (2 * 50) = 240 + 100 = $340
      // Effective hourly rate: 340 / 10 = $34.00/h -> 3400 minor
      const config = ShiftRateConfig(
        isCustom: true,
        customHourlyRate: 30.0,
        hasOvertime: true,
        overtimeThresholdHours: 8.0,
        overtimeType: OvertimePricingType.fixedRate,
        overtimeFixedRate: 50.0,
      );

      final effectiveRate = config.calculateEffectiveHourlyRateMinor(
        baseHourlyRateMinor: 3000,
        durationHours: 10.0,
      );
      final rateOverride = config.getRateOverrideMinor(
        baseHourlyRateMinor: 3000,
        durationHours: 10.0,
      );

      expect(effectiveRate, 3400);
      expect(rateOverride, 3400);
      expect(config.effectiveOvertimeHourlyRate, 50.0);
    });
  });

  group('Savings Account Currency Synchronization', () {
    test('ensureFixedTwoAccounts creates or updates both Everyday and Savings to selected currency', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = AccountRepository(db);

      // First run with EUR
      final initialAccounts = await repo.ensureFixedTwoAccounts('EUR');
      expect(initialAccounts.everyday.currencyCode, 'EUR');
      expect(initialAccounts.savings.currencyCode, 'EUR');

      // User changes currency to NPR
      final updatedAccounts = await repo.ensureFixedTwoAccounts('NPR');
      expect(updatedAccounts.everyday.currencyCode, 'NPR');
      expect(updatedAccounts.savings.currencyCode, 'NPR');

      // Re-query database to ensure persistence
      final allAccounts = await repo.watchAll().first;
      final everyday = allAccounts.firstWhere((a) => a.type == AccountType.bank.value);
      final savings = allAccounts.firstWhere((a) => a.type == AccountType.savings.value);

      expect(everyday.currencyCode, 'NPR');
      expect(savings.currencyCode, 'NPR');

      await db.close();
    });
  });
}
