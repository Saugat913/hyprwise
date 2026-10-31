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
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<HomeViewModel>();
    final workViewModel = getIt<WorkViewModel>();
    final subService = getIt<SubscriptionService>();

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, workViewModel, subService]),
      builder: (context, _) {
        final colors = context.colors;
        final text = Theme.of(context).textTheme;
        final tr = context.strings;

        return TabPage(
          title: tr.home,
          overline: AppDate.header(viewModel.now),
          actions: [
            RoundIconButton(
              HugeIcons.strokeRoundedSettings02,
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

            // Active shift banner (when clocked in)
            if (workViewModel.isClockedIn) ...[
              const SizedBox(height: AppSpace.md),
              _ActiveShiftBanner(workViewModel: workViewModel),
            ],

            // Quick actions placed right below the hero & active shift banner
            const SizedBox(height: AppSpace.xxl),
            SectionHeader(tr.quickActions),
            const SizedBox(height: AppSpace.sm),
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

            // Get set up checklist (if not completed) placed right under shift starting manage section
            if (viewModel.hasAccounts && !viewModel.isSetupComplete) ...[
              const SizedBox(height: AppSpace.xl),
              SectionHeader(
                tr.getSetUp,
                actionLabel: tr.setupStepsProgress(viewModel.setupCompletedCount, 4),
              ),
              const SizedBox(height: AppSpace.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ChecklistRow(
                      step: tr.formatNumber(1),
                      title: tr.addAccountChecklist,
                      subtitle:
                          viewModel.hasAccounts
                              ? '${tr.done} · ${tr.accountDisplayName(viewModel.snapshot.accounts.first.name)}'
                              : tr.balanceRealSubtitle,
                      isDone: viewModel.hasAccounts,
                      onTap: () => context.push(AppRoutes.addAccount),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: tr.formatNumber(2),
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

            // Cash flow answers the complementary question: what changed this month?
            if (viewModel.hasAccounts) ...[
              HomeMonthOverview(viewModel: viewModel),
              const SizedBox(height: AppSpace.md),
              TopSpendingCard(viewModel: viewModel),
              const SizedBox(height: AppSpace.md),
              HomeAtAGlance(viewModel: viewModel),
              const SizedBox(height: AppSpace.md),
              HomePlanningOverview(viewModel: viewModel),
            ],

            // Recent transactions section
            const SizedBox(height: AppSpace.xxl),
            SectionHeader(
              tr.recentTransactions,
              actionLabel: tr.seeAll,
              onAction: () => context.push(AppRoutes.money),
            ),
            if (viewModel.recentTransactions.isEmpty)
              AppCard(
                child: Text(
                  tr.noTransactionsYet,
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                        currency: viewModel.baseCurrency,
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

    return InkWell(
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
                shape: BoxShape.circle,
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

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(AppRoutes.liveShift),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm + 2,
        ),
        decoration: BoxDecoration(
          color: colors.income.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.income.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnBreak ? colors.warning : colors.income,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
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
    );
  }
}

/// A small, task-first control surface for the dashboard. It deliberately
/// uses the app's existing surface, hairline and 12px-radius tokens so it
/// feels like part of the product rather than a separate shortcut grid.
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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpace.md,
      crossAxisSpacing: AppSpace.md,
      childAspectRatio: 1.85,
      children: [
        _QuickActionTile(
          title: tr.transfer,
          subtitle: tr.accounts,
          icon: HugeIcons.strokeRoundedCoinsSwap,
          color: colors.brand,
          onTap: onTransfer,
        ),
        _QuickActionTile(
          title: workViewModel.isClockedIn ? tr.activeShift : tr.startShift,
          subtitle:
              workViewModel.isClockedIn ? tr.running : tr.liveTimeTracking,
          icon:
              workViewModel.isClockedIn
                  ? HugeIcons.strokeRoundedClock01
                  : HugeIcons.strokeRoundedPlay,
          color: colors.income,
          onTap: onShift,
        ),
        _QuickActionTile(
          title: tr.hyprAi,
          subtitle: tr.financialAi,
          icon: HugeIcons.strokeRoundedChatBot,
          color: colors.brand,
          onTap: onAssistant,
        ),
        _QuickActionTile(
          title: tr.t(
            'Analytics',
            ne: 'विश्लेषण',
            hi: 'एनालिटिक्स',
            es: 'Análisis',
            fr: 'Analyses',
            de: 'Analysen',
            ja: '分析',
            zh: '分析',
            it: 'Analisi',
          ),
          subtitle: tr.t(
            'Trends & insights',
            ne: 'प्रवृत्ति र अन्तर्दृष्टि',
            hi: 'रुझान और अंतर्दृष्टि',
            es: 'Tendencias e ideas',
            fr: 'Tendances et aperçus',
            de: 'Trends & Einblicke',
            ja: '傾向と分析',
            zh: '趋势与洞察',
            it: 'Tendenze e approfondimenti',
          ),
          icon: HugeIcons.strokeRoundedAnalytics01,
          color: colors.liquid,
          onTap: onAnalytics,
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconGlyph icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpace.sm + 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
            ],
          ),
        ),
      ),
    );
  }
}
