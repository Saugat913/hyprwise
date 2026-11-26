import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

/// ---------------------------------------------------------------------------
/// Widget 1: Shift Tracking Widget Preview (matches Android & iOS native widgets)
/// ---------------------------------------------------------------------------
class ShiftHomeScreenWidget extends StatelessWidget {
  const ShiftHomeScreenWidget({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final workVm = getIt<WorkViewModel>();

    return ListenableBuilder(
      listenable: Listenable.merge([workVm, workVm.liveTick]),
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;

        final active = workVm.activeShift;
        final job = active != null ? workVm.jobsById[active.jobId] : workVm.selectedJob;
        final isWorking = active != null;
        final isOnBreak = workVm.isOnBreak;

        final worked = workVm.activeShiftWorkedDuration;
        final h = worked.inHours.toString().padLeft(2, '0');
        final m = (worked.inMinutes % 60).toString().padLeft(2, '0');
        final s = (worked.inSeconds % 60).toString().padLeft(2, '0');
        final timeStr = tr.localizeDigits('$h:$m:$s');

        final earnings = workVm.activeShiftLiveEarnings;
        final earningsStr = earnings != null && job != null
            ? MoneyFormatter.format(earnings.earningsMinor, job.currencyCode)
            : (job != null ? MoneyFormatter.format(0, job.currencyCode) : '');
        final rateMinor = active?.rateOverrideMinor ?? job?.hourlyRateMinor;
        final rateStr = job != null && rateMinor != null
            ? '${MoneyFormatter.format(rateMinor, job.currencyCode)}/${tr.hourAbbr}'
            : '';

        final subtitle = isWorking
            ? [
                if (rateStr.isNotEmpty) rateStr,
                if (workVm.currentBreakMinutes > 0) '${workVm.currentBreakMinutes}${tr.minuteAbbr} ${tr.breakTime.toLowerCase()}',
              ].join(' · ')
            : (job != null
                ? tr.t(
                    'Ready to clock in · $rateStr',
                    ne: 'काम सुरु गर्न तयार · $rateStr',
                    hi: 'काम शुरू करने के लिए तैयार · $rateStr',
                  )
                : tr.t(
                    'Tap to start tracking',
                    ne: 'सिफ्ट सुरु गर्न ट्याप गर्नुहोस्',
                    hi: 'ट्रैकिंग शुरू करने के लिए टैप करें',
                  ));

        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: IconTile + Stacked Job Title & Rate Subtitle + StatusChip
              Row(
                children: [
                  const IconTile(HugeIcons.strokeRoundedBriefcase01, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job?.name ?? tr.t('Shift Tracker', ne: 'सिफ्ट ट्र्याकर', hi: 'शिफ्ट ट्रैकर'),
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle.isEmpty
                              ? (isOnBreak ? tr.onBreakTimerPaused : tr.inProgress)
                              : subtitle,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  StatusChip(
                    isWorking
                        ? (isOnBreak ? tr.takeBreak : tr.liveBadge)
                        : tr.t('Ready', ne: 'तयार', hi: 'तैयार'),
                    tone: isWorking
                        ? (isOnBreak ? ChipTone.warning : ChipTone.success)
                        : ChipTone.neutral,
                  ),
                ],
              ),

              if (isWorking) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: colors.fill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          timeStr,
                          style: text.titleLarge?.copyWith(
                            fontFamily: 'RedditMono',
                            fontWeight: FontWeight.w700,
                            color: isOnBreak ? scheme.onSurfaceVariant : scheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.incomeBg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          earningsStr,
                          style: text.labelMedium?.copyWith(
                            fontFamily: 'RedditMono',
                            fontWeight: FontWeight.w700,
                            color: colors.income,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              if (isWorking)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        isOnBreak ? tr.resumeShift : tr.t('Break', ne: 'विश्राम', hi: 'ब्रेक'),
                        icon: isOnBreak ? HugeIcons.strokeRoundedPlay : HugeIcons.strokeRoundedCoffee01,
                        kind: AppButtonKind.secondary,
                        compact: true,
                        onPressed: () => workVm.toggleBreak(),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: AppButton(
                        tr.t('End', ne: 'समाप्त', hi: 'समाप्त'),
                        icon: HugeIcons.strokeRoundedStop,
                        kind: AppButtonKind.danger,
                        compact: true,
                        onPressed: () => workVm.endShift(active.id, breakMinutes: workVm.currentBreakMinutes),
                      ),
                    ),
                  ],
                )
              else
                AppButton(
                  job != null ? tr.startShift : tr.manageJobs,
                  icon: HugeIcons.strokeRoundedPlay,
                  compact: true,
                  onPressed: () {
                    if (job != null) {
                      workVm.startShift(jobId: job.id);
                    } else {
                      context.push(AppRoutes.manageJobs);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Widget 2: Quick Action Bar Widget Preview (matches Android & iOS native widgets)
/// ---------------------------------------------------------------------------
class QuickActionsBarWidget extends StatelessWidget {
  const QuickActionsBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.strings;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: tr.income,
              icon: HugeIcons.strokeRoundedArrowDownLeft01,
              color: colors.income,
              bg: colors.incomeBg,
              onTap: () => context.push('${AppRoutes.addTransaction}?type=income'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ActionButton(
              label: tr.expense,
              icon: HugeIcons.strokeRoundedArrowUpRight01,
              color: colors.expense,
              bg: colors.expenseBg,
              onTap: () => context.push('${AppRoutes.addTransaction}?type=expense'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ActionButton(
              label: tr.lent,
              icon: HugeIcons.strokeRoundedMoneySend02,
              color: colors.warning,
              bg: colors.warningBg,
              onTap: () => context.push('${AppRoutes.addDebt}?type=lent'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ActionButton(
              label: tr.borrowed,
              icon: HugeIcons.strokeRoundedMoneyReceive02,
              color: colors.brandText,
              bg: colors.brandBg,
              onTap: () => context.push('${AppRoutes.addDebt}?type=borrowed'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String label;
  final IconGlyph icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Material(
      color: colors.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon, size: 32, color: color, background: bg),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Widget 3: HyprAI Launcher Widget Preview (1x1 square matching Android & iOS)
/// ---------------------------------------------------------------------------
class HyprAiWidget extends StatelessWidget {
  const HyprAiWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;

    return SizedBox(
      width: 96,
      height: 96,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.sm),
        onTap: () => context.push(AppRoutes.assistant),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandEmblem(size: 40),
            const SizedBox(height: 6),
            Text(
              tr.hyprAi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
