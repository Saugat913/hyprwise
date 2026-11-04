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
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class LiveShiftScreen extends StatefulWidget {
  const LiveShiftScreen({super.key, this.initialAction});

  final String? initialAction;

  @override
  State<LiveShiftScreen> createState() => _LiveShiftScreenState();
}

class _LiveShiftScreenState extends State<LiveShiftScreen> {
  bool _actionHandled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialAction());
    }
  }

  void _handleInitialAction() {
    if (_actionHandled || !mounted) return;
    _actionHandled = true;
    final viewModel = getIt<WorkViewModel>();
    final shift = viewModel.activeShift;
    if (shift == null) return;

    if (widget.initialAction == 'break') {
      viewModel.toggleBreak();
    } else if (widget.initialAction == 'end') {
      _triggerEndShift(viewModel, shift);
    }
  }

  Future<void> _triggerEndShift(WorkViewModel viewModel, dynamic shift) async {
    final job = viewModel.jobsById[shift.jobId];
    final elapsed = viewModel.activeShiftElapsed;
    final tr = context.strings;
    final confirmed = await showConfirmDialog(
      context,
      title: tr.endShiftNow,
      message:
          '${job?.name ?? tr.shiftLabel} · ${tr.formatNumber(elapsed.inHours)}${tr.hourAbbr} ${tr.formatNumber(elapsed.inMinutes % 60)}${tr.minuteAbbr} (${tr.formatNumber(viewModel.currentBreakMinutes)}${tr.minuteAbbr}).',
      confirmLabel: tr.endShift,
      cancelLabel: tr.keepWorking,
    );
    if (confirmed && mounted) {
      final earnings = await viewModel.endShift(
        shift.id,
        breakMinutes: viewModel.currentBreakMinutes,
      );
      if (mounted) {
        context.go(AppRoutes.shiftDone(shift.id), extra: earnings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final shift = viewModel.activeShift;
        final text = Theme.of(context).textTheme;
        final colors = context.colors;
        final tr = context.strings;

        if (shift == null) {
          return PopScope(
            canPop: context.canPop(),
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              context.go(AppRoutes.home);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(tr.liveShift),
                leading: BackButton(onPressed: handleBack),
              ),
              body: Center(
                child: EmptyState(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  title: tr.noActiveShift,
                  message: tr.notCurrentlyClockedIn,
                  actionLabel: tr.returnHome,
                  onAction: () => context.go(AppRoutes.home),
                ),
              ),
            ),
          );
        }

        final job = viewModel.jobsById[shift.jobId];
        final startTime = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
        final elapsed = viewModel.activeShiftElapsed;
        final liveEarnings = viewModel.activeShiftLiveEarnings;
        final currencyCode = job?.currencyCode ?? viewModel.baseCurrency;
        final rateMinor = shift.rateOverrideMinor ?? job?.hourlyRateMinor ?? 0;
        final isToday = AppDate.isSameDay(startTime, DateTime.now());
        final startedAtLabel = isToday
            ? AppDate.timeOnly(startTime)
            : '${AppDate.short(startTime)}, ${AppDate.timeOnly(startTime)}';

        Future<void> pickStartTime() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(startTime),
          );
          if (picked != null) {
            final newStart = DateTime(
              startTime.year,
              startTime.month,
              startTime.day,
              picked.hour,
              picked.minute,
            );
            await viewModel.shiftRepo.update(shift.id, startAt: newStart);
          }
        }

        final hasOt = liveEarnings?.hasOvertime ?? false;
        final currentHourlyRateMinor = hasOt ? liveEarnings!.overtimeRateMinor : rateMinor;

        return PopScope(
          canPop: context.canPop(),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            context.go(AppRoutes.home);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: handleBack),
              title: Text(tr.liveShift),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Shift Metadata Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const IconTile(HugeIcons.strokeRoundedBriefcase01, size: 42),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job?.name ?? tr.activeShift,
                                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr.startedAt(startedAtLabel),
                                      style: text.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              StatusChip(
                                viewModel.isOnBreak ? tr.takeBreak : tr.inProgress,
                                tone: viewModel.isOnBreak ? ChipTone.warning : ChipTone.success,
                              ),
                            ],
                          ),
                          const Divider(height: AppSpace.xl),
                          Row(
                            children: [
                              Expanded(
                                child: _ShiftMetaColumn(
                                  label: tr.starts,
                                  value: startedAtLabel,
                                ),
                              ),
                              Expanded(
                                child: _ShiftMetaColumn(
                                  label: hasOt ? '${tr.hourlyRate} (${tr.overtime})' : tr.hourlyRate,
                                  value: '${MoneyFormatter.format(currentHourlyRateMinor, currencyCode)}/${tr.hourAbbr}',
                                  valueColor: hasOt ? colors.brand : null,
                                ),
                              ),
                              Expanded(
                                child: _ShiftMetaColumn(
                                  label: tr.breakTime,
                                  value: '${tr.formatNumber(viewModel.currentBreakMinutes)} ${tr.minuteAbbr}',
                                  alignEnd: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 2. Centered Live Timer & Second-by-Second Earnings Hero
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
                                decoration: BoxDecoration(
                                  color: viewModel.isOnBreak ? colors.warningBg : colors.incomeBg,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcon(
                                      viewModel.isOnBreak
                                          ? HugeIcons.strokeRoundedCoffee01
                                          : HugeIcons.strokeRoundedClock01,
                                      size: 14,
                                      color: viewModel.isOnBreak ? colors.warning : colors.income,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      viewModel.isOnBreak
                                          ? tr.onBreakTimerPausedUpper
                                          : tr.inProgress.toUpperCase(),
                                      style: text.labelSmall?.copyWith(
                                        color: viewModel.isOnBreak ? colors.warning : colors.income,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpace.md),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  tr.localizeDigits(_formatTimer(elapsed)),
                                  style: text.displayLarge?.copyWith(
                                    fontFamily: 'RedditMono',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 54,
                                    letterSpacing: 2,
                                    color: viewModel.isOnBreak
                                        ? Theme.of(context).colorScheme.onSurfaceVariant
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.lg,
                                  vertical: AppSpace.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.incomeBg.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: colors.income.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '≈ ${MoneyFormatter.format(liveEarnings?.earningsMinor ?? 0, currencyCode)} ${tr.earned}',
                                  style: text.titleMedium?.copyWith(
                                    color: colors.income,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'RedditMono',
                                  ),
                                ),
                              ),
                              if (hasOt) ...[
                                const SizedBox(height: AppSpace.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.brand.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Text(
                                    '${tr.overtime}: ${_formatTimer(Duration(minutes: liveEarnings!.overtimeMinutes))} @ ${MoneyFormatter.format(liveEarnings.overtimeRateMinor, currencyCode)}/${tr.hourAbbr}',
                                    style: text.bodySmall?.copyWith(
                                      fontFamily: 'RedditMono',
                                      fontWeight: FontWeight.w700,
                                      color: colors.brand,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpace.md),
                              // Live Shift Detailed Breakdown Card
                              Container(
                                padding: const EdgeInsets.all(AppSpace.md),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Column(
                                  children: [
                                    _BreakdownRow(
                                      label: tr.regularPayLabel,
                                      value: MoneyFormatter.format(
                                        liveEarnings?.regularEarningsMinor ?? liveEarnings?.earningsMinor ?? 0,
                                        currencyCode,
                                      ),
                                      subValue: '${tr.formatNumber(liveEarnings?.regularMinutes ?? (elapsed.inMinutes))} ${tr.minuteAbbr}',
                                    ),
                                    if ((shift.overtimeThresholdMinutes != null && shift.overtimeThresholdMinutes! > 0) || hasOt) ...[
                                      const SizedBox(height: AppSpace.xs),
                                      _BreakdownRow(
                                        label: tr.overtimePayLabel,
                                        value: MoneyFormatter.format(liveEarnings?.overtimeEarningsMinor ?? 0, currencyCode),
                                        subValue: '${tr.formatNumber(liveEarnings?.overtimeMinutes ?? 0)} ${tr.minuteAbbr}',
                                        valueColor: hasOt ? colors.brand : null,
                                      ),
                                    ],
                                    const SizedBox(height: AppSpace.xs),
                                    _BreakdownRow(
                                      label: tr.breakTime,
                                      value: '${tr.formatNumber(viewModel.currentBreakMinutes)} ${tr.minuteAbbr}',
                                    ),
                                  ],
                                ),
                              ),
                              if (viewModel.isOnBreak || viewModel.currentBreakSeconds > 0) ...[
                                const SizedBox(height: AppSpace.sm),
                                Text(
                                  '${tr.breakTime}: ${tr.localizeDigits(_formatTimer(viewModel.currentBreakDuration))}',
                                  style: text.bodyMedium?.copyWith(
                                    color: viewModel.isOnBreak
                                        ? colors.warning
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Bottom-Aligned Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            viewModel.isOnBreak ? tr.resumeShift : tr.takeBreak,
                            icon: viewModel.isOnBreak
                                ? HugeIcons.strokeRoundedPlay
                                : HugeIcons.strokeRoundedCoffee01,
                            kind: viewModel.isOnBreak
                                ? AppButtonKind.primary
                                : AppButtonKind.secondary,
                            onPressed: () => viewModel.toggleBreak(),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: AppButton(
                            tr.editStartTime,
                            icon: HugeIcons.strokeRoundedCalendar03,
                            kind: AppButtonKind.outline,
                            onPressed: pickStartTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    AppButton(
                      tr.endShift,
                      kind: AppButtonKind.danger,
                      onPressed: () => _triggerEndShift(viewModel, shift),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimer(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _ShiftMetaColumn extends StatelessWidget {
  const _ShiftMetaColumn({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? scheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.subValue,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? subValue;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subValue != null) ...[
              Text(
                '($subValue) ',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
            Text(
              value,
              style: text.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? scheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
