import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class ShiftDoneScreen extends StatelessWidget {
  const ShiftDoneScreen({super.key, required this.shiftId, this.earnings});

  final int shiftId;
  final ShiftEarnings? earnings;

  String _formatDurationMinutes(int totalMinutes, AppStrings tr) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '$h${tr.hourAbbr} $m${tr.minuteAbbr}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final tr = context.strings;

    final shift = viewModel.shifts.firstWhere(
      (s) => s.id == shiftId,
      orElse: () => viewModel.shifts.first,
    );
    final job = viewModel.jobsById[shift.jobId];
    final currency = job?.currencyCode ?? viewModel.baseCurrency;

    final calculated = earnings ?? (job != null ? ShiftEarnings.forShift(shift, job) : null);

    final startTime = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
    final endTime = shift.endAt != null
        ? DateTime.fromMillisecondsSinceEpoch(shift.endAt!)
        : DateTime.now();
    final totalClockMinutes = endTime.difference(startTime).inMinutes.clamp(0, 100000);
    final workedMinutes = calculated?.workedMinutes ?? 0;
    final breakMinutes = shift.breakMinutes;
    final baseRateMinor = shift.rateOverrideMinor ?? job?.hourlyRateMinor ?? 0;
    final timeFmt = DateFormat('h:mm a');

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.shiftLogTitle),
          leading: BackButton(onPressed: handleBack),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: FutureBuilder<List<ShiftBreak>>(
            future: viewModel.breaksForShift(shiftId),
            builder: (context, snapshot) {
              final breaks = snapshot.data ?? const <ShiftBreak>[];

              // Build chronological timeline entries
              final timelineItems = <_ShiftTimelineEntry>[
                _ShiftTimelineEntry(
                  timeLabel: timeFmt.format(startTime),
                  title: tr.clockedInEvent,
                  subtitle: '${job?.name ?? tr.activeShift} · ${MoneyFormatter.format(baseRateMinor, currency)}/${tr.hourAbbr}',
                  icon: HugeIcons.strokeRoundedPlay,
                  accent: colors.brand,
                ),
              ];

              if (breaks.isNotEmpty) {
                for (final b in breaks) {
                  final bStart = DateTime.fromMillisecondsSinceEpoch(b.startAt);
                  final bEnd = b.endAt != null
                      ? DateTime.fromMillisecondsSinceEpoch(b.endAt!)
                      : endTime;
                  final bMins = ShiftTimeline.breakMinutesOf(b, now: endTime);
                  timelineItems.add(
                    _ShiftTimelineEntry(
                      timeLabel: '${timeFmt.format(bStart)} – ${timeFmt.format(bEnd)}',
                      title: tr.breakSegmentLabel,
                      subtitle: _formatDurationMinutes(bMins, tr),
                      icon: HugeIcons.strokeRoundedCoffee01,
                      accent: colors.warning,
                    ),
                  );
                }
              } else if (breakMinutes > 0) {
                timelineItems.add(
                  _ShiftTimelineEntry(
                    timeLabel: '$breakMinutes${tr.minuteAbbr}',
                    title: tr.breakSegmentLabel,
                    subtitle: _formatDurationMinutes(breakMinutes, tr),
                    icon: HugeIcons.strokeRoundedCoffee01,
                    accent: colors.warning,
                  ),
                );
              }

              if (calculated != null && calculated.hasOvertime) {
                final otThreshold = shift.overtimeThresholdMinutes ?? calculated.regularMinutes;
                final otReachedAt = startTime.add(Duration(minutes: otThreshold + breakMinutes));
                timelineItems.add(
                  _ShiftTimelineEntry(
                    timeLabel: timeFmt.format(otReachedAt),
                    title: tr.overtimeReachedEvent,
                    subtitle: '${_formatDurationMinutes(calculated.overtimeMinutes, tr)} @ ${MoneyFormatter.format(calculated.overtimeRateMinor, currency)}/${tr.hourAbbr}',
                    icon: HugeIcons.strokeRoundedFlash,
                    accent: colors.brand,
                  ),
                );
              }

              timelineItems.add(
                _ShiftTimelineEntry(
                  timeLabel: timeFmt.format(endTime),
                  title: tr.clockedOutEvent,
                  subtitle: '+${MoneyFormatter.format(calculated?.earningsMinor ?? 0, currency)}',
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  accent: colors.income,
                ),
              );

              return ListView(
                padding: const EdgeInsets.all(AppSpace.page),
                children: [
                  // Summary Header Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppDate.header(startTime),
                                    style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job?.name ?? tr.activeShift,
                                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              tr.statusCompleted,
                              tone: ChipTone.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          tr.earned.toUpperCase(),
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${MoneyFormatter.format(calculated?.earningsMinor ?? 0, currency)}',
                          style: text.displaySmall?.copyWith(
                            color: colors.income,
                            fontFamily: 'RedditMono',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Hours & Break Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: tr.totalClockTime,
                          value: _formatDurationMinutes(totalClockMinutes, tr),
                          subValue: '${timeFmt.format(startTime)} – ${timeFmt.format(endTime)}',
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _MetricTile(
                          label: tr.netWorkedTime,
                          value: _formatDurationMinutes(workedMinutes, tr),
                          subValue: '${tr.analyticsBreakTime}: ${_formatDurationMinutes(breakMinutes, tr)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Regular vs Overtime Pay Row
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: tr.regularPayLabel,
                          value: MoneyFormatter.format(
                            calculated?.regularEarningsMinor ?? calculated?.earningsMinor ?? 0,
                            currency,
                          ),
                          subValue: _formatDurationMinutes(
                            calculated?.regularMinutes ?? workedMinutes,
                            tr,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _MetricTile(
                          label: tr.overtimePayLabel,
                          value: MoneyFormatter.format(
                            calculated?.overtimeEarningsMinor ?? 0,
                            currency,
                          ),
                          subValue: _formatDurationMinutes(
                            calculated?.overtimeMinutes ?? 0,
                            tr,
                          ),
                          valueColor: (calculated?.hasOvertime ?? false) ? colors.brand : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // Shift Timeline Log Section
                  SectionHeader(tr.shiftTimelineTitle),
                  const SizedBox(height: AppSpace.sm),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < timelineItems.length; i++)
                          _TimelineStepRow(
                            entry: timelineItems[i],
                            isLast: i == timelineItems.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.page),
            child: AppButton(
              tr.done,
              onPressed: handleBack,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.subValue,
    this.valueColor,
  });

  final String label;
  final String value;
  final String subValue;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: text.titleMedium?.copyWith(
              fontFamily: 'RedditMono',
              fontWeight: FontWeight.w700,
              color: valueColor ?? scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ShiftTimelineEntry {
  const _ShiftTimelineEntry({
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String timeLabel;
  final String title;
  final String subtitle;
  final dynamic icon;
  final Color accent;
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.entry,
    required this.isLast,
  });

  final _ShiftTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: entry.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: entry.icon,
                  color: entry.accent,
                  size: 16,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        entry.timeLabel,
                        style: text.labelSmall?.copyWith(
                          fontFamily: 'RedditMono',
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
