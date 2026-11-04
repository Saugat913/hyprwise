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
/// Widget 1: Shift Tracking Widget (CAFE, time and pay rates, break/end)
/// Matches inspiration sketch (left): Rounded card with job, live duration,
/// live earnings, rate, and two actionable buttons [break] [end].
/// ---------------------------------------------------------------------------
class ShiftHomeScreenWidget extends StatelessWidget {
  const ShiftHomeScreenWidget({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final workVm = getIt<WorkViewModel>();

    return ListenableBuilder(
      listenable: workVm,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final active = workVm.activeShift;
        final job = active != null ? workVm.jobsById[active.jobId] : workVm.selectedJob;
        final isWorking = active != null;
        final isOnBreak = workVm.isOnBreak;

        final worked = workVm.activeShiftWorkedDuration;
        final h = worked.inHours.toString().padLeft(2, '0');
        final m = (worked.inMinutes % 60).toString().padLeft(2, '0');
        final s = (worked.inSeconds % 60).toString().padLeft(2, '0');
        final timeStr = '$h:$m:$s';

        final earnings = workVm.activeShiftLiveEarnings;
        final earningsStr = earnings != null && job != null
            ? MoneyFormatter.format(earnings.earningsMinor, job.currencyCode)
            : '';
        final rateStr = job != null
            ? '${job.currencyCode} ${(job.hourlyRateMinor / 100.0).toStringAsFixed(2)}/hr'
            : '';

        final subtitle = isWorking
            ? '$timeStr • $earningsStr • $rateStr'
            : (job != null ? tr.t('Ready to clock in • $rateStr', ne: 'काम सुरु गर्न तयार • $rateStr', hi: 'काम शुरू करने के लिए तैयार • $rateStr') : tr.t('No active shift', ne: 'कुनै सक्रिय सिफ्ट छैन', hi: 'कोई सक्रिय शिफ्ट नहीं'));

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Job Title (Uppercase header like 'CAFE')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job?.name.toUpperCase() ?? 'HYPRWISE SHIFT',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isWorking)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOnBreak
                            ? Colors.amber.withValues(alpha: 0.2)
                            : colors.income.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnBreak ? Colors.amber[800] : colors.income,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOnBreak ? 'PAUSED' : 'LIVE',
                            style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              color: isOnBreak ? Colors.amber[900] : colors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Time and pay rates
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.md),

              // Action Buttons Row (break, end)
              if (isWorking)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          side: BorderSide(color: scheme.outlineVariant, width: 1.2),
                        ),
                        onPressed: () => workVm.toggleBreak(),
                        child: Text(
                          isOnBreak ? 'resume' : 'break',
                          style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          side: BorderSide(color: colors.expense.withValues(alpha: 0.6), width: 1.2),
                          foregroundColor: colors.expense,
                        ),
                        onPressed: () {
                          workVm.endShift(active.id, breakMinutes: workVm.currentBreakMinutes);
                        },
                        child: Text(
                          'end',
                          style: text.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.expense,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () {
                      if (job != null) {
                        workVm.startShift(jobId: job.id);
                      } else {
                        context.push(AppRoutes.work);
                      }
                    },
                    child: Text(
                      job != null ? 'start shift' : 'manage jobs',
                      style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Widget 2: Quick Action Bar Widget (income, expense, lend, borrow)
/// Matches inspiration sketch (middle): Pill container with 4 action tiles.
/// ---------------------------------------------------------------------------
class QuickActionsBarWidget extends StatelessWidget {
  const QuickActionsBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            label: 'income',
            icon: HugeIcons.strokeRoundedArrowDownLeft01,
            color: colors.income,
            onTap: () => context.push('${AppRoutes.addTransaction}?type=income'),
          ),
          _ActionButton(
            label: 'expense',
            icon: HugeIcons.strokeRoundedArrowUpRight01,
            color: colors.expense,
            onTap: () => context.push('${AppRoutes.addTransaction}?type=expense'),
          ),
          _ActionButton(
            label: 'lend',
            icon: HugeIcons.strokeRoundedMoneySend02,
            color: const Color(0xFF2563EB),
            onTap: () => context.push('${AppRoutes.addDebt}?type=lent'),
          ),
          _ActionButton(
            label: 'borrow',
            icon: HugeIcons.strokeRoundedMoneyReceive02,
            color: const Color(0xFFEA580C),
            onTap: () => context.push('${AppRoutes.addDebt}?type=borrowed'),
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
    required this.onTap,
  });

  final String label;
  final IconGlyph icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: AppIcon(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Widget 3: HyprAI Widget (hyprai launcher)
/// Matches inspiration sketch (right): Rounded square card labeled 'hyprai'.
/// ---------------------------------------------------------------------------
class HyprAiWidget extends StatelessWidget {
  const HyprAiWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push(AppRoutes.assistant),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
              child: Center(
                child: AppIcon(
                  HugeIcons.strokeRoundedChatBot,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'hyprai',
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
