import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';

/// Handles bulk data operations: whole-database JSON export, import, and reset.
class DataRepository {
  DataRepository(this._db);

  final AppDatabase _db;

  /// Deletes all domain financial records (accounts, transactions, jobs, goals, etc.),
  /// but preserves essential app configuration (locale, theme mode, base currency).
  Future<void> eraseAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.goalContributions).go();
      await _db.delete(_db.goals).go();
      await _db.delete(_db.shiftBreaks).go();
      await _db.delete(_db.shifts).go();
      await _db.delete(_db.jobs).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.transfers).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.debts).go();
      await _db.delete(_db.exchangeRates).go();
    });
    TelemetryService.instance.trackEvent('data_erased');
  }

  /// Exports all financial tables to a JSON string.
  Future<String> exportJson() async {
    final accounts = await _db.select(_db.accounts).get();
    final transactions = await _db.select(_db.transactions).get();
    final transfers = await _db.select(_db.transfers).get();
    final recurringRules = await _db.select(_db.recurringRules).get();
    final jobs = await _db.select(_db.jobs).get();
    final shifts = await _db.select(_db.shifts).get();
    final goals = await _db.select(_db.goals).get();
    final contributions = await _db.select(_db.goalContributions).get();
    final debts = await _db.select(_db.debts).get();
    final rates = await _db.select(_db.exchangeRates).get();
    final shiftBreaks = await _db.select(_db.shiftBreaks).get();
    final reminderRules = await _db.select(_db.reminderRules).get();

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'transfers': transfers.map((e) => e.toJson()).toList(),
      'recurringRules': recurringRules.map((e) => e.toJson()).toList(),
      'jobs': jobs.map((e) => e.toJson()).toList(),
      'shifts': shifts.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'goalContributions': contributions.map((e) => e.toJson()).toList(),
      'debts': debts.map((e) => e.toJson()).toList(),
      'exchangeRates': rates.map((e) => e.toJson()).toList(),
      'shiftBreaks': shiftBreaks.map((e) => e.toJson()).toList(),
      'reminderRules': reminderRules.map((e) => e.toJson()).toList(),
    };

    TelemetryService.instance.trackEvent('data_exported', {
      'transactionsCount': transactions.length,
      'accountsCount': accounts.length,
    });

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Exports transactions to standard CSV format
  Future<String> exportCsv() async {
    final transactions = await _db.select(_db.transactions).get();
    final accounts = await _db.select(_db.accounts).get();
    final accountsById = {for (final a in accounts) a.id: a};

    final rows = <List<dynamic>>[
      ['ID', 'Date', 'Type', 'Category', 'Note/Merchant', 'Account', 'Amount', 'Currency'],
    ];

    for (final tx in transactions) {
      final acc = accountsById[tx.accountId];
      final dt = DateTime.fromMillisecondsSinceEpoch(tx.occurredAt);
      final formattedDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      rows.add([
        tx.id,
        formattedDate,
        tx.type,
        tx.category,
        tx.note ?? '',
        acc?.name ?? 'Account #${tx.accountId}',
        (tx.amountMinor / 100).toStringAsFixed(2),
        acc?.currencyCode ?? 'AUD',
      ]);
    }

    return csv.encode(rows);
  }

  /// Exports a clean human-readable text summary of all finances
  Future<String> exportSummaryReport(String baseCurrency) async {
    final accounts = await _db.select(_db.accounts).get();
    final transactions = await _db.select(_db.transactions).get();
    final jobs = await _db.select(_db.jobs).get();
    final shifts = await _db.select(_db.shifts).get();
    final goals = await _db.select(_db.goals).get();

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('HYPRWISE FINANCIAL REPORT');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Base Currency: $baseCurrency');
    buffer.writeln('========================================\n');

    buffer.writeln('ACCOUNTS (${accounts.length})');
    for (final acc in accounts) {
      buffer.writeln('- ${acc.name} (${acc.type}): ${acc.currencyCode} ${(acc.openingBalanceMinor / 100).toStringAsFixed(2)}');
    }
    buffer.writeln('');

    buffer.writeln('JOBS & WORK (${jobs.length} jobs, ${shifts.length} shifts)');
    for (final j in jobs) {
      buffer.writeln('- ${j.name}: ${j.currencyCode} ${(j.hourlyRateMinor / 100).toStringAsFixed(2)}/hour');
    }
    buffer.writeln('');

    buffer.writeln('GOALS (${goals.length})');
    for (final g in goals) {
      buffer.writeln('- ${g.name} [Priority: ${g.priority}]: ${g.currencyCode} ${(g.targetAmountMinor / 100).toStringAsFixed(2)}');
    }
    buffer.writeln('');

    buffer.writeln('TRANSACTIONS TOTAL: ${transactions.length} records');
    return buffer.toString();
  }

  /// Imports and overwrites data from an exported JSON string.
  Future<void> importJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await _db.transaction(() async {
      await eraseAll();

      if (data['accounts'] is List) {
        for (final item in data['accounts']) {
          await _db.into(_db.accounts).insert(
            Account.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['transactions'] is List) {
        for (final item in data['transactions']) {
          await _db.into(_db.transactions).insert(
            Transaction.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['transfers'] is List) {
        for (final item in data['transfers']) {
          await _db.into(_db.transfers).insert(
            Transfer.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['recurringRules'] is List) {
        for (final item in data['recurringRules']) {
          await _db.into(_db.recurringRules).insert(
            RecurringRule.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['jobs'] is List) {
        for (final item in data['jobs']) {
          await _db.into(_db.jobs).insert(
            Job.fromJson({
              'defaultBreakMinutes': 0,
              'longShiftAlertMinutes': 360,
              ...(item as Map<String, dynamic>),
            }),
          );
        }
      }

      if (data['shifts'] is List) {
        for (final item in data['shifts']) {
          await _db.into(_db.shifts).insert(
            Shift.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['shiftBreaks'] is List) {
        for (final item in data['shiftBreaks']) {
          await _db.into(_db.shiftBreaks).insert(
            ShiftBreak.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['reminderRules'] is List) {
        await _db.delete(_db.reminderRules).go();
        for (final item in data['reminderRules']) {
          await _db.into(_db.reminderRules).insert(
            ReminderRule.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['goals'] is List) {
        for (final item in data['goals']) {
          await _db.into(_db.goals).insert(
            Goal.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['goalContributions'] is List) {
        for (final item in data['goalContributions']) {
          await _db.into(_db.goalContributions).insert(
            GoalContribution.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['debts'] is List) {
        for (final item in data['debts']) {
          await _db.into(_db.debts).insert(
            Debt.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['exchangeRates'] is List) {
        for (final item in data['exchangeRates']) {
          await _db.into(_db.exchangeRates).insert(
            ExchangeRate.fromJson(item as Map<String, dynamic>),
          );
        }
      }
    });

    TelemetryService.instance.trackEvent('data_imported');
  }
}
