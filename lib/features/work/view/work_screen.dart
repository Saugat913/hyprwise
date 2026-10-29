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
                      Row(
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
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '≈ ${MoneyFormatter.format(liveEarnings?.earningsMinor ?? 0, activeCurrency)}',
                              style: text.titleSmall?.copyWith(
                                fontFamily: 'RedditMono',
                                fontWeight: FontWeight.w700,
                                color: colors.income,
                              ),
                            ),
                          ),
                        ],
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
                icon: HugeIcons.strokeRoundedBriefcase01,
                title: tr.noJobsYet,
                message: tr.addJobToTrack,
                actionLabel: tr.addJob,
                onAction: () => context.push(AppRoutes.addJob),
              )
            else ...[
              Text(
                tr.whichJobStarting,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.md),

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

              const SizedBox(height: AppSpace.md),
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
                      borderRadius: BorderRadius.circular(AppRadius.pill),
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
                Container(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      const AppIcon(HugeIcons.strokeRoundedCalendar03, size: 28, color: Colors.grey),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        tr.noShiftsForToday,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr.t(
                          'You have no scheduled or completed shifts today.\nCheck the Calendar tab to see other days.',
                          ne: 'आज तपाईंको कुनै सिफ्ट तालिका छैन।\nअन्य दिन हेर्न पात्रो ट्याब खोल्नुहोस्।',
                          es: 'No tienes turnos programados o completados hoy.\nRevisa el Calendario para otros días.',
                          fr: 'Aucun quart prévu ou terminé aujourd\'hui.\nConsultez le Calendrier pour d\'autres jours.',
                          de: 'Heute keine geplanten oder abgeschlossenen Schichten.\nPrüfen Sie den Kalender für andere Tage.',
                          ja: '本日の予定または完了したシフトはありません。\n他の日はカレンダーで確認してください。',
                          zh: '今天没有已安排或已完成的班次。\n请查看日历以了解其他日期的日程。',
                          it: 'Nessun turno programmato o completato per oggi.\nControlla il calendario per gli altri giorni.',
                        ),
                        textAlign: TextAlign.center,
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpace.md),
                      OutlinedButton.icon(
                        icon: const AppIcon(HugeIcons.strokeRoundedCalendar03, size: 16),
                        label: Text(tr.viewAllInCalendar),
                        onPressed: () => context.go(AppRoutes.calendar),
                      ),
                    ],
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

              const SizedBox(height: AppSpace.md),
              Center(
                child: TextButton.icon(
                  icon: const AppIcon(HugeIcons.strokeRoundedCalendar03, size: 16),
                  label: Text(tr.viewFullScheduleInCalendar),
                  onPressed: () => context.go(AppRoutes.calendar),
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
    final timeRangeStr = '${AppDate.timeOnly(start)}${end != null ? "–${AppDate.timeOnly(end)}" : ""}';

    final rateMinor = shift.rateOverrideMinor ?? job?.hourlyRateMinor;
    final rateStr = rateMinor != null
        ? '${MoneyFormatter.format(rateMinor, job?.currencyCode ?? baseCurrency)}/${tr.hourAbbr}'
        : null;

    final durationHours = earnings?.workedMinutes != null
        ? (earnings!.workedMinutes / 60.0)
        : (end != null ? (end.difference(start).inMinutes / 60.0) : (shift.durationMinutes / 60.0));

    return InkWell(
      onTap: () => _showShiftActionsSheet(context, shift, job, viewModel),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            IconTile(HugeIcons.strokeRoundedClock01, size: 36),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        job?.name ?? tr.shiftLabel,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (shift.status == ShiftStatus.inProgress.value) ...[
                        const SizedBox(width: AppSpace.xs),
                        StatusChip(tr.activeBadge, tone: ChipTone.warning),
                      ] else if (isCompleted) ...[
                        const SizedBox(width: AppSpace.xs),
                        StatusChip(tr.statusCompleted, tone: ChipTone.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppDate.weekdayDay(start)} · $timeRangeStr${rateStr != null ? " · $rateStr" : ""}',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (durationHours > 0)
                  Text(
                    '${tr.localizeDigits(durationHours.toStringAsFixed(1))} ${tr.hrsUnit}',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  )
                else
                  Text(
                    timeRangeStr,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                if (isCompleted) ...[
                  const SizedBox(height: 2),
                  Text(
                    tr.done,
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ] else if (shift.status == ShiftStatus.inProgress.value) ...[
                  const SizedBox(height: 2),
                  Text(
                    tr.liveBadge,
                    style: const TextStyle(
                      color: Color(0xFFEAB308),
                      fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.page),
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

            // Action buttons
            if (isScheduled) ...[
              AppButton(
                tr.startShiftNow,
                icon: HugeIcons.strokeRoundedPlay,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await viewModel.startShift(jobId: shift.jobId);
                  if (context.mounted) context.push(AppRoutes.liveShift);
                },
              ),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                tr.markAsCompleted,
                kind: AppButtonKind.secondary,
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await viewModel.updateShift(
                    shift.id,
                    status: ShiftStatus.completed,
                    endAt: shift.endAt != null
                        ? DateTime.fromMillisecondsSinceEpoch(shift.endAt!)
                        : DateTime.fromMillisecondsSinceEpoch(shift.startAt).add(const Duration(hours: 4)),
                  );
                  if (context.mounted) showToast(context, tr.shiftMarkedCompleted);
                },
              ),
              const SizedBox(height: AppSpace.sm),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const AppIcon(HugeIcons.strokeRoundedEdit02, size: 18),
                    label: Text(tr.editShift),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showEditShiftDialog(context, shift, job, viewModel);
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                    ),
                    icon: const AppIcon(HugeIcons.strokeRoundedDelete02, size: 18),
                    label: Text(tr.delete),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirmed = await showConfirmDialog(
                        context,
                        title: tr.deleteThisShift,
                        message: tr.t(
                          'This will remove the shift on ${AppDate.short(start)} for ${job?.name ?? "Job"}.',
                          ne: 'यसले ${AppDate.short(start)} को ${job?.name ?? "काम"} सिफ्ट हटाउनेछ।',
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
                              );
                            },
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
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
                        shape: BoxShape.circle,
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


