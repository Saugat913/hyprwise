import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';

/// An immutable, in-memory view of everything the financial engines need.
///
/// Building one snapshot per rebuild keeps forecasting, advice, insights and
/// the assistant consistent and cheap to test: they are pure functions over
/// this data and never touch the database directly.
class FinanceSnapshot {
  FinanceSnapshot({
    required this.now,
    required this.baseCurrency,
    required this.accounts,
    required this.transactions,
    required this.transfers,
    required this.recurring,
    required this.jobs,
    required this.shifts,
    required this.goals,
    required this.contributions,
    required this.rates,
  }) : _converter = CurrencyConverter(rates),
       _accountById = {for (final account in accounts) account.id: account};

  final DateTime now;
  final String baseCurrency;
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Transfer> transfers;
  final List<RecurringRule> recurring;
  final List<Job> jobs;
  final List<Shift> shifts;
  final List<Goal> goals;
  final List<GoalContribution> contributions;
  final List<ExchangeRateQuote> rates;

  final CurrencyConverter _converter;
  final Map<int, Account> _accountById;

  CurrencyConverter get converter => _converter;

  Account? accountById(int id) => _accountById[id];

  String currencyOf(int accountId) =>
      _accountById[accountId]?.currencyCode ?? baseCurrency;

  /// Current balance of an account: opening balance adjusted by income,
  /// expenses and both sides of transfers.
  int balanceOf(int accountId) {
    final account = _accountById[accountId];
    final opening = account?.openingBalanceMinor ?? 0;
    var movement = 0;
    for (final transaction in transactions) {
      if (transaction.accountId != accountId) continue;
      movement +=
          transaction.type == TransactionType.income.value
              ? transaction.amountMinor
              : -transaction.amountMinor;
    }
    for (final transfer in transfers) {
      if (transfer.sourceAccountId == accountId) {
        movement -= transfer.amountMinor;
      }
      if (transfer.destinationAccountId == accountId) {
        movement += transfer.destinationAmountMinor ?? transfer.amountMinor;
      }
    }
    return opening + movement;
  }

  /// Total balance across active accounts expressed in the base currency.
  int get netWorthMinor => accounts
      .where((account) => !account.isArchived)
      .fold(
        0,
        (sum, account) =>
            sum + convert(balanceOf(account.id), account.currencyCode),
      );

  int convert(int minorUnits, String from) =>
      _converter.convert(minorUnits, from, baseCurrency);

  List<Account> get activeAccounts =>
      accounts.where((account) => !account.isArchived).toList();

  /// Currencies that currently have balances, in a stable order.
  List<String> get activeCurrencies {
    final codes =
        {for (final account in activeAccounts) account.currencyCode}.toList()
          ..sort();
    return codes;
  }

  bool isInMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  int incomeInMonth(DateTime month) => transactions
      .where((t) => t.type == TransactionType.income.value)
      .where((t) => isInMonth(_date(t.occurredAt), month))
      .fold(
        0,
        (sum, t) => sum + convert(t.amountMinor, currencyOf(t.accountId)),
      );

  int expenseInMonth(DateTime month) => transactions
      .where((t) => t.type == TransactionType.expense.value)
      .where((t) => isInMonth(_date(t.occurredAt), month))
      .fold(
        0,
        (sum, t) => sum + convert(t.amountMinor, currencyOf(t.accountId)),
      );

  Map<String, int> get monthlyCategorySpend {
    final month = now;
    final spend = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense.value) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
      if (!isInMonth(date, month)) continue;
      final converted = convert(
        transaction.amountMinor,
        currencyOf(transaction.accountId),
      );
      spend.update(
        transaction.category,
        (value) => value + converted,
        ifAbsent: () => converted,
      );
    }
    return spend;
  }

  static DateTime _date(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis);

  DateTime get currentMonth => AppDate.startOfMonth(now);
}
