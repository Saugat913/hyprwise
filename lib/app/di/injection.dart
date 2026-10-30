import 'dart:async';

import 'package:get_it/get_it.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/debts/viewmodels/debts_view_model.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/money/viewmodels/money_view_model.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/plan/viewmodels/plan_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/reminder_rule_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/data/category_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/transfers/data/transfer_repository.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) return;

  // 1. Database
  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  // 2. Concrete Repositories
  final accountRepo = AccountRepository(db);
  final transactionRepo = TransactionRepository(db);
  final recurringRepo = RecurringRepository(db);
  final jobRepo = JobRepository(db);
  final shiftRepo = ShiftRepository(db);
  final goalRepo = GoalRepository(db);
  final ratesRepo = ExchangeRateRepository(db);
  final settingsRepo = SettingsRepository(db);
  final dataRepo = DataRepository(db);
  final debtRepo = DebtRepository(db);
  final categoryRepo = CategoryRepository(db);
  final reminderRuleRepo = ReminderRuleRepository(db);
  final transferRepo = TransferRepository(db);

  await settingsRepo.load();
  await categoryRepo.load();

  final authService = AuthService();
  await authService.load();
  final subscriptionService = SubscriptionService(authService: authService);
  await subscriptionService.load();
  await subscriptionService.initRevenueCat();

  getIt
    ..registerSingleton<AccountRepository>(accountRepo)
    ..registerSingleton<TransactionRepository>(transactionRepo)
    ..registerSingleton<RecurringRepository>(recurringRepo)
    ..registerSingleton<JobRepository>(jobRepo)
    ..registerSingleton<ShiftRepository>(shiftRepo)
    ..registerSingleton<GoalRepository>(goalRepo)
    ..registerSingleton<ExchangeRateRepository>(ratesRepo)
    ..registerSingleton<SettingsRepository>(settingsRepo)
    ..registerSingleton<DataRepository>(dataRepo)
    ..registerSingleton<DebtRepository>(debtRepo)
    ..registerSingleton<CategoryRepository>(categoryRepo)
    ..registerSingleton<ReminderRuleRepository>(reminderRuleRepo)
    ..registerSingleton<TransferRepository>(transferRepo)
    ..registerSingleton<AuthService>(authService)
    ..registerSingleton<SubscriptionService>(subscriptionService);

  // 3. Central FinanceStore
  final financeStore = FinanceStore(
    accountsRepo: accountRepo,
    transactionsRepo: transactionRepo,
    recurringRepo: recurringRepo,
    jobsRepo: jobRepo,
    shiftsRepo: shiftRepo,
    goalsRepo: goalRepo,
    ratesRepo: ratesRepo,
    settingsRepo: settingsRepo,
    debtsRepo: debtRepo,
  );
  financeStore.start();
  getIt.registerSingleton<FinanceStore>(financeStore);

  // Pro cloud sync is automatic. Both finance changes and preferences are
  // observed; AuthService debounces writes and ignores free/guest sessions.
  financeStore.addListener(authService.triggerProAutoSync);
  settingsRepo.addListener(authService.triggerProAutoSync);

  await accountRepo.ensureFixedTwoAccounts(settingsRepo.settings.baseCurrency);

  final existingRates = await ratesRepo.watchAll().first;
  if (existingRates.isEmpty) {
    await ratesRepo.add(baseCode: 'AUD', quoteCode: 'NPR', rate: 93.0);
    await ratesRepo.add(baseCode: 'USD', quoteCode: 'NPR', rate: 136.5);
    await ratesRepo.add(baseCode: 'INR', quoteCode: 'NPR', rate: 1.6);
    await ratesRepo.add(baseCode: 'EUR', quoteCode: 'NPR', rate: 148.0);
    await ratesRepo.add(baseCode: 'GBP', quoteCode: 'NPR', rate: 175.0);
    await ratesRepo.add(baseCode: 'AUD', quoteCode: 'USD', rate: 0.66);
  }

  // A persisted Google/Apple session bypasses the login screen on app launch.
  // Restore its snapshot after local defaults are ready, so the import cannot
  // race account/rate initialization.
  if (authService.isAuthenticated &&
      (authService.currentUser?.isPro == true || subscriptionService.isPro)) {
    unawaited(authService.pullCloudDataToLocal());
  }

  // 4. ViewModels
  getIt
    ..registerLazySingleton<HomeViewModel>(
      () => HomeViewModel(
        financeStore: getIt<FinanceStore>(),
        settingsRepo: getIt<SettingsRepository>(),
      ),
    )
    ..registerLazySingleton<CalendarViewModel>(
      () => CalendarViewModel(financeStore: getIt<FinanceStore>()),
    )
    ..registerLazySingleton<AnalyticsViewModel>(
      () => AnalyticsViewModel(financeStore: getIt<FinanceStore>()),
    )
    ..registerSingleton<WorkViewModel>(
      WorkViewModel(
        financeStore: getIt<FinanceStore>(),
        jobRepo: getIt<JobRepository>(),
        shiftRepo: getIt<ShiftRepository>(),
      ),
    )
    ..registerLazySingleton<PlanViewModel>(
      () => PlanViewModel(
        financeStore: getIt<FinanceStore>(),
        goalRepo: getIt<GoalRepository>(),
        accountRepo: getIt<AccountRepository>(),
        transactionRepo: getIt<TransactionRepository>(),
      ),
    )
    ..registerLazySingleton<MoneyViewModel>(
      () => MoneyViewModel(
        financeStore: getIt<FinanceStore>(),
        transactionRepo: getIt<TransactionRepository>(),
      ),
    )
    ..registerLazySingleton<AccountsViewModel>(
      () => AccountsViewModel(
        financeStore: getIt<FinanceStore>(),
        accountRepo: getIt<AccountRepository>(),
      ),
    )
    ..registerLazySingleton<AlertsViewModel>(
      () => AlertsViewModel(
        financeStore: getIt<FinanceStore>(),
        settingsRepo: getIt<SettingsRepository>(),
        reminderRuleRepo: getIt<ReminderRuleRepository>(),
      ),
    )
    ..registerLazySingleton<AssistantViewModel>(
      () => AssistantViewModel(
        financeStore: getIt<FinanceStore>(),
        transactionRepo: getIt<TransactionRepository>(),
        shiftRepo: getIt<ShiftRepository>(),
        goalRepo: getIt<GoalRepository>(),
      ),
    )
    ..registerLazySingleton<SettingsViewModel>(
      () => SettingsViewModel(
        settingsRepo: getIt<SettingsRepository>(),
        dataRepo: getIt<DataRepository>(),
        financeStore: getIt<FinanceStore>(),
      ),
    )
    ..registerLazySingleton<DebtsViewModel>(
      () => DebtsViewModel(
        financeStore: getIt<FinanceStore>(),
        debtRepo: getIt<DebtRepository>(),
        transactionRepo: getIt<TransactionRepository>(),
      ),
    );
}
