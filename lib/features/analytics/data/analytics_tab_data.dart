import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/analytics/data/insights_engine.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

class AnalyticsTrend {
  const AnalyticsTrend(this.values, this.labels);
  final List<double> values;
  final List<String> labels;
}

class AnalyticsTxTabData {
  const AnalyticsTxTabData({
    required this.totalMinor,
    required this.count,
    required this.trend,
    required this.categories,
    required this.top,
  });
  final int totalMinor;
  final int count;
  final AnalyticsTrend trend;
  final List<CategorySpend> categories;
  final List<AnalyticsMerchantSpend> top;

  int get averageMinor => count == 0 ? 0 : (totalMinor / count).round();
}

class AnalyticsPartyTotal {
  const AnalyticsPartyTotal(this.name, this.amountMinor, this.count);
  final String name;
  final int amountMinor;
  final int count;
}

class AnalyticsDebtTabData {
  const AnalyticsDebtTabData({
    required this.totalMinor,
    required this.outstandingMinor,
    required this.settledMinor,
    required this.count,
    required this.trend,
    required this.parties,
    required this.top,
  });
  final int totalMinor;
  final int outstandingMinor;
  final int settledMinor;
  final int count;
  final AnalyticsTrend trend;
  final List<AnalyticsPartyTotal> parties;
  final List<Debt> top;
}

class AnalyticsJobEarnings {
  const AnalyticsJobEarnings({
    required this.job,
    required this.earningsMinor,
    required this.minutes,
    required this.shifts,
  });
  final Job job;
  final int earningsMinor;
  final int minutes;
  final int shifts;
}

class AnalyticsWeek {
  const AnalyticsWeek(this.start, this.minutes, this.earningsMinor);
  final DateTime start;
  final int minutes;
  final int earningsMinor;
}

class AnalyticsWorkTabData {
  const AnalyticsWorkTabData({
    required this.totalMinutes,
    required this.earningsMinor,
    required this.overtimeMinutes,
    required this.breakMinutes,
    required this.shiftCount,
    required this.jobs,
    required this.weeks,
  });
  final int totalMinutes;
  final int earningsMinor;
  final int overtimeMinutes;
  final int breakMinutes;
  final int shiftCount;
  final List<AnalyticsJobEarnings> jobs;
  final List<AnalyticsWeek> weeks;

  int get averageShiftMinutes =>
      shiftCount == 0 ? 0 : (totalMinutes / shiftCount).round();
}

/// Buckets dated amounts across [start]..[end]: daily up to 31 days,
/// otherwise at most ~12 equal buckets (months when the range is long).
AnalyticsTrend bucketTrend(
  DateTime start,
  DateTime end,
  Iterable<(int, double)> points,
) {
  final first = AppDate.dateOnly(start);
  final totalDays = AppDate.dateOnly(end).difference(first).inDays + 1;
  final step = totalDays <= 31 ? 1 : (totalDays / 12).ceil();
  final bucketCount = (totalDays / step).ceil();
  final values = List<double>.filled(bucketCount, 0);
  for (final (ms, v) in points) {
    final d = AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
    final i = d.difference(first).inDays ~/ step;
    if (i >= 0 && i < bucketCount) values[i] += v;
  }
  final labels = <String>[
    for (var i = 0; i < bucketCount; i++)
      () {
        final d = first.add(Duration(days: i * step));
        if (totalDays <= 7) return AppDate.weekday(d);
        return totalDays > 92 ? DateFormatter.monthShort(d) : DateFormatter.day(d);
      }(),
  ];
  return AnalyticsTrend(values, labels);
}

extension AnalyticsTabData on AnalyticsViewModel {
  AnalyticsTxTabData txTabData(TransactionType type) {
    final (start, end) = dateRange;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final snap = financeStore.snapshot;
    final txs = financeStore.transactions.where(
      (t) =>
          t.type == type.value &&
          t.occurredAt >= startMs &&
          t.occurredAt <= endMs &&
          (selectedAccountId == null || t.accountId == selectedAccountId),
    );

    var total = 0;
    var count = 0;
    final points = <(int, double)>[];
    final cats = <String, int>{};
    final tops = <String, (int, int, String)>{};
    for (final t in txs) {
      final amt = snap.convert(t.amountMinor, snap.currencyOf(t.accountId));
      total += amt;
      count++;
      points.add((t.occurredAt, amt.toDouble()));
      cats.update(t.category, (v) => v + amt, ifAbsent: () => amt);
      final raw = t.note?.split('·').first.trim();
      final locCat = TransactionCategories.localizedCategoryName(t.category);
      final name = (raw != null && raw.isNotEmpty) ? raw : locCat;
      final cur = tops[name] ?? (0, 0, locCat);
      tops[name] = (cur.$1 + amt, cur.$2 + 1, cur.$3);
    }
    return AnalyticsTxTabData(
      totalMinor: total,
      count: count,
      trend: bucketTrend(start, end, points),
      categories: [
        for (final e in cats.entries)
          CategorySpend(
            categoryKey: e.key,
            label: TransactionCategories.fromValue(e.key, type).label,
            amountMinor: e.value,
          ),
      ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor)),
      top: [
        for (final e in tops.entries)
          AnalyticsMerchantSpend(
            name: e.key,
            amountMinor: e.value.$1,
            count: e.value.$2,
            category: e.value.$3,
          ),
      ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor)),
    );
  }

  AnalyticsDebtTabData debtTabData(DebtType type) {
    final (start, end) = dateRange;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final snap = financeStore.snapshot;
    final items =
        debts
            .where(
              (d) =>
                  d.type == type.value &&
                  d.createdAt >= startMs &&
                  d.createdAt <= endMs,
            )
            .toList();

    var total = 0;
    var settled = 0;
    final points = <(int, double)>[];
    final parties = <String, (int, int)>{};
    for (final d in items) {
      final amt = snap.convert(d.amountMinor, d.currencyCode);
      total += amt;
      if (d.isSettled) settled += amt;
      points.add((d.createdAt, amt.toDouble()));
      final name = d.personName.trim();
      final cur = parties[name] ?? (0, 0);
      parties[name] = (cur.$1 + amt, cur.$2 + 1);
    }
    items.sort(
      (a, b) => snap
          .convert(b.amountMinor, b.currencyCode)
          .compareTo(snap.convert(a.amountMinor, a.currencyCode)),
    );
    return AnalyticsDebtTabData(
      totalMinor: total,
      outstandingMinor: total - settled,
      settledMinor: settled,
      count: items.length,
      trend: bucketTrend(start, end, points),
      parties: [
        for (final e in parties.entries)
          AnalyticsPartyTotal(e.key, e.value.$1, e.value.$2),
      ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor)),
      top: items,
    );
  }

  AnalyticsWorkTabData workTabData() {
    final (start, end) = dateRange;
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final snap = financeStore.snapshot;
    final jobsById = {for (final j in financeStore.jobs) j.id: j};

    var minutes = 0, earnings = 0, overtime = 0, breaks = 0, count = 0;
    final perJob = <int, (int, int, int)>{}; // earnings, minutes, shifts
    final perWeek = <int, (int, int)>{}; // minutes, earnings

    for (final s in financeStore.shifts) {
      if (s.status != ShiftStatus.completed.value || s.endAt == null) continue;
      if (s.startAt < startMs || s.startAt > endMs) continue;
      final job = jobsById[s.jobId];
      if (job == null) continue;
      final result = ShiftEarnings.forShift(s, job);
      final earned = snap.convert(result.earningsMinor, job.currencyCode);
      final worked = result.workedMinutes;
      minutes += worked;
      earnings += earned;
      breaks += s.breakMinutes;
      count++;
      overtime += result.overtimeMinutes;
      final j = perJob[job.id] ?? (0, 0, 0);
      perJob[job.id] = (j.$1 + earned, j.$2 + worked, j.$3 + 1);
      final day = AppDate.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(s.startAt),
      );
      final weekStart = day.subtract(Duration(days: day.weekday - 1));
      final w = perWeek[weekStart.millisecondsSinceEpoch] ?? (0, 0);
      perWeek[weekStart.millisecondsSinceEpoch] = (
        w.$1 + worked,
        w.$2 + earned,
      );
    }

    // Continuous weeks (including empty ones), capped to the latest 12.
    final weeks = <AnalyticsWeek>[];
    final firstDay = AppDate.dateOnly(start);
    var cursor = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    while (!cursor.isAfter(end)) {
      final w = perWeek[cursor.millisecondsSinceEpoch] ?? (0, 0);
      weeks.add(AnalyticsWeek(cursor, w.$1, w.$2));
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 7);
    }
    final shownWeeks =
        weeks.length > 12 ? weeks.sublist(weeks.length - 12) : weeks;

    return AnalyticsWorkTabData(
      totalMinutes: minutes,
      earningsMinor: earnings,
      overtimeMinutes: overtime,
      breakMinutes: breaks,
      shiftCount: count,
      jobs: [
        for (final e in perJob.entries)
          AnalyticsJobEarnings(
            job: jobsById[e.key]!,
            earningsMinor: e.value.$1,
            minutes: e.value.$2,
            shifts: e.value.$3,
          ),
      ]..sort((a, b) => b.earningsMinor.compareTo(a.earningsMinor)),
      weeks: shownWeeks,
    );
  }
}
