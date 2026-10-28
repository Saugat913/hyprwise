import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';

/// Chart-friendly aggregates over a [FinanceSnapshot], in base currency.
extension SnapshotStats on FinanceSnapshot {
  /// Totals per day for the last [days] days (oldest first, today last).
  List<int> dailyTotals(TransactionType type, {int days = 7}) {
    final today = AppDate.dateOnly(now);
    final totals = List<int>.filled(days, 0);
    for (final t in transactions) {
      if (t.type != type.value) continue;
      final day = AppDate.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(t.occurredAt),
      );
      final idx = days - 1 - today.difference(day).inDays;
      if (idx < 0 || idx >= days) continue;
      totals[idx] += convert(t.amountMinor, currencyOf(t.accountId));
    }
    return totals;
  }

  /// This month's expense categories, largest first.
  List<MapEntry<String, int>> get topSpendCategories =>
      monthlyCategorySpend.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
}
