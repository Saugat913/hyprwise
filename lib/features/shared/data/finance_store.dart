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
  bool _isHydrated = false;
  Object? _lastError;
  bool _snapshotDirty = false;
  bool _notifyScheduled = false;
  bool _disposed = false;

  final Map<int, ForecastResult> _forecastCache = {};
  List<FinanceAlert>? _adviceCache;
  final Map<InsightsPeriod, InsightsReport> _insightsCache = {};

  late FinanceSnapshot _snapshot = _buildSnapshot();

  bool get isHydrated => _isHydrated;
  Object? get lastError => _lastError;
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

  FinanceSnapshot get snapshot {
    if (_snapshotDirty) {
      _refreshSnapshot();
    }
    return _snapshot;
  }
  String get baseCurrency => settingsRepo.settings.baseCurrency;
  Account? get everydayAccount =>
      _accounts.where((a) => !a.isArchived && a.name.toLowerCase() == 'everyday').firstOrNull ??
      _accounts.firstOrNull;
  Account? get savingsAccount =>
      _accounts.where((a) => !a.isArchived && (a.name.toLowerCase() == 'savings' || a.type == 'savings')).firstOrNull;

  /// Starts listening to all repository streams.
  void start() {
    void onStreamError(Object error, StackTrace _) {
      _lastError = error;
      notifyListeners();
    }

    _subscriptions.addAll([
      accountsRepo.watchAll().listen((data) {
        _accounts = data;
        _isHydrated = true;
        _lastError = null;
        _scheduleRebuild();
      }, onError: onStreamError),
      transactionsRepo.watchAll().listen((data) {
        _transactions = data;
        _isHydrated = true;
        _scheduleRebuild();
      }, onError: onStreamError),
      transactionsRepo.watchTransfers().listen((data) {
        _transfers = data;
        _scheduleRebuild();
      }, onError: onStreamError),
      recurringRepo.watchAll().listen((data) {
        _recurring = data;
        _scheduleRebuild();
      }, onError: onStreamError),
      jobsRepo.watchAll().listen((data) {
        _jobs = data;
        _scheduleRebuild();
      }, onError: onStreamError),
      shiftsRepo.watchAll().listen((data) {
        _shifts = data;
        _scheduleRebuild();
      }, onError: onStreamError),
      goalsRepo.watchGoals().listen((data) {
        _goals = data;
        _scheduleRebuild();
      }, onError: onStreamError),
      goalsRepo.watchContributions().listen((data) {
        _contributions = data;
        _scheduleRebuild();
      }, onError: onStreamError),
      ratesRepo.watchAll().listen((data) {
        _rates = data;
        _scheduleRebuild();
      }, onError: onStreamError),
      if (debtsRepo != null)
        debtsRepo!.watchAll().listen((data) {
          _debts = data;
          _scheduleRebuild();
        }, onError: onStreamError),
    ]);

    settingsRepo.addListener(_onSettingsChanged);
    _rebuildNow();
  }

  void _onSettingsChanged() {
    _rebuildNow();
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
      rates: _rates.map(ExchangeRateQuote.fromRow).toList(growable: false),
    );
  }

  void _refreshSnapshot() {
    _snapshotDirty = false;
    _snapshot = _buildSnapshot();
    _forecastCache.clear();
    _adviceCache = null;
    _insightsCache.clear();
  }

  void _rebuildNow() {
    _refreshSnapshot();
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Coalesces multiple Drift stream emissions landing in the same event turn
  /// (e.g. cold startup hydration of 10 tables or multi-table transactions)
  /// into a single snapshot rebuild and UI notification pass.
  void _scheduleRebuild() {
    _snapshotDirty = true;
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      if (_disposed) return;
      if (_snapshotDirty) {
        _refreshSnapshot();
      }
      notifyListeners();
    });
  }

  /// Projects future balances and goal achievements (memoized per snapshot).
  ForecastResult forecast({int horizonDays = 90}) {
    final snap = snapshot;
    return _forecastCache.putIfAbsent(
      horizonDays,
      () => forecastEngine.project(snap, horizonDays: horizonDays),
    );
  }

  /// Analyzes financial state and surfaces recommendations (memoized per snapshot).
  List<FinanceAlert> advice() {
    final snap = snapshot;
    return _adviceCache ??= adviceEngine.generate(snap, forecast: forecast());
  }

  /// Aggregates historical metrics for weekly/monthly insights (memoized per snapshot).
  InsightsReport insights([InsightsPeriod period = InsightsPeriod.month]) {
    final snap = snapshot;
    return _insightsCache.putIfAbsent(
      period,
      () => insightsEngine.report(snap, period),
    );
  }

  /// Answers a natural-language query deterministically from local data.
  AssistantAnswer ask(String query) {
    TelemetryService.instance.trackEvent('assistant_query', {'length': query.length});
    return assistantEngine.answer(snapshot, query);
  }

  @override
  void dispose() {
    _disposed = true;
    settingsRepo.removeListener(_onSettingsChanged);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
