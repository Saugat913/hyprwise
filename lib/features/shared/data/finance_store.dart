import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/alerts/data/advice_engine.dart';
import 'package:finance_tracker/features/alerts/data/model/alerts.dart';
import 'package:finance_tracker/features/analytics/data/insights_engine.dart';
import 'package:finance_tracker/features/assistant/data/assistant_engine.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/forecast_engine.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

/// Central observable store combining database streams and deterministic financial engines.
///
/// Views and ViewModels listen to this store for reactive updates across the app.
class FinanceStore extends ChangeNotifier {
  FinanceStore({
    required this.accountsRepo,
    required this.transactionsRepo,
    required this.recurringRepo,
    required this.jobsRepo,
    required this.shiftsRepo,
    required this.goalsRepo,
    required this.ratesRepo,
    required this.settingsRepo,
    this.debtsRepo,
    this.forecastEngine = const ForecastEngine(),
    this.adviceEngine = const AdviceEngine(),
    this.insightsEngine = const InsightsEngine(),
    this.assistantEngine = const AssistantEngine(),
  });

  final AccountRepository accountsRepo;
  final TransactionRepository transactionsRepo;
  final RecurringRepository recurringRepo;
  final JobRepository jobsRepo;
  final ShiftRepository shiftsRepo;
  final GoalRepository goalsRepo;
  final ExchangeRateRepository ratesRepo;
  final SettingsRepository settingsRepo;
  final DebtRepository? debtsRepo;

  final ForecastEngine forecastEngine;
  final AdviceEngine adviceEngine;
  final InsightsEngine insightsEngine;
  final AssistantEngine assistantEngine;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<Account> _accounts = const [];
  List<Transaction> _transactions = const [];
  List<Transfer> _transfers = const [];
  List<RecurringRule> _recurring = const [];
  List<Job> _jobs = const [];
  List<Shift> _shifts = const [];
  List<Goal> _goals = const [];
  List<GoalContribution> _contributions = const [];
  List<ExchangeRate> _rates = const [];
  List<Debt> _debts = const [];

  late FinanceSnapshot _snapshot = _buildSnapshot();

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Transfer> get transfers => _transfers;
  List<RecurringRule> get recurring => _recurring;
  List<Job> get jobs => _jobs;
  List<Shift> get shifts => _shifts;
  List<Goal> get goals => _goals;
  List<GoalContribution> get contributions => _contributions;
  List<ExchangeRate> get rates => _rates;
  List<Debt> get debts => _debts;

  FinanceSnapshot get snapshot => _snapshot;
  String get baseCurrency => settingsRepo.settings.baseCurrency;
  Account? get everydayAccount =>
      _accounts.where((a) => !a.isArchived && a.name.toLowerCase() == 'everyday').firstOrNull ??
      _accounts.firstOrNull;
  Account? get savingsAccount =>
      _accounts.where((a) => !a.isArchived && (a.name.toLowerCase() == 'savings' || a.type == 'savings')).firstOrNull;

  /// Starts listening to all repository streams.
  void start() {
    _subscriptions.addAll([
      accountsRepo.watchAll().listen((data) {
        _accounts = data;
        _rebuild();
      }),
      transactionsRepo.watchAll().listen((data) {
        _transactions = data;
        _rebuild();
      }),
      transactionsRepo.watchTransfers().listen((data) {
        _transfers = data;
        _rebuild();
      }),
      recurringRepo.watchAll().listen((data) {
        _recurring = data;
        _rebuild();
      }),
      jobsRepo.watchAll().listen((data) {
        _jobs = data;
        _rebuild();
      }),
      shiftsRepo.watchAll().listen((data) {
        _shifts = data;
        _rebuild();
      }),
      goalsRepo.watchGoals().listen((data) {
        _goals = data;
        _rebuild();
      }),
      goalsRepo.watchContributions().listen((data) {
        _contributions = data;
        _rebuild();
      }),
      ratesRepo.watchAll().listen((data) {
        _rates = data;
        _rebuild();
      }),
      if (debtsRepo != null)
        debtsRepo!.watchAll().listen((data) {
          _debts = data;
          _rebuild();
        }),
    ]);

    settingsRepo.addListener(_onSettingsChanged);
    _rebuild();
  }

  void _onSettingsChanged() {
    _rebuild();
  }

  FinanceSnapshot _buildSnapshot() {
    return FinanceSnapshot(
      now: DateTime.now(),
      baseCurrency: settingsRepo.settings.baseCurrency,
      accounts: _accounts,
      transactions: _transactions,
      transfers: _transfers,
      recurring: _recurring,
      jobs: _jobs,
      shifts: _shifts,
      goals: _goals,
      contributions: _contributions,
      rates: _rates.map(ExchangeRateQuote.fromRow).toList(),
    );
  }

  void _rebuild() {
    _snapshot = _buildSnapshot();
    notifyListeners();
  }

  /// Projects future balances and goal achievements.
  ForecastResult forecast({int horizonDays = 90}) {
    return forecastEngine.project(_snapshot, horizonDays: horizonDays);
  }

  /// Analyzes financial state and surfaces recommendations.
  List<FinanceAlert> advice() {
    return adviceEngine.generate(_snapshot, forecast: forecast());
  }

  /// Aggregates historical metrics for weekly/monthly insights.
  InsightsReport insights([InsightsPeriod period = InsightsPeriod.month]) {
    return insightsEngine.report(_snapshot, period);
  }

  /// Answers a natural-language query deterministically from local data.
  AssistantAnswer ask(String query) {
    TelemetryService.instance.trackEvent('assistant_query', {'length': query.length});
    return assistantEngine.answer(_snapshot, query);
  }

  @override
  void dispose() {
    settingsRepo.removeListener(_onSettingsChanged);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
