import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/goals/data/forecast_engine.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
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

  final ValueNotifier<int> scrollToShiftNotifier = ValueNotifier<int>(0);

  void triggerScrollToNextShift() {
    scrollToShiftNotifier.value++;
  }

  // Per-snapshot O(1) date indexes & selected-day memoization caches.
  FinanceSnapshot? _indexedSnapshot;
  Map<int, List<Shift>> _shiftsByDay = const {};
  Map<int, List<Transaction>> _transactionsByDay = const {};
  Map<int, Job> _jobsById = const {};
  Set<int>? _forecastNonShiftDays;
  Set<int>? _forecastBillDays;
  List<CalendarItem>? _selectedDayItemsCache;
  int? _dayIncomeCache;
  int? _dayExpenseCache;

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  void _invalidateDayCache() {
    _selectedDayItemsCache = null;
    _dayIncomeCache = null;
    _dayExpenseCache = null;
  }

  void _ensureIndexed() {
    final snap = financeStore.snapshot;
    if (identical(_indexedSnapshot, snap)) return;
    _indexedSnapshot = snap;
    _forecastNonShiftDays = null;
    _forecastBillDays = null;
    _invalidateDayCache();

    _jobsById = {for (final j in snap.jobs) j.id: j};

    final shiftMap = <int, List<Shift>>{};
    final todayKey = _dayKey(DateTime.now());
    for (final s in snap.shifts) {
      final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
      final startKey = _dayKey(start);
      shiftMap.putIfAbsent(startKey, () => <Shift>[]).add(s);

      if (s.endAt != null) {
        final end = DateTime.fromMillisecondsSinceEpoch(s.endAt!);
        final endKey = _dayKey(end);
        if (endKey != startKey) {
          shiftMap.putIfAbsent(endKey, () => <Shift>[]).add(s);
        }
      }
      if (s.status == 'in_progress' && todayKey != startKey) {
        final list = shiftMap.putIfAbsent(todayKey, () => <Shift>[]);
        if (!list.contains(s)) list.add(s);
      }
    }
    _shiftsByDay = shiftMap;

    final txMap = <int, List<Transaction>>{};
    for (final t in snap.transactions) {
      final txDate = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
      txMap.putIfAbsent(_dayKey(txDate), () => <Transaction>[]).add(t);
    }
    _transactionsByDay = txMap;
  }

  void _ensureForecastDaysIndexed() {
    _ensureIndexed();
    if (_forecastNonShiftDays != null) return;
    final nonShiftDays = <int>{};
    final billDays = <int>{};
    final events = financeStore.forecast(horizonDays: 60).events;
    for (final e in events) {
      if (e.kind == ForecastEventKind.shift) continue;
      final key = _dayKey(e.date);
      nonShiftDays.add(key);
      if (e.kind == ForecastEventKind.bill ||
          e.kind == ForecastEventKind.subscription) {
        billDays.add(key);
      }
    }
    _forecastNonShiftDays = nonShiftDays;
    _forecastBillDays = billDays;
  }

  void _onStoreChanged() {
    _indexedSnapshot = null;
    _invalidateDayCache();
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = AppDate.dateOnly(date);
    _invalidateDayCache();
    // Keep week strip synced with selected date
    final today = AppDate.dateOnly(DateTime.now());
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final selectedMonday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    _weekOffset = (selectedMonday.difference(currentMonday).inDays / 7).round();
    triggerScrollToNextShift();
    notifyListeners();
  }

  void setFilter(CalendarFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    _invalidateDayCache();
    triggerScrollToNextShift();
    notifyListeners();
  }

  void navigateWeek(int delta) {
    _weekOffset += delta;
    final today = AppDate.dateOnly(DateTime.now());
    final currentMonday = today.subtract(Duration(days: today.weekday - 1));
    final newMonday = currentMonday.add(Duration(days: _weekOffset * 7));
    _selectedDate = newMonday;
    _invalidateDayCache();
    triggerScrollToNextShift();
    notifyListeners();
  }

  void jumpToToday({bool resetFilter = false}) {
    _weekOffset = 0;
    _selectedDate = AppDate.dateOnly(DateTime.now());
    if (resetFilter) _filter = CalendarFilter.shifts;
    _invalidateDayCache();
    triggerScrollToNextShift();
    notifyListeners();
  }

  /// 7-day strip based on current _weekOffset
  List<DateTime> get weekStrip {
    final today = AppDate.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1)).add(Duration(days: _weekOffset * 7));
    return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }

  bool hasEventsOn(DateTime day) {
    _ensureIndexed();
    final key = _dayKey(day);
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.shifts) {
      if (_shiftsByDay.containsKey(key)) return true;
    }
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.transactions) {
      if (_transactionsByDay.containsKey(key)) return true;
    }
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.bills) {
      _ensureForecastDaysIndexed();
      if (_filter == CalendarFilter.bills) {
        return _forecastBillDays!.contains(key);
      }
      return _forecastNonShiftDays!.contains(key);
    }
    return false;
  }

  /// Returns items ONLY for the selected date, filtered by active filter (cached per date/filter/snapshot).
  List<CalendarItem> get selectedDayItems {
    _ensureIndexed();
    if (_selectedDayItemsCache != null) return _selectedDayItemsCache!;

    final items = <CalendarItem>[];
    final targetDate = _selectedDate;
    final targetKey = _dayKey(targetDate);
    final tr = AppStrings.current();

    // 1. Shifts on selected date (O(1) bucket lookup)
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.shifts) {
      final dayShifts = _shiftsByDay[targetKey];
      if (dayShifts != null) {
        for (final s in dayShifts) {
          final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
          final end = s.endAt != null ? DateTime.fromMillisecondsSinceEpoch(s.endAt!) : null;
          final job = _jobsById[s.jobId];
          final jobName = job?.name ?? tr.shiftLabel;
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
    }

    // 2. Real transactions recorded on selected date (O(1) bucket lookup)
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.transactions) {
      final dayTxs = _transactionsByDay[targetKey];
      if (dayTxs != null) {
        for (final t in dayTxs) {
          final txDate = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
          final isIncome = t.type == TransactionType.income.value;
          final locCat = TransactionCategories.localizedCategoryName(t.category);
          final title = (t.note != null && t.note!.isNotEmpty) ? t.note! : locCat;

          items.add(
            CalendarItem(
              id: 'tx_${t.id}',
              type: isIncome ? CalendarItemType.income : CalendarItemType.expense,
              title: title,
              subtitle: '$locCat · ${AppDate.timeOnly(txDate)}',
              date: txDate,
              amountMinor: t.amountMinor,
              currencyCode: financeStore.snapshot.currencyOf(t.accountId),
              isIncome: isIncome,
              category: t.category,
              rawId: t.id,
            ),
          );
        }
      }
    }

    // 3. Forecast events (bills, subscriptions, goal contributions) on selected date
    if (_filter == CalendarFilter.all || _filter == CalendarFilter.bills) {
      final forecast = financeStore.forecast(horizonDays: 60);
      for (var i = 0; i < forecast.events.length; i++) {
        final e = forecast.events[i];
        if (_dayKey(e.date) != targetKey) continue;
        if (e.kind == ForecastEventKind.shift) continue; // Real shifts already added above

        final isBill = e.kind == ForecastEventKind.bill || e.kind == ForecastEventKind.subscription;
        if (_filter == CalendarFilter.bills && !isBill) continue;

        final type = isBill ? CalendarItemType.bill : CalendarItemType.goal;

        items.add(
          CalendarItem(
            id: 'forecast_$i',
            type: type,
            title: e.label,
            subtitle: isBill ? tr.recurringBillDue : tr.goalContributionPlanned,
            date: e.date,
            amountMinor: e.deltaMinor.abs(),
            currencyCode: baseCurrency,
            isIncome: e.isIncome,
          ),
        );
      }
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return _selectedDayItemsCache = items;
  }

  /// Day income totals converted to base currency (cached per date/filter/snapshot)
  int get dayIncomeMinor {
    if (_dayIncomeCache != null) return _dayIncomeCache!;
    var sum = 0;
    final snap = financeStore.snapshot;
    for (final item in selectedDayItems) {
      if (item.isIncome) {
        sum += snap.convert(item.amountMinor, item.currencyCode);
      }
    }
    return _dayIncomeCache = sum;
  }

  /// Day expense totals converted to base currency (cached per date/filter/snapshot)
  int get dayExpenseMinor {
    if (_dayExpenseCache != null) return _dayExpenseCache!;
    var sum = 0;
    final snap = financeStore.snapshot;
    for (final item in selectedDayItems) {
      if (!item.isIncome) {
        sum += snap.convert(item.amountMinor, item.currencyCode);
      }
    }
    return _dayExpenseCache = sum;
  }

  int get dayNetMinor => dayIncomeMinor - dayExpenseMinor;

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
