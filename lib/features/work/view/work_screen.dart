import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/view/widgets/edit_shift_sheet.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;
        final activeShift = viewModel.activeShift;

        return TabPage(
          title: tr.work,
          overline: tr.shiftsAndJobs,
          children: [
            // Active shift banner (if clocked in)
            if (activeShift != null) ...[
              () {
                final activeJob = viewModel.jobsById[activeShift.jobId];
                final activeStart = DateTime.fromMillisecondsSinceEpoch(activeShift.startAt);
                final activeCurrency = activeJob?.currencyCode ?? viewModel.baseCurrency;
                final activeRateMinor = activeShift.rateOverrideMinor ?? activeJob?.hourlyRateMinor ?? 0;
                final liveEarnings = viewModel.activeShiftLiveEarnings;
                final isStartedToday = AppDate.isSameDay(activeStart, DateTime.now());
                final startedAtStr = isStartedToday
                    ? AppDate.timeOnly(activeStart)
                    : '${AppDate.short(activeStart)}, ${AppDate.timeOnly(activeStart)}';

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconTile(HugeIcons.strokeRoundedBriefcase01, size: 38),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeJob?.name ?? tr.activeShift,
                                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${tr.startedAt(startedAtStr)} · ${MoneyFormatter.format(activeRateMinor, activeCurrency)}/${tr.hourAbbr}',
                                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            viewModel.isOnBreak ? tr.takeBreak : tr.running,
                            tone: viewModel.isOnBreak ? ChipTone.warning : ChipTone.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      ListenableBuilder(
                        listenable: viewModel.liveTick,
                        builder: (context, _) {
                          final tickEarnings = viewModel.activeShiftLiveEarnings;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                tr.localizeDigits(_formatDuration(viewModel.activeShiftElapsed)),
                                style: text.displaySmall?.copyWith(
                                  fontFamily: 'RedditMono',
                                  fontWeight: FontWeight.w700,
                                  color: viewModel.isOnBreak ? scheme.onSurfaceVariant : null,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.incomeBg.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Text(
                                  '≈ ${MoneyFormatter.format(tickEarnings?.earningsMinor ?? liveEarnings?.earningsMinor ?? 0, activeCurrency)}',
                                  style: text.titleSmall?.copyWith(
                                    fontFamily: 'RedditMono',
                                    fontWeight: FontWeight.w700,
                                    color: colors.income,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              tr.viewLiveShift,
                              onPressed: () => context.push(AppRoutes.liveShift),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }(),
              const SizedBox(height: AppSpace.xl),
            ],

            if (viewModel.jobs.isEmpty)
              EmptyState(
                illustration: EmptyIllustration.jobs,
                icon: HugeIcons.strokeRoundedBriefcase01,
                title: tr.noJobsYet,
                message: tr.addJobToTrack,
                actionLabel: tr.addJob,
                onAction: () => context.push(AppRoutes.addJob),
              )
            else ...[
              if (viewModel.jobs.length == 1) ...[
                SectionHeader(
                  tr.workplaceJob,
                  actionLabel: tr.addJob,
                  onAction: () => context.push(AppRoutes.addJob),
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListRow(
                    leading: const IconTile(HugeIcons.strokeRoundedBriefcase01, size: 40),
                    title: viewModel.jobs.first.name,
                    subtitle:
                        '${MoneyFormatter.format(viewModel.jobs.first.hourlyRateMinor, viewModel.jobs.first.currencyCode)}/${tr.hourAbbr}',
                    trailing: StatusChip(tr.activeBadge, tone: ChipTone.success),
                    onTap: () => context.push(AppRoutes.manageJobs),
                  ),
                ),
              ] else ...[
                SectionHeader(
                  tr.whichJobStarting,
                  actionLabel: tr.addJob,
                  onAction: () => context.push(AppRoutes.addJob),
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpace.sm,
                    mainAxisSpacing: AppSpace.sm,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: viewModel.jobs.length,
                  itemBuilder: (context, index) {
                    final job = viewModel.jobs[index];
                    final isSelected = viewModel.selectedJob?.id == job.id;
                    return _WorkJobGridCard(
                      job: job,
                      isSelected: isSelected,
                      onTap: () => viewModel.selectJob(job.id),
                    );
                  },
                ),
              ],

              const SizedBox(height: AppSpace.md),
              if (activeShift != null)
                AppButton(
                  tr.scheduleShift,
                  icon: HugeIcons.strokeRoundedCalendar03,
                  kind: AppButtonKind.secondary,
                  onPressed: () => context.push(AppRoutes.scheduleShift),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        '${tr.startShift}: ${viewModel.selectedJob?.name ?? ""}',
                        icon: HugeIcons.strokeRoundedPlay,
                        onPressed: () => context.push(AppRoutes.startShift),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: AppButton(
                        tr.scheduleShift,
                        icon: HugeIcons.strokeRoundedCalendar03,
                        kind: AppButtonKind.secondary,
                        onPressed: () => context.push(AppRoutes.scheduleShift),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: AppSpace.xxl),
              // Weekly stats card
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr.hoursThisWeek, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            '${tr.localizeDigits(viewModel.hoursThisWeek.toStringAsFixed(1))} ${tr.hourAbbr}',
                            style: text.headlineSmall?.copyWith(
                              fontFamily: 'RedditMono',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr.shiftsLeft, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            tr.formatNumber(viewModel.shiftsLeftThisWeek),
                            style: text.headlineSmall?.copyWith(
                              fontFamily: 'RedditMono',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpace.xl),

              // Today's Shifts Section
              Row(
                children: [
                  Text(tr.todayShifts, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.fill,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      tr.formatNumber(viewModel.todayTotalCount),
                      style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    ),
                    icon: const AppIcon(HugeIcons.strokeRoundedCalendar03, size: 15),
                    label: Text(tr.calendar, style: const TextStyle(fontSize: 12)),
                    onPressed: () => context.go(AppRoutes.calendar),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),

              // Filter Pills for Today (only show when there are multiple shifts to filter)
              if (viewModel.todayTotalCount > 2) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ShiftFilterPill(
                        label: '${tr.allEvents} (${tr.formatNumber(viewModel.todayTotalCount)})',
                        isSelected: viewModel.filterStatus == null && viewModel.filterJobId == null,
                        onTap: () {
                          viewModel.setFilterStatus(null);
                          viewModel.setFilterJobId(null);
                        },
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _ShiftFilterPill(
                        label: '${tr.scheduled} (${tr.formatNumber(viewModel.todayScheduledCount)})',
                        isSelected: viewModel.filterStatus == ShiftStatus.scheduled.value,
                        onTap: () => viewModel.setFilterStatus(
                          viewModel.filterStatus == ShiftStatus.scheduled.value ? null : ShiftStatus.scheduled.value,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _ShiftFilterPill(
                        label: '${tr.completed} (${tr.formatNumber(viewModel.todayCompletedCount)})',
                        isSelected: viewModel.filterStatus == ShiftStatus.completed.value,
                        onTap: () => viewModel.setFilterStatus(
                          viewModel.filterStatus == ShiftStatus.completed.value ? null : ShiftStatus.completed.value,
                        ),
                      ),
                      if (viewModel.jobs.length > 1) ...[
                        const SizedBox(width: AppSpace.sm),
                        for (final j in viewModel.jobs) ...[
                          _ShiftFilterPill(
                            label: j.name,
                            isSelected: viewModel.filterJobId == j.id,
                            onTap: () => viewModel.setFilterJobId(
                              viewModel.filterJobId == j.id ? null : j.id,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],

              if (viewModel.todayShifts.isEmpty)
                AppCard(
                  child: EmptyState(
                    compact: true,
                    illustration: EmptyIllustration.shifts,
                    icon: HugeIcons.strokeRoundedCalendar03,
                    title: tr.noShiftsForToday,
                    message: tr.t(
                      'You have no scheduled or completed shifts today. Schedule one or check the Calendar tab for other days.',
                      ne: 'आज तपाईंको कुनै सिफ्ट तालिका छैन। नयाँ सिफ्ट थप्नुहोस् वा पात्रो हेर्नुहोस्।',
                      hi: 'आज आपकी कोई शिफ्ट नहीं है। नई शिफ्ट शेड्यूल करें या कैलेंडर देखें।',
                      es: 'No tienes turnos hoy. Programa uno o revisa el Calendario.',
                      fr: 'Aucun quart aujourd\'hui. Planifiez-en un ou consultez le Calendrier.',
                      de: 'Heute keine Schichten. Plane eine Schicht oder prüfe den Kalender.',
                      ja: '本日のシフトはありません。新しく予定するかカレンダーを確認してください。',
                      zh: '今天没有班次，您可以安排新班次或查看日历。',
                      it: 'Nessun turno per oggi. Pianificane uno o controlla il calendario.',
                    ),
                    actionLabel: tr.scheduleShift,
                    onAction: () => context.push(AppRoutes.scheduleShift),
                    secondaryActionLabel: tr.viewAllInCalendar,
                    onSecondaryAction: () => context.go(AppRoutes.calendar),
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < viewModel.todayShifts.length; i++) ...[
                        if (i > 0) const RowDivider(),
                        _ShiftRow(
                          shift: viewModel.todayShifts[i],
                          job: viewModel.jobsById[viewModel.todayShifts[i].jobId],
                          baseCurrency: viewModel.baseCurrency,
                          viewModel: viewModel,
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: AppSpace.xl),
            ],
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _ShiftFilterPill extends StatelessWidget {
  const _ShiftFilterPill({
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
    return Material(
      color: isSelected ? scheme.primary : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
    required this.shift,
    required this.job,
    required this.baseCurrency,
    required this.viewModel,
  });

  final Shift shift;
  final Job? job;
  final String baseCurrency;
  final WorkViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;

    final start = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
    final end = shift.endAt != null ? DateTime.fromMillisecondsSinceEpoch(shift.endAt!) : null;
    final earnings = job != null ? ShiftEarnings.forShift(shift, job!) : null;

    final isCompleted = shift.status == ShiftStatus.completed.value;
    final isInProgress = shift.status == ShiftStatus.inProgress.value;
    final timeRangeStr = '${AppDate.timeOnly(start)}${end != null ? " – ${AppDate.timeOnly(end)}" : ""}';

    final rateMinor = shift.rateOverrideMinor ?? job?.hourlyRateMinor;
    final rateStr = rateMinor != null
        ? '${MoneyFormatter.format(rateMinor, job?.currencyCode ?? baseCurrency)}/${tr.hourAbbr}'
        : null;

    final durationHours = earnings?.workedMinutes != null
        ? (earnings!.workedMinutes / 60.0)
        : (end != null ? (end.difference(start).inMinutes / 60.0) : (shift.durationMinutes / 60.0));

    final earningsStr = earnings != null && earnings.earningsMinor > 0
        ? MoneyFormatter.format(earnings.earningsMinor, job?.currencyCode ?? baseCurrency)
        : null;
    final durationStr = durationHours > 0
        ? '${tr.localizeDigits(durationHours.toStringAsFixed(1))} ${tr.hrsUnit}'
        : null;

    return InkWell(
      onTap: () => _showShiftActionsSheet(context, shift, job, viewModel),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
        child: Row(
          children: [
            IconTile(
              isCompleted
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : (isInProgress ? HugeIcons.strokeRoundedPlay : HugeIcons.strokeRoundedClock01),
              size: 40,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          job?.name ?? tr.shiftLabel,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isInProgress) ...[
                        const SizedBox(width: AppSpace.xs),
                        StatusChip(tr.activeBadge, tone: ChipTone.warning),
                      ] else if (isCompleted) ...[
                        const SizedBox(width: AppSpace.xs),
                        StatusChip(tr.statusCompleted, tone: ChipTone.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$timeRangeStr${rateStr != null ? " · $rateStr" : ""}',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompleted) ...[
                  Text(
                    earningsStr ?? durationStr ?? tr.done,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (earningsStr != null && durationStr != null) ? durationStr : tr.done,
                    style: text.bodySmall?.copyWith(
                      color: context.colors.income,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ] else if (isInProgress) ...[
                  Text(
                    earningsStr ?? durationStr ?? tr.liveBadge,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr.liveBadge,
                    style: TextStyle(
                      color: context.colors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ] else ...[
                  Text(
                    durationStr ?? timeRangeStr,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr.scheduled,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
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
}

void _showShiftActionsSheet(BuildContext context, Shift shift, Job? job, WorkViewModel viewModel) {
  final text = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;
  final colors = context.colors;
  final tr = context.strings;

  final start = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
  final end = shift.endAt != null ? DateTime.fromMillisecondsSinceEpoch(shift.endAt!) : null;
  final isCompleted = shift.status == ShiftStatus.completed.value;
  final isScheduled = shift.status == ShiftStatus.scheduled.value;
  final earnings = job != null ? ShiftEarnings.forShift(shift, job) : null;
  final timeRangeStr = '${AppDate.timeOnly(start)}${end != null ? "–${AppDate.timeOnly(end)}" : ""}';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.page,
          AppSpace.page,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpace.page,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(HugeIcons.strokeRoundedClock01, size: 40),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job?.name ?? tr.activeShift, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        '${AppDate.weekdayDay(start)} · $timeRangeStr',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  isCompleted ? tr.completed : (isScheduled ? tr.scheduled : tr.inProgress),
                  tone: isCompleted ? ChipTone.success : (isScheduled ? ChipTone.neutral : ChipTone.warning),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpace.md),

            // Details summary card
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.duration, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(
                        '${tr.localizeDigits(earnings?.workedMinutes != null ? (earnings!.workedMinutes / 60).toStringAsFixed(1) : (end != null ? (end.difference(start).inMinutes / 60).toStringAsFixed(1) : "—"))} ${tr.hoursUnit}',
                        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.breakTime, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      Text('${tr.formatNumber(shift.breakMinutes)} ${tr.minsUnit}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr.hourlyRate, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(
                        MoneyFormatter.format(shift.rateOverrideMinor ?? job?.hourlyRateMinor ?? 0, job?.currencyCode ?? viewModel.baseCurrency),
                        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isCompleted ? tr.earnedTotal : tr.projectedPay, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(
                        MoneyFormatter.format(earnings?.earningsMinor ?? (job != null ? job.hourlyRateMinor * 4 : 0), job?.currencyCode ?? viewModel.baseCurrency),
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.income,
                        ),
                      ),
                    ],
                  ),
                  if (shift.note != null && shift.note!.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr.notes, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            shift.note!,
                            textAlign: TextAlign.end,
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // Action buttons (stacked vertically in full-width Column per design system)
            if (isScheduled) ...[
              AppButton(
                tr.startShiftNow,
                icon: HugeIcons.strokeRoundedPlay,
                onPressed: () async {
                  try {
                    await viewModel.startScheduledShift(shift);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) context.push(AppRoutes.liveShift);
                  } catch (e) {
                    if (context.mounted) showErrorToast(context, tr.couldNotSave('$e'));
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                tr.markAsCompleted,
                kind: AppButtonKind.secondary,
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                onPressed: () async {
                  try {
                    await viewModel.updateShift(
                      shift.id,
                      status: ShiftStatus.completed,
                      endAt: shift.endAt != null
                          ? DateTime.fromMillisecondsSinceEpoch(shift.endAt!)
                          : DateTime.fromMillisecondsSinceEpoch(shift.startAt).add(const Duration(hours: 4)),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) showToast(context, tr.shiftMarkedCompleted);
                  } catch (e) {
                    if (context.mounted) showErrorToast(context, tr.couldNotSave('$e'));
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
            ],

            AppButton(
              tr.editShift,
              kind: AppButtonKind.outline,
              icon: HugeIcons.strokeRoundedEdit02,
              onPressed: () {
                Navigator.pop(ctx);
                showEditShiftDialog(context, shift, job, viewModel);
              },
            ),
            const SizedBox(height: AppSpace.sm),
            AppButton(
              tr.delete,
              kind: AppButtonKind.danger,
              icon: HugeIcons.strokeRoundedDelete02,
              onPressed: () async {
                Navigator.pop(ctx);
                final confirmed = await showConfirmDialog(
                  context,
                  title: tr.deleteThisShift,
                  message: tr.t(
                    'This will remove the shift on ${AppDate.short(start)} for ${job?.name ?? "Job"}.',
                    ne: 'यसले ${AppDate.short(start)} को ${job?.name ?? "काम"} सिफ्ट हटाउनेछ।',
                    hi: 'यह ${AppDate.short(start)} की ${job?.name ?? "जॉब"} शिफ्ट हटा देगा।',
                    es: 'Esto eliminará el turno del ${AppDate.short(start)} para ${job?.name ?? "Empleo"}.',
                    fr: 'Cela supprimera le quart du ${AppDate.short(start)} pour ${job?.name ?? "Travail"}.',
                    de: 'Dies entfernt die Schicht am ${AppDate.short(start)} für ${job?.name ?? "Job"}.',
                    ja: '${AppDate.short(start)} の ${job?.name ?? "仕事"} のシフトが削除されます。',
                    zh: '这将删除 ${job?.name ?? "工作"} 于 ${AppDate.short(start)} 的班次。',
                    it: 'Questo rimuoverà il turno del ${AppDate.short(start)} per ${job?.name ?? "Lavoro"}.',
                  ),
                  confirmLabel: tr.delete,
                  destructive: true,
                );
                if (confirmed && context.mounted) {
                  try {
                    await viewModel.deleteShift(shift.id);
                    if (context.mounted) {
                      showToast(
                        context,
                        tr.shiftDeleted,
                        actionLabel: tr.undo,
                        onAction: () async {
                          await viewModel.scheduleShift(
                            jobId: shift.jobId,
                            startAt: start,
                            endAt: end,
                            breakMinutes: shift.breakMinutes,
                            note: shift.note,
                            rateOverrideMinor: shift.rateOverrideMinor,
                            overtimeThresholdMinutes: shift.overtimeThresholdMinutes,
                            overtimeRateMinor: shift.overtimeRateMinor,
                            longShiftAlertMinutes: shift.longShiftAlertMinutes,
                            status: ShiftStatus.fromValue(shift.status),
                          );
                        },
                      );
                    }
                  } catch (e) {
                    if (context.mounted) showErrorToast(context, tr.couldNotSave('$e'));
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _WorkJobGridCard extends StatelessWidget {
  const _WorkJobGridCard({
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final Job job;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final tr = context.strings;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? scheme.primary.withValues(alpha: 0.08) : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: AppIcon(
                        HugeIcons.strokeRoundedBriefcase01,
                        size: 16,
                        color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? scheme.primary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)} /${tr.hourAbbr}',
                      style: text.bodySmall?.copyWith(
                        fontFamily: 'RedditMono',
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


