import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/view/widgets/edit_shift_sheet.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    // Default automatically to today's date and shifts filter on every page visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = getIt<CalendarViewModel>();
      vm.jumpToToday();
      vm.setFilter(CalendarFilter.shifts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<CalendarViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;
        final items = viewModel.selectedDayItems;
        final isToday = AppDate.dateOnly(viewModel.selectedDate) == AppDate.dateOnly(DateTime.now());

        return TabPage(
          title: tr.calendar,
          overline: AppDate.monthYear(viewModel.selectedDate),
          actions: [
            if (!isToday)
              Container(
                height: 38,
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: viewModel.jumpToToday,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(tr.today, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            RoundIconButton(
              HugeIcons.strokeRoundedArrowLeft01,
              onPressed: () => viewModel.navigateWeek(-1),
            ),
            RoundIconButton(
              HugeIcons.strokeRoundedArrowRight01,
              onPressed: () => viewModel.navigateWeek(1),
            ),
            RoundIconButton(
              HugeIcons.strokeRoundedPlusSign,
              onPressed: () => _showAddActionSheet(context, viewModel.selectedDate),
            ),
          ],
          children: [
            // Weekday horizontal strip
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.xs),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final day in viewModel.weekStrip) ...[
                    _WeekDayPill(
                      date: day,
                      isSelected: AppDate.dateOnly(day) == viewModel.selectedDate,
                      isToday: AppDate.dateOnly(day) == AppDate.dateOnly(DateTime.now()),
                      hasDot: viewModel.hasEventsOn(day),
                      onTap: () => viewModel.selectDate(day),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: tr.allEvents,
                    isSelected: viewModel.filter == CalendarFilter.all,
                    onTap: () => viewModel.setFilter(CalendarFilter.all),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _FilterChip(
                    label: tr.shiftsOnly,
                    isSelected: viewModel.filter == CalendarFilter.shifts,
                    onTap: () => viewModel.setFilter(CalendarFilter.shifts),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _FilterChip(
                    label: tr.transactionsOnly,
                    isSelected: viewModel.filter == CalendarFilter.transactions,
                    onTap: () => viewModel.setFilter(CalendarFilter.transactions),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _FilterChip(
                    label: tr.bills,
                    isSelected: viewModel.filter == CalendarFilter.bills,
                    onTap: () => viewModel.setFilter(CalendarFilter.bills),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            if (items.isNotEmpty) ...[
              // Compact summary bar above timeline
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (viewModel.dayIncomeMinor > 0) ...[
                          Text(
                            '+${MoneyFormatter.format(viewModel.dayIncomeMinor, viewModel.baseCurrency)}',
                            style: text.bodySmall?.copyWith(color: colors.income, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: AppSpace.sm),
                        ],
                        if (viewModel.dayExpenseMinor > 0) ...[
                          Text(
                            '-${MoneyFormatter.format(viewModel.dayExpenseMinor, viewModel.baseCurrency)}',
                            style: text.bodySmall?.copyWith(color: colors.expense, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: AppSpace.sm),
                        ],
                        Text(
                          tr.itemsScheduledCount(items.length),
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              _AppleCalendarDayTimeline(
                selectedDate: viewModel.selectedDate,
                items: items,
                baseCurrency: viewModel.baseCurrency,
                isToday: isToday,
              ),
            ] else
              _EmptyDayState(
                selectedDate: viewModel.selectedDate,
                isToday: isToday,
                onAddShift: () => context.push(AppRoutes.scheduleShift, extra: viewModel.selectedDate),
                onAddExpense: () => context.push(AppRoutes.addTransaction),
              ),
          ],
        );
      },
    );
  }

  void _showAddActionSheet(BuildContext context, DateTime selectedDate) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final tr = ctx.strings;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tr.addToDateTitle(AppDate.short(selectedDate)),
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                  child: HorizontalOptionSelector<String>(
                    height: 64,
                    selectedValue: null,
                    onChanged: (action) {
                      Navigator.pop(ctx);
                      switch (action) {
                        case 'shift':
                          context.push(AppRoutes.scheduleShift, extra: selectedDate);
                          break;
                        case 'expense':
                        case 'income':
                          context.push(AppRoutes.addTransaction);
                          break;
                      }
                    },
                    items: [
                      HorizontalOptionItem(
                        value: 'shift',
                        label: tr.scheduleShift,
                        subtitle: tr.addWorkShiftWithRate,
                        icon: HugeIcons.strokeRoundedClock01,
                      ),
                      HorizontalOptionItem(
                        value: 'expense',
                        label: tr.addExpense,
                        subtitle: tr.recordExpenseOnDate,
                        icon: HugeIcons.strokeRoundedArrowUpRight01,
                      ),
                      HorizontalOptionItem(
                        value: 'income',
                        label: tr.addIncome,
                        subtitle: tr.recordIncomeOnDate,
                        icon: HugeIcons.strokeRoundedArrowDownLeft01,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasDot,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;
    final dayLetter = tr.weekdayShort(date.weekday);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayLetter,
              style: text.labelSmall?.copyWith(
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: colors.brand, width: 1.5)
                    : null,
              ),
              child: Text(
                tr.formatNumber(date.day),
                style: text.titleSmall?.copyWith(
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: (isSelected || isToday) ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: hasDot ? colors.brand : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple Calendar-style empty state redirecting user to create an event
class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({
    required this.selectedDate,
    required this.isToday,
    required this.onAddShift,
    required this.onAddExpense,
  });

  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onAddShift;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl, horizontal: AppSpace.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          AppIcon(HugeIcons.strokeRoundedCalendar03, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(height: AppSpace.md),
          Text(
            isToday ? tr.nothingScheduledForToday : tr.nothingScheduledForThisDay,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            tr.calendarEmptyAdvice,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              FilledButton.icon(
                onPressed: onAddShift,
                icon: AppIcon(HugeIcons.strokeRoundedClock01, size: 16, color: scheme.onPrimary),
                label: Text(tr.scheduleShift),
              ),
              OutlinedButton.icon(
                onPressed: onAddExpense,
                icon: AppIcon(HugeIcons.strokeRoundedMoneySend02, size: 16, color: scheme.primary),
                label: Text(tr.addExpense),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Apple Calendar-style vertical hourly timeline of events
class _AppleCalendarDayTimeline extends StatefulWidget {
  const _AppleCalendarDayTimeline({
    required this.selectedDate,
    required this.items,
    required this.baseCurrency,
    required this.isToday,
  });

  final DateTime selectedDate;
  final List<CalendarItem> items;
  final String baseCurrency;
  final bool isToday;

  @override
  State<_AppleCalendarDayTimeline> createState() => _AppleCalendarDayTimelineState();
}

class _AppleCalendarDayTimelineState extends State<_AppleCalendarDayTimeline> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.isToday) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _now = DateTime.now();
    // Do not create hanging periodic timers in test environments
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AppleCalendarDayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isToday && _timer == null) {
      _startTimer();
    } else if (!widget.isToday && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // Determine the hour range to display
    var minHour = 7;
    var maxHour = 22;

    if (widget.isToday) {
      if (_now.hour < minHour) minHour = _now.hour;
      if (_now.hour >= maxHour) maxHour = (_now.hour + 1).clamp(0, 23);
    }

    for (final item in widget.items) {
      if (item.date.hour < minHour) minHour = item.date.hour;
      final endHour = item.endDate?.hour ?? item.date.hour;
      if (endHour > maxHour) maxHour = (endHour + 1).clamp(0, 23);
    }

    final hours = List.generate(maxHour - minHour + 1, (i) => minHour + i);

    // Group non-shift transactions by hour
    final txByHour = <int, List<CalendarItem>>{};
    final shifts = <CalendarItem>[];
    for (final it in widget.items) {
      if (it.type == CalendarItemType.shift) {
        shifts.add(it);
      } else {
        txByHour.putIfAbsent(it.date.hour, () => []).add(it);
      }
    }

    // Sort transactions within each hour by minute ascending
    for (final list in txByHour.values) {
      list.sort((a, b) => a.date.minute.compareTo(b.date.minute));
    }

    // Calculate dynamic height for each hour so the timeline gap expands to fit items
    const double baseHourHeight = 68.0;
    const double cardHeight = 56.0;
    const double cardSpacing = 6.0;

    final hourHeights = <int, double>{};
    final hourTops = <int, double>{};
    final txOffsetWithinHour = <int, List<double>>{};
    double currentTop = 0.0;

    for (final h in hours) {
      final list = txByHour[h];
      hourTops[h] = currentTop;

      if (list == null || list.isEmpty) {
        hourHeights[h] = baseHourHeight;
        txOffsetWithinHour[h] = [];
        currentTop += baseHourHeight;
        continue;
      }

      // Position cards starting at the first item's minute
      final tops = <double>[];
      final m0 = list[0].date.minute;
      final spaceBefore = (m0 / 60.0) * baseHourHeight + 6.0;
      tops.add(spaceBefore);

      for (var i = 1; i < list.length; i++) {
        final prevTop = tops[i - 1];
        final prevMin = list[i - 1].date.minute;
        final curMin = list[i].date.minute;
        final minuteDelta = ((curMin - prevMin) / 60.0) * baseHourHeight;
        final nextTop = math.max(
          prevTop + cardHeight + cardSpacing,
          prevTop + cardHeight + minuteDelta,
        );
        tops.add(nextTop);
      }

      final lastMin = list.last.date.minute;
      final spaceAfter = math.max(12.0, ((60 - lastMin) / 60.0) * baseHourHeight);
      final double hHeight = tops.last + cardHeight + spaceAfter;

      hourHeights[h] = hHeight;
      txOffsetWithinHour[h] = tops;
      currentTop += hHeight;
    }
    final double totalHeight = currentTop + 36.0;

    // Helper to convert any DateTime to vertical offset on this dynamic timeline
    double timeToOffset(DateTime dt) {
      final h = dt.hour;
      if (h < minHour) return 0.0;
      if (h > maxHour) return totalHeight - 36.0;
      final baseTop = hourTops[h] ?? 0.0;
      final hHeight = hourHeights[h] ?? baseHourHeight;
      final list = txByHour[h];
      final tops = txOffsetWithinHour[h];

      if (list == null || list.isEmpty || tops == null || tops.isEmpty) {
        return baseTop + (dt.minute / 60.0) * hHeight;
      }

      final m = dt.minute.toDouble() + (dt.second / 60.0);
      final m0 = list[0].date.minute.toDouble();
      final mLast = list.last.date.minute.toDouble();

      // Before the first transaction: interpolate from 0 to tops[0]
      if (m <= m0) {
        final ratio = m0 > 0 ? (m / m0) : 0.0;
        return baseTop + ratio * tops[0];
      }

      // After the last transaction: interpolate from (tops.last + cardHeight) to hHeight
      if (m >= mLast) {
        final lastEnd = tops.last + cardHeight;
        final remMin = 60.0 - mLast;
        final ratio = remMin > 0 ? ((m - mLast) / remMin) : 0.0;
        return baseTop + lastEnd + ratio * (hHeight - lastEnd);
      }

      // Between transactions:
      for (var i = 0; i < list.length - 1; i++) {
        final mi = list[i].date.minute.toDouble();
        final miNext = list[i + 1].date.minute.toDouble();
        if (m >= mi && m <= miNext) {
          final curEnd = tops[i] + cardHeight;
          final nextStart = tops[i + 1];
          if (curEnd >= nextStart) {
            return baseTop + tops[i];
          }
          final spanMin = miNext - mi;
          final ratio = spanMin > 0 ? ((m - mi) / spanMin) : 0.0;
          return baseTop + curEnd + ratio * (nextStart - curEnd);
        }
      }

      return baseTop + (dt.minute / 60.0) * hHeight;
    }

    // Position shifts
    final shiftEvents = <_PositionedTimelineEvent>[];
    for (final s in shifts) {
      final sTop = timeToOffset(s.date);
      final rawDurMin = s.endDate != null
          ? s.endDate!.difference(s.date).inMinutes
          : (s.durationMinutes > 0 ? s.durationMinutes : 480);
      final durMin = rawDurMin.clamp(30, 24 * 60);
      final sEndDate = s.endDate ?? s.date.add(Duration(minutes: durMin));
      final sBottom = timeToOffset(sEndDate);
      final sHeight = (sBottom - sTop).clamp(44.0, totalHeight);
      shiftEvents.add(_PositionedTimelineEvent(item: s, top: sTop, height: sHeight));
    }

    shiftEvents.sort((a, b) => a.top.compareTo(b.top));

    for (final s in shiftEvents) {
      s.col = 0;
      s.totalCols = 2; // Split width if concurrent transactions exist
    }

    // Position transactions strictly inside their hour gap
    final txEvents = <_PositionedTimelineEvent>[];
    for (final h in hours) {
      final list = txByHour[h];
      if (list == null || list.isEmpty) continue;

      final hTop = hourTops[h] ?? 0.0;
      final hHeight = hourHeights[h] ?? baseHourHeight;

      // Check if any shift overlaps with this hour
      final overlapsWithShift = shiftEvents.any((s) => s.top < (hTop + hHeight) && s.bottom > hTop);

      for (var i = 0; i < list.length; i++) {
        final it = list[i];
        final relativeTop = txOffsetWithinHour[h]?[i] ?? 6.0;
        final top = hTop + relativeTop;

        final ev = _PositionedTimelineEvent(item: it, top: top, height: cardHeight);
        if (overlapsWithShift) {
          ev.col = 1;
          ev.totalCols = 2;
        } else {
          ev.col = 0;
          ev.totalCols = 1;
        }
        txEvents.add(ev);
      }
    }

    // If there were shifts with no overlapping transactions, let them be full width!
    for (final s in shiftEvents) {
      final hasOverlappingTx = txEvents.any((tx) => tx.top < s.bottom && tx.bottom > s.top);
      if (!hasOverlappingTx) {
        s.col = 0;
        s.totalCols = 1;
      }
    }

    final positioned = [...shiftEvents, ...txEvents];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      CalendarItem? targetShift;
      if (shifts.isNotEmpty) {
        targetShift = shifts.firstWhere(
          (s) => s.date.isAfter(_now),
          orElse: () => shifts.first,
        );
      }
      final targetTime = targetShift?.date ?? (widget.isToday ? _now : widget.items.firstOrNull?.date);
      if (targetTime != null) {
        final offset = math.max(0.0, timeToOffset(targetTime) - 30.0);
        final maxScroll = _scrollController.position.maxScrollExtent;
        final clamped = offset.clamp(0.0, maxScroll);
        _scrollController.jumpTo(clamped);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          const double contentLeft = 52.0;
          final eventsWidth = (availableWidth - contentLeft - 4.0).clamp(100.0, 10000.0);
          final viewportHeight = math.min(totalHeight, 520.0);

          return SizedBox(
            height: viewportHeight,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: totalHeight,
                child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Grid of hour lines and labels positioned dynamically
                for (final h in hours) ...[
                  Positioned(
                    top: hourTops[h]!,
                    left: 0,
                    right: 0,
                    height: hourHeights[h]!,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            _formatHourLabel(h),
                            style: text.labelSmall?.copyWith(
                              color: (widget.isToday && _now.hour == h)
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant.withValues(alpha: 0.75),
                              fontWeight: (widget.isToday && _now.hour == h)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            margin: const EdgeInsets.only(top: 8),
                            color: scheme.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 2. Events overlay positioned according to start time & duration
                for (final ev in positioned)
                  Positioned(
                    top: ev.top,
                    left: contentLeft + (ev.col * (eventsWidth / ev.totalCols)),
                    width: (eventsWidth / ev.totalCols) - 4.0,
                    height: ev.height,
                    child: _TimelineEventBlock(
                      item: ev.item,
                      baseCurrency: widget.baseCurrency,
                      blockHeight: ev.height,
                    ),
                  ),

                // 3. Horizontal current time pointer (Red line + circle dot)
                if (widget.isToday && _now.hour >= minHour && _now.hour <= maxHour)
                  Positioned(
                    top: timeToOffset(_now).clamp(0.0, totalHeight - 2),
                    left: 42,
                    right: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
  }

  String _formatHourLabel(int hour) {
    return AppStrings.current().formatHourLabel(hour);
  }
}

class _PositionedTimelineEvent {
  _PositionedTimelineEvent({
    required this.item,
    required this.top,
    required this.height,
  });

  final CalendarItem item;
  double top;
  final double height;
  int col = 0;
  int totalCols = 1;

  double get bottom => top + height;
}

class _TimelineEventBlock extends StatelessWidget {
  const _TimelineEventBlock({
    required this.item,
    required this.baseCurrency,
    required this.blockHeight,
  });

  final CalendarItem item;
  final String baseCurrency;
  final double blockHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isShift = item.type == CalendarItemType.shift;
    final timeStr = item.endDate != null
        ? '${AppDate.timeOnly(item.date)} – ${AppDate.timeOnly(item.endDate!)}'
        : AppDate.timeOnly(item.date);

    // Color definitions according to user specifications:
    // Shift: grayed container with strong charcoal/slate left border
    // Income: green container with strong green left border
    // Expense: red container with strong red left border
    // Bill: blue container with strong blue left border
    // Goal: purple container with strong purple left border
    final Color strongBorderColor;
    final Color backgroundColor;

    switch (item.type) {
      case CalendarItemType.shift:
        strongBorderColor = isDark ? const Color(0xFF71717A) : const Color(0xFF52525B);
        backgroundColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF1F2F4);
        break;
      case CalendarItemType.income:
        strongBorderColor = const Color(0xFF16A34A);
        backgroundColor = const Color(0xFF16A34A).withValues(alpha: isDark ? 0.22 : 0.12);
        break;
      case CalendarItemType.expense:
        strongBorderColor = const Color(0xFFDC2626);
        backgroundColor = const Color(0xFFDC2626).withValues(alpha: isDark ? 0.22 : 0.12);
        break;
      case CalendarItemType.bill:
        strongBorderColor = const Color(0xFF2563EB);
        backgroundColor = const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.12);
        break;
      case CalendarItemType.goal:
        strongBorderColor = const Color(0xFF7C3AED);
        backgroundColor = const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.22 : 0.12);
        break;
    }

    final String typeTag;
    final IconGlyph typeIcon;
    switch (item.type) {
      case CalendarItemType.shift:
        typeTag = tr.workShiftTag;
        typeIcon = HugeIcons.strokeRoundedClock01;
        break;
      case CalendarItemType.income:
        typeTag = tr.income;
        typeIcon = HugeIcons.strokeRoundedArrowDownLeft01;
        break;
      case CalendarItemType.expense:
        typeTag = tr.expense;
        typeIcon = HugeIcons.strokeRoundedArrowUpRight01;
        break;
      case CalendarItemType.bill:
        typeTag = tr.billTag;
        typeIcon = HugeIcons.strokeRoundedRepeat;
        break;
      case CalendarItemType.goal:
        typeTag = tr.goalTag;
        typeIcon = HugeIcons.strokeRoundedTarget02;
        break;
    }

    String? statusBadge;
    Color statusBadgeColor = strongBorderColor;
    if (isShift) {
      if (item.status == 'in_progress') {
        statusBadge = tr.inProgress;
        statusBadgeColor = const Color(0xFF16A34A);
      } else if (item.status == 'completed') {
        statusBadge = tr.completedStatus;
        statusBadgeColor = scheme.onSurfaceVariant;
      } else {
        statusBadge = tr.scheduledStatus;
        statusBadgeColor = strongBorderColor;
      }
    }

    final displayTitle = (isShift && (item.title == 'Shift' || item.title == 'Work Shift' || item.title.trim().isEmpty))
        ? tr.workShiftTag
        : item.title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showItemDetailsSheet(context, item),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.zero, // Squared shaped as requested
            border: Border(
              left: BorderSide(color: strongBorderColor, width: 5.0), // Left border only
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.sm + 2,
            vertical: blockHeight < 56 ? 2 : 6,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: _buildEventContent(
                  context: context,
                  scheme: scheme,
                  text: text,
                  tr: tr,
                  isShift: isShift,
                  displayTitle: displayTitle,
                  timeStr: timeStr,
                  typeTag: typeTag,
                  typeIcon: typeIcon,
                  strongBorderColor: strongBorderColor,
                  statusBadge: statusBadge,
                  statusBadgeColor: statusBadgeColor,
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventContent({
    required BuildContext context,
    required ColorScheme scheme,
    required TextTheme text,
    required AppStrings tr,
    required bool isShift,
    required String displayTitle,
    required String timeStr,
    required String typeTag,
    required IconGlyph typeIcon,
    required Color strongBorderColor,
    required String? statusBadge,
    required Color statusBadgeColor,
    required double maxWidth,
    required double maxHeight,
  }) {
    // 0. Ultra-compact single row if height is very tight (< 38px)
    if (maxHeight < 38) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            color: strongBorderColor,
            child: Text(
              typeTag.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 8,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              displayTitle,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isShift) ...[
            const SizedBox(width: 4),
            _buildAmountText(text, scheme),
          ] else ...[
            const SizedBox(width: 4),
            Text(
              timeStr,
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
              maxLines: 1,
            ),
          ],
        ],
      );
    }

    // 1. Narrow column responsive layout (< 160px)
    if (maxWidth < 160) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    color: strongBorderColor,
                    child: Text(
                      typeTag.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8.5),
                    ),
                  ),
                  const Spacer(),
                  if (!isShift) _buildAmountText(text, scheme),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                displayTitle,
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  AppIcon(HugeIcons.strokeRoundedClock01, size: 9, color: strongBorderColor),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      timeStr,
                      style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 9.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 2. Standard event layout (< 105px, including 56px transaction blocks)
    if (blockHeight < 105) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: strongBorderColor,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(typeIcon, size: 10, color: Colors.white),
                        const SizedBox(width: 3.5),
                        Text(
                          typeTag.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isShift) ...[
                    const SizedBox(width: 6),
                    _buildAmountText(text, scheme),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  AppIcon(
                    HugeIcons.strokeRoundedClock01,
                    size: 11,
                    color: strongBorderColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5,
                    ),
                  ),
                  if (isShift && item.durationMinutes > 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      '(${tr.localizeDigits((item.durationMinutes / 60).toStringAsFixed(1))}${tr.hourAbbr})',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                  if (statusBadge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusBadgeColor.withValues(alpha: 0.15),
                        border: Border.all(color: statusBadgeColor.withValues(alpha: 0.4), width: 0.8),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        statusBadge,
                        style: text.labelSmall?.copyWith(
                          color: statusBadgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 3. Tall continuous layout (height >= 105px, e.g. 480px 9 to 5 shift!)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: strongBorderColor,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(typeIcon, size: 10.5, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    typeTag.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                displayTitle,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (statusBadge != null) ...[
              const SizedBox(width: AppSpace.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBadgeColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusBadgeColor.withValues(alpha: 0.4), width: 0.8),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  statusBadge,
                  style: text.labelSmall?.copyWith(
                    color: statusBadgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
            if (!isShift) ...[
              const SizedBox(width: 8),
              _buildAmountText(text, scheme),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedClock01,
                  size: 13,
                  color: strongBorderColor,
                ),
                const SizedBox(width: 5),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            if (isShift && item.durationMinutes > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  tr.hoursDurationLabel(tr.localizeDigits((item.durationMinutes / 60).toStringAsFixed(1))),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ),
          ],
        ),
        if (blockHeight >= 160) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.7),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_outlined, size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  isShift ? tr.tapToManageShift : tr.tapToViewDetails,
                  style: text.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountText(TextTheme text, ColorScheme scheme) {
    if (item.type == CalendarItemType.shift) {
      return const SizedBox.shrink();
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: MoneyText(
        item.isIncome ? item.amountMinor : -item.amountMinor,
        item.currencyCode,
        signed: true,
        style: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: item.isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  void _showItemDetailsSheet(BuildContext context, CalendarItem item) {
    final tr = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: item.type == CalendarItemType.shift
                          ? const Color(0xFF52525B)
                          : item.isIncome
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                      child: Text(
                        switch (item.type) {
                          CalendarItemType.shift => tr.shiftLabel.toUpperCase(),
                          CalendarItemType.expense => tr.expense.toUpperCase(),
                          CalendarItemType.income => tr.income.toUpperCase(),
                          CalendarItemType.bill => tr.billTagLabel.toUpperCase(),
                          CalendarItemType.goal => tr.goalLabel.toUpperCase(),
                        },
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  '${AppDate.short(item.date)} · ${item.subtitle}',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  tr.amountWithValue(MoneyFormatter.format(item.amountMinor, item.currencyCode)),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    if (item.type == CalendarItemType.shift) ...[
                      if (item.status == ShiftStatus.scheduled.value) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const AppIcon(HugeIcons.strokeRoundedEdit02, size: 16),
                            label: Text(tr.editShift),
                            onPressed: () {
                              Navigator.pop(ctx);
                              final workVm = getIt<WorkViewModel>();
                              final shift = workVm.shifts.where((s) => s.id == item.rawId).firstOrNull;
                              final job = shift != null ? workVm.jobsById[shift.jobId] : null;
                              if (shift != null) {
                                showEditShiftDialog(context, shift, job, workVm);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.work_outline, size: 16),
                          label: Text(tr.viewInWork),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go(AppRoutes.work);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(tr.closeAction),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

