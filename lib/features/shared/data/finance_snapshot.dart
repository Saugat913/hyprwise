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

  // Lazy per-snapshot memoization caches (snapshot is immutable).
  Map<int, int>? _balancesCache;
  int? _netWorthCache;
  List<Account>? _activeAccountsCache;
  final Map<int, int> _monthlyIncomeCache = {};
  final Map<int, int> _monthlyExpenseCache = {};
  Map<String, int>? _monthlyCategorySpendCache;

  CurrencyConverter get converter => _converter;

  Account? accountById(int id) => _accountById[id];

  String currencyOf(int accountId) =>
      _accountById[accountId]?.currencyCode ?? baseCurrency;

  Map<int, int> _computeAllBalances() {
    final balances = <int, int>{
      for (final account in accounts) account.id: account.openingBalanceMinor,
    };
    for (final transaction in transactions) {
      final delta =
          transaction.type == TransactionType.income.value
              ? transaction.amountMinor
              : -transaction.amountMinor;
      balances.update(
        transaction.accountId,
        (v) => v + delta,
        ifAbsent: () => delta,
      );
    }
    for (final transfer in transfers) {
      balances.update(
        transfer.sourceAccountId,
        (v) => v - transfer.amountMinor,
        ifAbsent: () => -transfer.amountMinor,
      );
      final destDelta = transfer.destinationAmountMinor ?? transfer.amountMinor;
      balances.update(
        transfer.destinationAccountId,
        (v) => v + destDelta,
        ifAbsent: () => destDelta,
      );
    }
    return balances;
  }

  /// Current balance of an account: opening balance adjusted by income,
  /// expenses and both sides of transfers. Computed in O(1) after first lookup.
  int balanceOf(int accountId) {
    final map = _balancesCache ??= _computeAllBalances();
    return map[accountId] ?? 0;
  }

  /// Total balance across active accounts expressed in the base currency.
  int get netWorthMinor =>
      _netWorthCache ??= activeAccounts.fold<int>(
        0,
        (sum, account) =>
            sum + convert(balanceOf(account.id), account.currencyCode),
      );

  int convert(int minorUnits, String from) =>
      _converter.convert(minorUnits, from, baseCurrency);

  List<Account> get activeAccounts =>
      _activeAccountsCache ??=
          accounts.where((account) => !account.isArchived).toList(growable: false);

  /// Currencies that currently have balances, in a stable order.
  List<String> get activeCurrencies {
    final codes =
        {for (final account in activeAccounts) account.currencyCode}.toList()
          ..sort();
    return codes;
  }

  bool isInMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  int incomeInMonth(DateTime month) {
    final key = month.year * 12 + month.month;
    return _monthlyIncomeCache.putIfAbsent(key, () {
      var sum = 0;
      for (final t in transactions) {
        if (t.type != TransactionType.income.value) continue;
        if (!isInMonth(_date(t.occurredAt), month)) continue;
        sum += convert(t.amountMinor, currencyOf(t.accountId));
      }
      return sum;
    });
  }

  int expenseInMonth(DateTime month) {
    final key = month.year * 12 + month.month;
    return _monthlyExpenseCache.putIfAbsent(key, () {
      var sum = 0;
      for (final t in transactions) {
        if (t.type != TransactionType.expense.value) continue;
        if (!isInMonth(_date(t.occurredAt), month)) continue;
        sum += convert(t.amountMinor, currencyOf(t.accountId));
      }
      return sum;
    });
  }

  Map<String, int> get monthlyCategorySpend {
    if (_monthlyCategorySpendCache != null) return _monthlyCategorySpendCache!;
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
    return _monthlyCategorySpendCache = spend;
  }

  static DateTime _date(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis);

  DateTime get currentMonth => AppDate.startOfMonth(now);
}
