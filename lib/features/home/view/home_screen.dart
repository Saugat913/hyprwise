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
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/home/view/widgets/hero/home_hero_card.dart';
import 'package:finance_tracker/features/home/view/widgets/home_at_a_glance.dart';
import 'package:finance_tracker/features/home/view/widgets/home_month_overview.dart';
import 'package:finance_tracker/features/home/view/widgets/home_planning_overview.dart';
import 'package:finance_tracker/features/home/view/widgets/top_spending_card.dart';
import 'package:finance_tracker/features/home/view/widgets/home_transaction_row.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<HomeViewModel>();
    final workViewModel = getIt<WorkViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final colors = context.colors;
        final tr = context.strings;

        return TabPage(
          title: tr.home,
          overline: AppDate.header(viewModel.now),
          actions: [
            RoundIconButton(
              HugeIcons.strokeRoundedSettings02,
              tooltip: tr.settings,
              onPressed: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(width: AppSpace.xs),
            Builder(
              builder: (context) {
                final alertsVm = getIt<AlertsViewModel>();
                return ListenableBuilder(
                  listenable: alertsVm,
                  builder: (context, _) {
                    final unreadCount = alertsVm.unreadCount;
                    final iconButton = RoundIconButton(
                      HugeIcons.strokeRoundedNotification01,
                      tooltip: tr.alerts,
                      onPressed: () {
                        alertsVm.markAllAsRead();
                        context.push(AppRoutes.notifications);
                      },
                    );

                    if (unreadCount <= 0) {
                      return iconButton;
                    }

                    return Badge(
                      label: Text(
                        tr.formatNumber(unreadCount),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: colors.expense,
                      offset: const Offset(-2, 2),
                      child: iconButton,
                    );
                  },
                );
              },
            ),
          ],
          children: [
            // One calm snapshot of where money stands right now.
            HomeHeroCard(viewModel: viewModel),

            // Active shift banner (scoped listener prevents 1Hz full-dashboard rebuilds)
            ListenableBuilder(
              listenable: Listenable.merge([workViewModel, workViewModel.liveTick]),
              builder: (context, _) {
                return AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: workViewModel.isClockedIn
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpace.md),
                          child: _ActiveShiftBanner(workViewModel: workViewModel),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),

            // Get set up checklist (actionable milestones, dismissible anytime)
            if (viewModel.hasAccounts && !viewModel.isSetupComplete) ...[
              const SizedBox(height: AppSpace.xs),
              SectionHeader(
                '${tr.getSetUp} · ${tr.setupStepsProgress(viewModel.setupCompletedCount, 4)}',
                actionLabel: tr.t(
                  'Hide',
                  ne: 'लुकाउनुहोस्',
                  hi: 'छिपाएं',
                  es: 'Ocultar',
                  fr: 'Masquer',
                  de: 'Ausblenden',
                  ja: '非表示',
                  zh: '隐藏',
                  it: 'Nascondi',
                ),
                onAction: viewModel.dismissSetupChecklist,
              ),
              const SizedBox(height: AppSpace.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ChecklistRow(
                      step: tr.formatNumber(1),
                      title: tr.addJobChecklist,
                      subtitle:
                          viewModel.hasJobs
                              ? '${tr.done} · ${viewModel.snapshot.jobs.first.name}'
                              : tr.shiftsLiveHereSubtitle,
                      isDone: viewModel.hasJobs,
                      onTap: () => context.push(AppRoutes.addJob),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: tr.formatNumber(2),
                      title: tr.addTransaction,
                      subtitle:
                          viewModel.hasTransactions
                              ? '${tr.done} · ${tr.formatNumber(viewModel.snapshot.transactions.length)}'
                              : tr.tapAddToRecordFirstTransaction,
                      isDone: viewModel.hasTransactions,
                      onTap: () => context.push(AppRoutes.addTransaction),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: tr.formatNumber(3),
                      title: tr.setGoalChecklist,
                      subtitle:
                          viewModel.hasGoals
                              ? '${tr.done} · ${viewModel.snapshot.goals.first.name}'
                              : tr.giveMoneyReasonSubtitle,
                      isDone: viewModel.hasGoals,
                      onTap: () => context.push(AppRoutes.addGoal),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: tr.formatNumber(4),
                      title: tr.turnOnAlertsChecklist,
                      subtitle:
                          viewModel.hasAlerts
                              ? tr.done
                              : tr.neverMissShiftOrBillSubtitle,
                      isDone: viewModel.hasAlerts,
                      onTap: () => context.push(AppRoutes.alerts),
                    ),
                  ],
                ),
              ),
            ],

            // Quick actions placed right below the hero & active shift banner
            const SizedBox(height: AppSpace.xs),
            SectionHeader(tr.quickActions),
            const SizedBox(height: AppSpace.xs),
            _HomeActionPanel(
              workViewModel: workViewModel,
              onTransfer: () => context.push(AppRoutes.transfers),
              onShift:
                  () => context.push(
                    workViewModel.isClockedIn
                        ? AppRoutes.liveShift
                        : AppRoutes.startShift,
                  ),
              onAssistant: () => context.push(AppRoutes.assistant),
              onAnalytics: () => context.push(AppRoutes.analytics),
            ),

            

            // Cash flow answers the complementary question: what changed this month?
            // Progressive disclosure: hide TopSpendingCard until spending exists so
            // new users don't face consecutive empty cards on the dashboard.
            if (viewModel.hasAccounts) ...[
              HomeMonthOverview(viewModel: viewModel),
              if (viewModel.topSpendingCategories.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs),
                TopSpendingCard(viewModel: viewModel),
              ],
              const SizedBox(height: AppSpace.xs),
              HomeAtAGlance(viewModel: viewModel),
              const SizedBox(height: AppSpace.xs),
              HomePlanningOverview(viewModel: viewModel),
            ],

            // Recent transactions section
            const SizedBox(height: AppSpace.sm),
            SectionHeader(
              tr.recentTransactions,
              actionLabel: tr.seeAll,
              onAction: () => context.push(AppRoutes.money),
            ),
            if (viewModel.recentTransactions.isEmpty)
              AppCard(
                child: EmptyState(
                  compact: true,
                  illustration: EmptyIllustration.transactions,
                  icon: HugeIcons.strokeRoundedCoins01,
                  title: tr.noTransactionsYet,
                  message: tr.tapAddToRecordFirstTransaction,
                  actionLabel: tr.addTransaction,
                  onAction: () => context.push(AppRoutes.addTransaction),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (
                      var i = 0;
                      i < viewModel.recentTransactions.length;
                      i++
                    ) ...[
                      if (i > 0) const RowDivider(),
                      HomeTransactionRow(
                        transaction: viewModel.recentTransactions[i],
                        currency: viewModel.snapshot.currencyOf(
                          viewModel.recentTransactions[i].accountId,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.onTap,
  });

  final String step;
  final String title;
  final String subtitle;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone ? context.colors.incomeBg : context.colors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              child:
                  isDone
                      ? Icon(
                        Icons.check,
                        size: 16,
                        color: context.colors.income,
                      )
                      : Text(
                        step,
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color:
                          isDone
                              ? context.colors.income
                              : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              StatusChip(context.strings.done, tone: ChipTone.success)
            else
              const Chevron(),
          ],
        ),
      ),
      ),
    );
  }
}

class _ActiveShiftBanner extends StatelessWidget {
  const _ActiveShiftBanner({required this.workViewModel});

  final WorkViewModel workViewModel;

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return AppStrings.current().localizeDigits('$h:$m:$s');
  }

  @override
  Widget build(BuildContext context) {
    final shift = workViewModel.activeShift;
    if (shift == null) return const SizedBox.shrink();

    final tr = context.strings;
    final job = workViewModel.jobsById[shift.jobId];
    final elapsed = workViewModel.activeShiftElapsed;
    final liveEarnings = workViewModel.activeShiftLiveEarnings;
    final isOnBreak = workViewModel.isOnBreak;
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: (isOnBreak ? colors.warning : colors.income).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: (isOnBreak ? colors.warning : colors.income).withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.liveShift),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm + 2,
          ),
          child: Row(
          children: [
         
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          job?.name ?? tr.activeShift,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      StatusChip(
                        isOnBreak ? tr.onBreakTimerPaused : tr.running,
                        tone: isOnBreak ? ChipTone.warning : ChipTone.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatElapsed(elapsed)} · ≈ ${liveEarnings != null ? MoneyFormatter.format(liveEarnings.earningsMinor, job?.currencyCode ?? workViewModel.baseCurrency) : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'RedditMono',
                      fontWeight: FontWeight.w600,
                      color: colors.income,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              tr.manage,
              compact: true,
              kind: AppButtonKind.outline,
              onPressed: () => context.push(AppRoutes.liveShift),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Full-width, evenly proportioned task bar using Hyprwise's 12px surface and
/// hairline tokens so every quick action shares identical geometry and weight.
class _HomeActionPanel extends StatelessWidget {
  const _HomeActionPanel({
    required this.workViewModel,
    required this.onTransfer,
    required this.onShift,
    required this.onAssistant,
    required this.onAnalytics,
  });

  final WorkViewModel workViewModel;
  final VoidCallback onTransfer;
  final VoidCallback onShift;
  final VoidCallback onAssistant;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final colors = context.colors;

    final actions = [
      _QuickActionItem(
        title: tr.transfer,
        icon: HugeIcons.strokeRoundedCoinsSwap,
        color: colors.brandText,
        background: colors.brandBg,
        onTap: onTransfer,
      ),
      _QuickActionItem(
        title: tr.hyprAi,
        icon: HugeIcons.strokeRoundedSparkles,
        customLeading: const BrandEmblem(size: 22),
        color: colors.brandText,
        background: colors.brandBg,
        onTap: onAssistant,
      ),
      _QuickActionItem(
        title: tr.analytics,
        icon: HugeIcons.strokeRoundedAnalytics01,
        color: colors.income,
        background: colors.incomeBg,
        onTap: onAnalytics,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpace.sm),
          Expanded(
            child: _QuickActionTile(
              title: actions[i].title,
              icon: actions[i].icon,
              customLeading: actions[i].customLeading,
              color: actions[i].color,
              background: actions[i].background,
              onTap: actions[i].onTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.title,
    required this.icon,
    this.customLeading,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String title;
  final IconGlyph icon;
  final Widget? customLeading;
  final Color color;
  final Color background;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.icon,
    this.customLeading,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String title;
  final IconGlyph icon;
  final Widget? customLeading;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: customLeading ?? AppIcon(icon, size: 18, color: color),
              ),
              const SizedBox(height: AppSpace.xs + 2),
              Text(
                title,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
