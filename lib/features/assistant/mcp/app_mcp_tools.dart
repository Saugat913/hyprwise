import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

/// In-App Model Context Protocol (MCP) Tool Registry and Local Executor.
/// Tools execute directly on-device against the local Drift database and FinanceStore.
class AppMcpTools {
  AppMcpTools({
    required this.financeStore,
    required this.transactionRepo,
    required this.goalRepo,
  });

  final FinanceStore financeStore;
  final TransactionRepository transactionRepo;
  final GoalRepository goalRepo;

  /// Tool definitions formatted for Gemini Function Calling
  List<Map<String, dynamic>> get declarations => [
    {
      'name': 'get_balance_summary',
      'description':
          'Fetches the user\'s current financial snapshot including Everyday account balance, Savings account balance, and Net Position.',
      'parameters': {'type': 'OBJECT', 'properties': {}},
    },
    {
      'name': 'get_cash_flow_metrics',
      'description': 'Returns month-to-date income, expenses, and net savings.',
      'parameters': {'type': 'OBJECT', 'properties': {}},
    },
    {
      'name': 'get_debts_summary',
      'description':
          'Returns summary of active loans and debts (total lent, total borrowed, and party details).',
      'parameters': {'type': 'OBJECT', 'properties': {}},
    },
    {
      'name': 'list_upcoming_shifts',
      'description':
          'Returns work shifts scheduled within the next 7 days, including job names and estimated earnings.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'daysAhead': {
            'type': 'INTEGER',
            'description': 'Number of days ahead to look (default: 7)',
          },
        },
      },
    },
    {
      'name': 'convert_currency',
      'description':
          'Converts an amount from a foreign currency (e.g. AUD, USD, EUR) to the user\'s base currency using live rates.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'amount': {
            'type': 'NUMBER',
            'description': 'The foreign amount to convert',
          },
          'fromCurrency': {
            'type': 'STRING',
            'description':
                'The source currency ISO code (e.g. AUD, USD, EUR, INR)',
          },
        },
        'required': ['amount', 'fromCurrency'],
      },
    },
    {
      'name': 'record_transaction',
      'description':
          'Records a new income or expense transaction into the user\'s Everyday account.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'amount': {
            'type': 'NUMBER',
            'description': 'Amount in base currency (e.g. 25.50)',
          },
          'type': {
            'type': 'STRING',
            'enum': ['expense', 'income'],
            'description': 'Whether this is an expense or income',
          },
          'category': {
            'type': 'STRING',
            'description':
                'Category label (e.g. Groceries, Eating out, Shift Pay, Transport)',
          },
          'note': {
            'type': 'STRING',
            'description': 'Optional transaction note or merchant name',
          },
        },
        'required': ['amount', 'type', 'category'],
      },
    },
    {
      'name': 'allocate_savings_goal',
      'description':
          'Transfers savings from the Everyday account to the Savings account towards a goal.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'goalName': {
            'type': 'STRING',
            'description': 'Name of the savings goal',
          },
          'amount': {
            'type': 'NUMBER',
            'description': 'Amount to save towards the goal',
          },
        },
        'required': ['goalName', 'amount'],
      },
    },
  ];

  /// Executes an MCP tool locally on-device
  Future<Map<String, dynamic>> execute(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    try {
      switch (name) {
        case 'get_balance_summary':
          final snapshot = financeStore.snapshot;
          final everyday = financeStore.everydayAccount;
          final savings = financeStore.savingsAccount;
          return {
            'baseCurrency': financeStore.baseCurrency,
            'netPosition': MoneyFormatter.format(
              snapshot.netWorthMinor,
              financeStore.baseCurrency,
            ),
            'everydayBalance':
                everyday != null
                    ? MoneyFormatter.format(
                      snapshot.balanceOf(everyday.id),
                      everyday.currencyCode,
                    )
                    : 'N/A',
            'savingsBalance':
                savings != null
                    ? MoneyFormatter.format(
                      snapshot.balanceOf(savings.id),
                      savings.currencyCode,
                    )
                    : 'N/A',
          };

        case 'get_cash_flow_metrics':
          final now = DateTime.now();
          final start = DateTime(now.year, now.month);
          final income = financeStore.snapshot.incomeInMonth(start);
          final expense = financeStore.snapshot.expenseInMonth(start);
          return {
            'month': '${now.year}-${now.month.toString().padLeft(2, '0')}',
            'income': MoneyFormatter.format(income, financeStore.baseCurrency),
            'expense': MoneyFormatter.format(
              expense,
              financeStore.baseCurrency,
            ),
            'netCashFlow': MoneyFormatter.format(
              income - expense,
              financeStore.baseCurrency,
            ),
          };

        case 'get_debts_summary':
          final debts = financeStore.debts.where((d) => !d.isSettled).toList();
          final lent = debts
              .where((d) => d.type == 'lent')
              .fold<int>(0, (s, d) => s + d.amountMinor);
          final borrowed = debts
              .where((d) => d.type == 'borrowed')
              .fold<int>(0, (s, d) => s + d.amountMinor);
          final partyBreakdown =
              debts
                  .map(
                    (d) => {
                      'party': d.personName,
                      'type': d.type,
                      'amount': MoneyFormatter.format(
                        d.amountMinor,
                        d.currencyCode,
                      ),
                      'note': d.note,
                    },
                  )
                  .toList();
          return {
            'totalLent': MoneyFormatter.format(lent, financeStore.baseCurrency),
            'totalBorrowed': MoneyFormatter.format(
              borrowed,
              financeStore.baseCurrency,
            ),
            'netDebt': MoneyFormatter.format(
              lent - borrowed,
              financeStore.baseCurrency,
            ),
            'activeDebts': partyBreakdown,
          };

        case 'list_upcoming_shifts':
          final days = (arguments['daysAhead'] as num?)?.toInt() ?? 7;
          final now = DateTime.now();
          final end = now.add(Duration(days: days));
          final jobsById = {for (final j in financeStore.jobs) j.id: j};
          final shifts =
              financeStore.shifts
                  .where((s) {
                    final st = DateTime.fromMillisecondsSinceEpoch(s.startAt);
                    return st.isAfter(now.subtract(const Duration(hours: 4))) &&
                        st.isBefore(end);
                  })
                  .map((s) {
                    final job = jobsById[s.jobId];
                    final earnings =
                        job != null
                            ? ShiftEarnings.forShift(s, job).earningsMinor
                            : 0;
                    return {
                      'job': job?.name ?? 'Job #${s.jobId}',
                      'start':
                          DateTime.fromMillisecondsSinceEpoch(
                            s.startAt,
                          ).toIso8601String(),
                      'end':
                          s.endAt != null
                              ? DateTime.fromMillisecondsSinceEpoch(
                                s.endAt!,
                              ).toIso8601String()
                              : 'Active',
                      'estimatedEarnings': MoneyFormatter.format(
                        earnings,
                        job?.currencyCode ?? financeStore.baseCurrency,
                      ),
                    };
                  })
                  .toList();
          return {'shifts': shifts, 'totalShifts': shifts.length};

        case 'convert_currency':
          final amount = (arguments['amount'] as num).toDouble();
          final from = (arguments['fromCurrency'] as String).toUpperCase();
          final to = financeStore.baseCurrency.toUpperCase();
          final quotes = financeStore.snapshot.rates;
          final converter = CurrencyConverter(quotes);
          final minor = (amount * 100).round();
          final convertedMinor = converter.convert(minor, from, to);
          return {
            'from': '$from ${amount.toStringAsFixed(2)}',
            'to': '$to ${(convertedMinor / 100).toStringAsFixed(2)}',
            'convertedAmountMinor': convertedMinor,
          };

        case 'record_transaction':
          final amount = (arguments['amount'] as num).toDouble();
          final typeStr = arguments['type'] as String;
          final category = arguments['category'] as String;
          final note = arguments['note'] as String?;
          final type =
              typeStr == 'income'
                  ? TransactionType.income
                  : TransactionType.expense;
          final everyday = financeStore.everydayAccount;
          if (everyday == null) {
            return {'error': 'No active Everyday account found'};
          }

          final minor = (amount * 100).round();
          final id = await transactionRepo.add(
            accountId: everyday.id,
            type: type,
            amountMinor: minor,
            category: category,
            note: note,
            occurredAt: DateTime.now(),
          );
          return {
            'success': true,
            'transactionId': id,
            'message':
                'Recorded $typeStr of ${MoneyFormatter.format(minor, financeStore.baseCurrency)} in Everyday account',
          };

        case 'allocate_savings_goal':
          final goalName = arguments['goalName'] as String;
          final amount = (arguments['amount'] as num).toDouble();
          final minor = (amount * 100).round();
          final goal =
              financeStore.goals
                  .where((g) => g.name.toLowerCase() == goalName.toLowerCase())
                  .firstOrNull;
          if (goal == null) {
            return {'error': 'Goal "$goalName" not found'};
          }
          final everyday = financeStore.everydayAccount;
          final savings = financeStore.savingsAccount;
          if (everyday != null &&
              savings != null &&
              everyday.id != savings.id) {
            await transactionRepo.addTransfer(
              sourceAccountId: everyday.id,
              destinationAccountId: savings.id,
              amountMinor: minor,
              note: 'Saved for ${goal.name}',
              occurredAt: DateTime.now(),
            );
          }
          await goalRepo.addContribution(
            goalId: goal.id,
            amountMinor: minor,
            note: 'Hypr AI allocation',
          );
          return {
            'success': true,
            'message':
                'Transferred ${MoneyFormatter.format(minor, financeStore.baseCurrency)} to Savings for ${goal.name}',
          };

        default:
          return {'error': 'Unknown tool: $name'};
      }
    } catch (e, stack) {
      debugPrint('MCP Tool error ($name): $e\n$stack');
      return {'error': e.toString()};
    }
  }
}
