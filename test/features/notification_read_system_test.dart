import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/model/goals.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/reminder_rule_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  late AppDatabase db;
  late FinanceStore store;
  late GoalRepository goalRepo;
  late SettingsRepository settingsRepo;
  late ReminderRuleRepository reminderRuleRepo;
  late AlertsViewModel alertsVm;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    goalRepo = GoalRepository(db);
    settingsRepo = SettingsRepository(db);
    reminderRuleRepo = ReminderRuleRepository(db);
    await settingsRepo.load();

    final accRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    final jobRepo = JobRepository(db);
    final shiftRepo = ShiftRepository(db);
    final debtRepo = DebtRepository(db);
    final rateRepo = ExchangeRateRepository(db);

    store = FinanceStore(
      accountsRepo: accRepo,
      transactionsRepo: txRepo,
      recurringRepo: recRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      debtsRepo: debtRepo,
      settingsRepo: settingsRepo,
      ratesRepo: rateRepo,
    );
    store.start();

    alertsVm = AlertsViewModel(
      financeStore: store,
      settingsRepo: settingsRepo,
      reminderRuleRepo: reminderRuleRepo,
    );
  });

  tearDown(() async {
    alertsVm.dispose();
    store.dispose();
    await db.close();
  });

  test('Unread notification count tracks new alerts and markAllAsRead resets to 0', () async {
    // Add an urgent goal due soon to trigger an advice alert
    await goalRepo.add(
      name: 'House Downpayment',
      targetAmountMinor: 5000000,
      currencyCode: 'USD',
      targetDate: DateTime.now().add(const Duration(days: 5)),
      priority: GoalPriority.high,
    );
    await Future.delayed(const Duration(milliseconds: 100));

    // Advice engine surfaces goal alerts
    expect(alertsVm.alerts.isNotEmpty, isTrue);
    final alertCount = alertsVm.alerts.length;
    expect(alertsVm.unreadCount, equals(alertCount));

    // Call markAllAsRead
    await alertsVm.markAllAsRead();

    // Verify unread count immediately drops to 0
    expect(alertsVm.unreadCount, equals(0));
    expect(alertsVm.isRead(alertsVm.alerts.first), isTrue);
  });
}
