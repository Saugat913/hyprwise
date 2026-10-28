import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

enum CalendarItemType { shift, bill, goal, expense, income }

enum CalendarFilter { all, shifts, transactions, bills }

class CalendarItem {
  const CalendarItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    this.endDate,
    required this.amountMinor,
    required this.currencyCode,
    this.isIncome = false,
    this.colorIndex = 0,
    this.status,
    this.category,
    this.rawId,
  });

  final String id;
  final CalendarItemType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final DateTime? endDate;
  final int amountMinor;
  final String currencyCode;
  final bool isIncome;
  final int colorIndex;
  final String? status;
  final String? category;
  final int? rawId;

  int get durationMinutes {
    if (endDate != null) {
      return endDate!.difference(date).inMinutes;
    }
    return 0;
  }
}

class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({
    required this.financeStore,
    CalendarFilter initialFilter = CalendarFilter.all,
  }) : _filter = initialFilter {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;

  DateTime _selectedDate = AppDate.dateOnly(DateTime.now());
  DateTime get selectedDate => _selectedDate;
  String get baseCurrency => financeStore.baseCurrency;

  CalendarFilter _filter;
  CalendarFilter get filter => _filter;

  int _weekOffset = 0;
  int get weekOffset => _weekOffset;

  void _onStoreChanged() {
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = AppDate.dateOnly(date);
    // Keep week strip synced with selected date
    final today = AppDate.dateOnly(DateTime.now());
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final selectedMonday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    _weekOffset = (selectedMonday.difference(currentMonday).inDays / 7).round();
    notifyListeners();
  }

  void setFilter(CalendarFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void navigateWeek(int delta) {
    _weekOffset += delta;
    final today = AppDate.dateOnly(DateTime.now());
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final newMonday = currentMonday.add(Duration(days: _weekOffset * 7));
    _selectedDate = newMonday;
    notifyListeners();
  }

  void jumpToToday({bool resetFilter = false}) {
    _weekOffset = 0;
    _selectedDate = AppDate.dateOnly(DateTime.now());
    if (resetFilter) _filter = CalendarFilter.shifts;
    notifyListeners();
  }

  /// 7-day strip based on current _weekOffset
  List<DateTime> get weekStrip {
    final today = AppDate.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1)).add(Duration(days: _weekOffset * 7));
    return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }

  bool hasEventsOn(DateTime day) {
    final d = AppDate.dateOnly(day);
    // Check shifts
    for (final s in financeStore.shifts) {
      final start = AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(s.startAt));
      if (start == d) return true;
    }
    // Check recorded transactions
    for (final t in financeStore.transactions) {
      final txDate = AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(t.occurredAt));
      if (txDate == d) return true;
    }
    // Check forecast events
    final events = financeStore.forecast(horizonDays: 60).events;
    for (final e in events) {
      if (AppDate.dateOnly(e.date) == d) return true;
    }
    return false;
  }

  /// Returns items ONLY for the selected date, filtered by active filter
  List<CalendarItem> get selectedDayItems {
    final items = <CalendarItem>[];
    final targetDate = _selectedDate;
    final jobsById = {for (final j in financeStore.jobs) j.id: j};

    // 1. Shifts on selected date
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.shifts) {
      for (final s in financeStore.shifts) {
        final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
        final end = s.endAt != null ? DateTime.fromMillisecondsSinceEpoch(s.endAt!) : null;
        final onTargetDate = AppDate.dateOnly(start) == targetDate ||
            (end != null && AppDate.dateOnly(end) == targetDate) ||
            (s.status == 'in_progress' && AppDate.dateOnly(DateTime.now()) == targetDate);
        if (!onTargetDate) continue;

        final job = jobsById[s.jobId];
        final jobName = job?.name ?? 'Shift';
        final earnings = job != null ? ShiftEarnings.forShift(s, job) : null;
        final timeStr = end != null
            ? '${AppDate.timeOnly(start)} – ${AppDate.timeOnly(end)}'
            : AppDate.timeOnly(start);

        final amount = earnings?.earningsMinor ?? (job != null ? job.hourlyRateMinor * 4 : 0);

        items.add(
          CalendarItem(
            id: 'shift_${s.id}',
            type: CalendarItemType.shift,
            title: jobName,
            subtitle: timeStr,
            date: start,
            endDate: end,
            amountMinor: amount,
            currencyCode: job?.currencyCode ?? baseCurrency,
            isIncome: true,
            colorIndex: job?.colorIndex ?? 0,
            status: s.status,
            rawId: s.id,
          ),
        );
      }
    }

    // 2. Real transactions recorded on selected date
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.transactions) {
      for (final t in financeStore.transactions) {
        final txDate = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
        if (AppDate.dateOnly(txDate) != targetDate) continue;

        final isIncome = t.type == TransactionType.income.value;
        final title = (t.note != null && t.note!.isNotEmpty) ? t.note! : t.category;

        items.add(
          CalendarItem(
            id: 'tx_${t.id}',
            type: isIncome ? CalendarItemType.income : CalendarItemType.expense,
            title: title,
            subtitle: '${t.category} · ${AppDate.timeOnly(txDate)}',
            date: txDate,
            amountMinor: t.amountMinor,
            currencyCode: baseCurrency,
            isIncome: isIncome,
            category: t.category,
            rawId: t.id,
          ),
        );
      }
    }

    // 3. Forecast events (bills, subscriptions, goal contributions) on selected date
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.bills) {
      final forecast = financeStore.forecast(horizonDays: 60);
      for (var i = 0; i < forecast.events.length; i++) {
        final e = forecast.events[i];
        if (AppDate.dateOnly(e.date) != targetDate) continue;
        if (e.kind == ForecastEventKind.shift) continue; // Real shifts already added above

        final isBill = e.kind == ForecastEventKind.bill || e.kind == ForecastEventKind.subscription;
        if (_filter == CalendarFilter.bills && !isBill) continue;

        final type = isBill ? CalendarItemType.bill : CalendarItemType.goal;

        items.add(
          CalendarItem(
            id: 'forecast_$i',
            type: type,
            title: e.label,
            subtitle: isBill ? 'Recurring bill due' : 'Goal contribution planned',
            date: e.date,
            amountMinor: e.deltaMinor.abs(),
            currencyCode: baseCurrency,
            isIncome: e.isIncome,
          ),
        );
      }
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  /// Day income totals
  int get dayIncomeMinor {
    var sum = 0;
    for (final item in selectedDayItems) {
      if (item.isIncome) sum += item.amountMinor;
    }
    return sum;
  }

  /// Day expense totals
  int get dayExpenseMinor {
    var sum = 0;
    for (final item in selectedDayItems) {
      if (!item.isIncome) sum += item.amountMinor;
    }
    return sum;
  }

  int get dayNetMinor => dayIncomeMinor - dayExpenseMinor;

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
