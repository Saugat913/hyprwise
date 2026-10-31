import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/model/goals.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

void main() {
  late AppDatabase db;
  late FinanceStore store;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late GoalRepository goalRepo;
  late DataRepository dataRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
    goalRepo = GoalRepository(db);
    dataRepo = DataRepository(db);

    final accRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    final settingsRepo = SettingsRepository(db);
    await settingsRepo.load();
    final rateRepo = ExchangeRateRepository(db);

    store = FinanceStore(
      accountsRepo: accRepo,
      transactionsRepo: txRepo,
      recurringRepo: recRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      settingsRepo: settingsRepo,
      ratesRepo: rateRepo,
    );
    store.start();
  });

  tearDown(() async {
    await db.close();
  });

  test('Updating job hourly rate preserves historical rate on past shifts', () async {
    final workVm = WorkViewModel(
      financeStore: store,
      jobRepo: jobRepo,
      shiftRepo: shiftRepo,
    );

    // 1. Create a job at $25/hour (2500 minor)
    final jobId = await workVm.addJob(
      name: 'Cafe Barista',
      hourlyRateMinor: 2500,
      currencyCode: 'AUD',
    );
    await Future.delayed(const Duration(milliseconds: 50));

    // 2. Schedule and complete a 4-hour shift (10:00 to 14:00)
    final now = DateTime.now();
    final shiftId = await shiftRepo.add(
      jobId: jobId,
      startAt: now.subtract(const Duration(days: 2)),
      endAt: now.subtract(const Duration(days: 2, hours: -4)),
      status: ShiftStatus.completed,
    );
    await Future.delayed(const Duration(milliseconds: 50));

    // 3. Update job rate to $35/hour (3500 minor)
    await workVm.updateJob(
      jobId,
      name: 'Senior Barista',
      hourlyRateMinor: 3500,
    );
    await Future.delayed(const Duration(milliseconds: 50));

    // 4. Verify historical shift preserved the old $25 rate via rateOverrideMinor
    final updatedShift = (await db.select(db.shifts).get()).firstWhere((s) => s.id == shiftId);
    expect(updatedShift.rateOverrideMinor, 2500);

    // 5. Verify the job's new rate is $35
    final updatedJob = (await db.select(db.jobs).get()).firstWhere((j) => j.id == jobId);
    expect(updatedJob.hourlyRateMinor, 3500);
    expect(updatedJob.name, 'Senior Barista');
  });

  test('Goal priority waterfall orders high priority goals first in forecast', () async {
    await goalRepo.add(
      name: 'Emergency Fund',
      targetAmountMinor: 1000000,
      currencyCode: 'AUD',
      priority: GoalPriority.high,
    );

    await goalRepo.add(
      name: 'Vacation',
      targetAmountMinor: 200000,
      currencyCode: 'AUD',
      priority: GoalPriority.low,
    );

    await goalRepo.add(
      name: 'New Laptop',
      targetAmountMinor: 300000,
      currencyCode: 'AUD',
      priority: GoalPriority.normal,
    );
    await Future.delayed(const Duration(milliseconds: 50));

    final forecast = store.forecast(horizonDays: 90);
    expect(forecast.goalForecasts.length, 3);
    // Highest priority first
    expect(forecast.goalForecasts[0].goal.name, 'Emergency Fund');
    expect(forecast.goalForecasts[0].goal.priority, 'high');
    // Normal priority second
    expect(forecast.goalForecasts[1].goal.name, 'New Laptop');
    expect(forecast.goalForecasts[1].goal.priority, 'normal');
    // Low priority last
    expect(forecast.goalForecasts[2].goal.name, 'Vacation');
    expect(forecast.goalForecasts[2].goal.priority, 'low');
  });

  test('DataRepository exports CSV and Summary Report properly', () async {
    final csvContent = await dataRepo.exportCsv();
    expect(csvContent, contains('ID,Date,Type,Category,Note/Merchant,Account,Amount,Currency'));

    final reportContent = await dataRepo.exportSummaryReport('AUD');
    expect(reportContent, contains('HYPRWISE FINANCIAL REPORT'));
    expect(reportContent, contains('Base Currency: AUD'));
  });
}
