import 'package:flutter/material.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/analytics/data/insights_engine.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

enum AnalyticsDateFilter {
  thisMonth,
  thisWeek,
  last30Days,
  thisYear,
  custom;

  String get label {
    final tr = AppStrings.current();
    return switch (this) {
      AnalyticsDateFilter.thisMonth => tr.filterThisMonth,
      AnalyticsDateFilter.thisWeek => tr.filterThisWeek,
      AnalyticsDateFilter.last30Days => tr.filterLast30Days,
      AnalyticsDateFilter.thisYear => tr.filterThisYear,
      AnalyticsDateFilter.custom => tr.customOption,
    };
  }
}

class DualBarChartData {
  const DualBarChartData({
    required this.incomeValues,
    required this.expenseValues,
    required this.labels,
    this.dates = const [],
  });

  final List<double> incomeValues;
  final List<double> expenseValues;
  final List<String> labels;
  final List<DateTime> dates;

  bool get isEmpty => incomeValues.isEmpty && expenseValues.isEmpty;
  bool get hasAnyData =>
      incomeValues.any((v) => v > 0) || expenseValues.any((v) => v > 0);
}

class AnalyticsMerchantSpend {
  const AnalyticsMerchantSpend({
    required this.name,
    required this.amountMinor,
    required this.count,
    required this.category,
  });

  final String name;
  final int amountMinor;
  final int count;
  final String category;
}

class AnalyticsDebtParty {
  const AnalyticsDebtParty({
    required this.name,
    required this.netMinor,
    required this.lentMinor,
    required this.borrowedMinor,
    required this.count,
  });

  final String name;
  final int netMinor;
  final int lentMinor;
  final int borrowedMinor;
  final int count;
}

class AnalyticsViewModel extends ChangeNotifier {
  AnalyticsViewModel({required this.financeStore}) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;

  AnalyticsDateFilter _dateFilter = AnalyticsDateFilter.thisMonth;
  AnalyticsDateFilter get dateFilter => _dateFilter;

  TransactionType _activeType = TransactionType.expense;
  TransactionType get activeType => _activeType;

  DateTimeRange? _customRange;
  DateTimeRange? get customRange => _customRange;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  int? _selectedAccountId;
  int? get selectedAccountId => _selectedAccountId;

  String? _selectedDebtParty;
  String? get selectedDebtParty => _selectedDebtParty;

  String get baseCurrency => financeStore.baseCurrency;
  List<Account> get accounts => financeStore.accounts;

  void _onStoreChanged() {
    notifyListeners();
  }

  void setActiveType(TransactionType type) {
    if (_activeType != type) {
      _activeType = type;
      _selectedCategory = null;
      notifyListeners();
    }
  }

  void setDateFilter(AnalyticsDateFilter filter, {DateTimeRange? customRange}) {
    _dateFilter = filter;
    if (filter == AnalyticsDateFilter.custom && customRange != null) {
      _customRange = customRange;
    }
    notifyListeners();
  }

  void selectCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null; // Toggle off
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void selectAccountId(int? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  void selectDebtParty(String? party) {
    if (_selectedDebtParty == party) {
      _selectedDebtParty = null; // Toggle off
    } else {
      _selectedDebtParty = party;
    }
    notifyListeners();
  }

  void clearFilters() {
    _dateFilter = AnalyticsDateFilter.thisMonth;
    _customRange = null;
    _selectedCategory = null;
    _selectedAccountId = null;
    _selectedDebtParty = null;
    notifyListeners();
  }

  /// Calculates the active start and end DateTime for analytics
  (DateTime, DateTime) get dateRange {
    final now = DateTime.now();
    final today = AppDate.dateOnly(now);

    return switch (_dateFilter) {
      AnalyticsDateFilter.thisWeek => (
        today.subtract(Duration(days: today.weekday - 1)),
        today.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
      ),
      AnalyticsDateFilter.thisMonth => (
        AppDate.startOfMonth(now),
        AppDate.endOfMonth(now),
      ),
      AnalyticsDateFilter.last30Days => (
        today.subtract(const Duration(days: 29)),
        today.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
      ),
      AnalyticsDateFilter.thisYear => (
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31, 23, 59, 59),
      ),
      AnalyticsDateFilter.custom =>
        _customRange != null
            ? (
              AppDate.dateOnly(_customRange!.start),
              AppDate.dateOnly(
                _customRange!.end,
              ).add(const Duration(hours: 23, minutes: 59, seconds: 59)),
            )
            : (AppDate.startOfMonth(now), AppDate.endOfMonth(now)),
    };
  }

  /// Filtered list of transactions matching date range, category, and account
  List<Transaction> get filteredTransactions {
    final (start, end) = dateRange;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    return financeStore.transactions.where((t) {
      if (t.occurredAt < startMs || t.occurredAt > endMs) return false;
      if (_selectedCategory != null) {
        final sel = _selectedCategory!.trim().toLowerCase();
        final cat = t.category.trim().toLowerCase();
        final match =
            cat == sel ||
            TransactionCategories.find(
                  sel,
                  TransactionType.expense,
                )?.label.toLowerCase() ==
                cat ||
            TransactionCategories.find(
                  sel,
                  TransactionType.income,
                )?.label.toLowerCase() ==
                cat ||
            TransactionCategories.find(
                  cat,
                  TransactionType.expense,
                )?.value.toLowerCase() ==
                sel ||
            TransactionCategories.find(
                  cat,
                  TransactionType.income,
                )?.value.toLowerCase() ==
                sel;
        if (!match) return false;
      }
      if (_selectedAccountId != null && t.accountId != _selectedAccountId) {
        return false;
      }
      return true;
    }).toList();
  }

  /// All unique categories available across transactions in the current date range
  List<String> get availableCategories {
    final (start, end) = dateRange;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    final cats = <String>{};
    for (final t in financeStore.transactions) {
      if (t.occurredAt >= startMs &&
          t.occurredAt <= endMs &&
          t.type == _activeType.value) {
        cats.add(t.category);
      }
    }
    return cats.toList();
  }

  int get expenseMinor {
    var total = 0;
    for (final t in filteredTransactions) {
      if (t.type == TransactionType.expense.value) {
        total += financeStore.snapshot.convert(
          t.amountMinor,
          financeStore.snapshot.currencyOf(t.accountId),
        );
      }
    }
    return total;
  }

  int get incomeMinor {
    var total = 0;
    for (final t in filteredTransactions) {
      if (t.type == TransactionType.income.value) {
        total += financeStore.snapshot.convert(
          t.amountMinor,
          financeStore.snapshot.currencyOf(t.accountId),
        );
      }
    }
    return total;
  }

  int get activeTotalMinor =>
      _activeType == TransactionType.expense ? expenseMinor : incomeMinor;

  int get netMinor => incomeMinor - expenseMinor;

  bool get hasData => incomeMinor > 0 || expenseMinor > 0;

  /// Category breakdown for the active period (or subcategories/merchants if single category selected)
  List<CategorySpend> get categoryBreakdown {
    final totals = <String, int>{};
    for (final t in filteredTransactions) {
      if (t.type == _activeType.value) {
        final amt = financeStore.snapshot.convert(
          t.amountMinor,
          financeStore.snapshot.currencyOf(t.accountId),
        );
        totals.update(t.category, (v) => v + amt, ifAbsent: () => amt);
      }
    }

    final list =
        totals.entries.map((e) {
          final label =
              TransactionCategories.fromValue(e.key, _activeType).label;
          return CategorySpend(
            categoryKey: e.key,
            label: label,
            amountMinor: e.value,
          );
        }).toList();

    list.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return list;
  }

  /// Daily income and expense breakdown for dual bar chart
  DualBarChartData get dualChartData {
    final (start, end) = dateRange;
    final incomeBuckets = <int, double>{};
    final expenseBuckets = <int, double>{};

    for (final t in filteredTransactions) {
      final d = AppDate.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(t.occurredAt),
      );
      final key = d.millisecondsSinceEpoch;
      final amt = financeStore.snapshot
          .convert(
            t.amountMinor,
            financeStore.snapshot.currencyOf(t.accountId),
          )
          .toDouble();

      if (t.type == TransactionType.income.value) {
        incomeBuckets.update(key, (v) => v + amt, ifAbsent: () => amt);
      } else if (t.type == TransactionType.expense.value) {
        expenseBuckets.update(key, (v) => v + amt, ifAbsent: () => amt);
      }
    }

    final incomeValues = <double>[];
    final expenseValues = <double>[];
    final labels = <String>[];
    final dates = <DateTime>[];
    final totalDays = end.difference(start).inDays + 1;

    // Sample intervals if date range is long
    final step = totalDays > 31 ? (totalDays / 12).ceil() : 1;

    var day = start;
    while (!day.isAfter(end)) {
      final key = AppDate.dateOnly(day).millisecondsSinceEpoch;
      incomeValues.add(incomeBuckets[key] ?? 0.0);
      expenseValues.add(expenseBuckets[key] ?? 0.0);
      labels.add(totalDays <= 7 ? AppDate.weekday(day) : DateFormatter.day(day));
      dates.add(day);
      day = day.add(Duration(days: step));
      if (step > 1 && labels.length >= 12) break;
    }

    return DualBarChartData(
      incomeValues: incomeValues,
      expenseValues: expenseValues,
      labels: labels,
      dates: dates,
    );
  }

  /// Daily spending or income breakdown for chart
  (List<double>, List<String>) get chartData {
    final data = dualChartData;
    final values = _activeType == TransactionType.income
        ? data.incomeValues
        : data.expenseValues;
    return (values, data.labels);
  }

  /// Top merchants or income sources based on filtered set
  List<AnalyticsMerchantSpend> get topMerchants {
    final map =
        <String, (int, int, String)>{}; // name -> (total, count, category)

    for (final t in filteredTransactions) {
      if (t.type != _activeType.value) continue;
      final rawName = t.note?.split('·').first.trim();
      final locCat = TransactionCategories.localizedCategoryName(t.category);
      final name =
          (rawName != null && rawName.isNotEmpty) ? rawName : locCat;
      final amt = financeStore.snapshot.convert(
        t.amountMinor,
        financeStore.snapshot.currencyOf(t.accountId),
      );

      final current = map[name] ?? (0, 0, locCat);
      map[name] = (current.$1 + amt, current.$2 + 1, current.$3);
    }

    final list =
        map.entries
            .map(
              (e) => AnalyticsMerchantSpend(
                name: e.key,
                amountMinor: e.value.$1,
                count: e.value.$2,
                category: e.value.$3,
              ),
            )
            .toList();

    list.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return list;
  }

  int get projectedMonthEndMinor {
    final forecast = financeStore.forecast(horizonDays: 30);
    return forecast.endMinor;
  }

  // Lending & Borrowing analytics
  List<Debt> get debts => financeStore.debts;

  List<Debt> get activeDebts =>
      financeStore.debts.where((d) => !d.isSettled).toList();

  int get totalLentMinor {
    var sum = 0;
    for (final d in activeDebts) {
      if (d.type == DebtType.lent.value) {
        sum += financeStore.snapshot.convert(d.amountMinor, d.currencyCode);
      }
    }
    return sum;
  }

  int get totalBorrowedMinor {
    var sum = 0;
    for (final d in activeDebts) {
      if (d.type == DebtType.borrowed.value) {
        sum += financeStore.snapshot.convert(d.amountMinor, d.currencyCode);
      }
    }
    return sum;
  }

  int get netDebtMinor => totalLentMinor - totalBorrowedMinor;

  List<AnalyticsDebtParty> get topDebtParties {
    final partyMap =
        <String, (int, int, int)>{}; // name -> (lent, borrowed, count)
    for (final d in activeDebts) {
      final name = d.personName.trim();
      if (name.isEmpty) continue;
      final amt = financeStore.snapshot.convert(d.amountMinor, d.currencyCode);
      final current = partyMap[name] ?? (0, 0, 0);
      if (d.type == DebtType.lent.value) {
        partyMap[name] = (current.$1 + amt, current.$2, current.$3 + 1);
      } else {
        partyMap[name] = (current.$1, current.$2 + amt, current.$3 + 1);
      }
    }

    final list =
        partyMap.entries.map((e) {
          final lent = e.value.$1;
          final borrowed = e.value.$2;
          return AnalyticsDebtParty(
            name: e.key,
            netMinor: lent - borrowed,
            lentMinor: lent,
            borrowedMinor: borrowed,
            count: e.value.$3,
          );
        }).toList();

    list.sort((a, b) => b.netMinor.abs().compareTo(a.netMinor.abs()));
    return list;
  }

  /// All counterparties with records of [type] in the active date range (plus currently selected party)
  List<String> debtPartiesFor(DebtType type) {
    final (start, end) = dateRange;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final parties = <String>{};
    for (final d in debts) {
      if (d.type == type.value && d.createdAt >= startMs && d.createdAt <= endMs) {
        final name = d.personName.trim();
        if (name.isNotEmpty) parties.add(name);
      }
    }
    if (_selectedDebtParty != null && _selectedDebtParty!.trim().isNotEmpty) {
      parties.add(_selectedDebtParty!.trim());
    }
    return parties.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Total amount in base currency for [party] under [type] in the active date range
  int partyTotalFor(String party, DebtType type) {
    final (start, end) = dateRange;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final snap = financeStore.snapshot;
    var sum = 0;
    for (final d in debts) {
      if (d.type == type.value &&
          d.personName.trim().toLowerCase() == party.trim().toLowerCase() &&
          d.createdAt >= startMs &&
          d.createdAt <= endMs) {
        sum += snap.convert(d.amountMinor, d.currencyCode);
      }
    }
    return sum;
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
