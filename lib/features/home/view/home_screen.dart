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
import 'package:finance_tracker/features/home/view/widgets/home_insight_widgets.dart';
import 'package:finance_tracker/features/home/view/widgets/home_transaction_row.dart';
import 'package:finance_tracker/features/home/view/widgets/upcoming_event_row.dart';
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
      listenable: Listenable.merge([viewModel, workViewModel]),
      builder: (context, _) {
        final colors = context.colors;
        final text = Theme.of(context).textTheme;
        final tr = context.strings;

        return TabPage(
          title: tr.home,
          overline: AppDate.header(viewModel.now),
          actions: [
            RoundIconButton(
              HugeIcons.strokeRoundedChartHistogram,
              onPressed: () => context.push(AppRoutes.analytics),
            ),
            RoundIconButton(
              HugeIcons.strokeRoundedNotification01,
              onPressed: () => context.push(AppRoutes.notifications),
            ),
            RoundIconButton(
              HugeIcons.strokeRoundedSlidersHorizontal,
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
          children: [
            // Hero net position card
            if (!viewModel.hasAccounts)
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.netPosition,
                      style: text.bodyMedium?.copyWith(color: colors.onHeroSecondary),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      MoneyFormatter.format(0, viewModel.baseCurrency),
                      style: text.displaySmall?.copyWith(color: colors.onHero, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      tr.t('Add an account and this fills in.', ne: 'खाता थप्नुहोस् र यहाँ विवरण देखिनेछ।', es: 'Añade una cuenta y esto se completará.', fr: 'Ajoutez un compte et ces données s\'afficheront.', de: 'Konto hinzufügen, um Daten anzuzeigen.', ja: '口座を追加するとここに情報が表示されます。', zh: '添加账户后此处将显示详细信息。', it: 'Aggiungi un conto e questo si compilerà.'),
                      style: text.bodySmall?.copyWith(color: colors.onHeroSecondary),
                    ),
                  ],
                ),
              )
            else
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tr.netPosition,
                          style: text.bodyMedium?.copyWith(color: colors.onHeroSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Builder(
                      builder: (context) {
                        final isPositive = viewModel.netPositionMinor >= 0;
                        final indicatorColor = isPositive ? colors.income : colors.expense;
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: indicatorColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: AppIcon(
                                isPositive
                                    ? HugeIcons.strokeRoundedArrowUpRight01
                                    : HugeIcons.strokeRoundedArrowDownLeft01,
                                size: 20,
                                color: indicatorColor,
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                MoneyFormatter.format(viewModel.netPositionMinor, viewModel.baseCurrency),
                                style: text.displaySmall?.copyWith(
                                  color: isPositive ? colors.onHero : colors.expense,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // 2-Account breakdown (Everyday & Savings)
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.accounts),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                              decoration: BoxDecoration(
                                color: colors.onHero.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: colors.onHeroSecondary.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AppIcon(HugeIcons.strokeRoundedBank, size: 12, color: colors.onHeroSecondary),
                                      const SizedBox(width: 4),
                                      Text(tr.everyday, style: text.labelSmall?.copyWith(color: colors.onHeroSecondary, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    MoneyFormatter.format(viewModel.everydayBalanceMinor, viewModel.baseCurrency),
                                    style: text.labelLarge?.copyWith(color: colors.onHero, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.plan),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                              decoration: BoxDecoration(
                                color: colors.onHero.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: colors.onHeroSecondary.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AppIcon(HugeIcons.strokeRoundedSafe, size: 12, color: colors.onHeroSecondary),
                                      const SizedBox(width: 4),
                                      Text(tr.savings, style: text.labelSmall?.copyWith(color: colors.onHeroSecondary, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    MoneyFormatter.format(viewModel.savingsBalanceMinor, viewModel.baseCurrency),
                                    style: text.labelLarge?.copyWith(color: colors.onHero, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (viewModel.sparklinePoints.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      Sparkline(viewModel.sparklinePoints, color: colors.brand, height: 48),
                    ],
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr.income, style: text.bodySmall?.copyWith(color: colors.onHeroSecondary)),
                              Text(
                                MoneyFormatter.format(viewModel.monthIncome, viewModel.baseCurrency),
                                style: text.titleMedium?.copyWith(color: colors.onHero),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr.expense, style: text.bodySmall?.copyWith(color: colors.onHeroSecondary)),
                              Text(
                                MoneyFormatter.format(viewModel.monthExpense, viewModel.baseCurrency),
                                style: text.titleMedium?.copyWith(color: colors.onHero),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (viewModel.totalLentMinor > 0 || viewModel.totalBorrowedMinor > 0 || viewModel.activeDebts.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      Container(
                        height: 1,
                        color: colors.onHeroSecondary.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      InkWell(
                        onTap: () => context.push(AppRoutes.debts),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      AppIcon(HugeIcons.strokeRoundedExchange01, size: 13, color: colors.onHeroSecondary),
                                      const SizedBox(width: 5),
                                      Text(
                                        tr.debts,
                                        style: text.labelSmall?.copyWith(
                                          color: colors.onHeroSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        tr.t('${viewModel.activeDebts.length} active', ne: '${viewModel.activeDebts.length} सक्रिय', es: '${viewModel.activeDebts.length} activos', fr: '${viewModel.activeDebts.length} actifs', de: '${viewModel.activeDebts.length} aktiv', ja: '${viewModel.activeDebts.length}件 進行中', zh: '${viewModel.activeDebts.length} 条待清算', it: '${viewModel.activeDebts.length} attivi'),
                                        style: text.labelSmall?.copyWith(
                                          color: colors.onHeroSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      AppIcon(HugeIcons.strokeRoundedArrowRight01, size: 12, color: colors.onHeroSecondary),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 12,
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: colors.income,
                                            borderRadius: BorderRadius.circular(1.5),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${tr.lent}: ${MoneyFormatter.format(viewModel.totalLentMinor, viewModel.baseCurrency)}',
                                            style: text.bodySmall?.copyWith(
                                              color: colors.onHero,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 12,
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: colors.expense,
                                            borderRadius: BorderRadius.circular(1.5),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${tr.borrowed}: ${MoneyFormatter.format(viewModel.totalBorrowedMinor, viewModel.baseCurrency)}',
                                            style: text.bodySmall?.copyWith(
                                              color: colors.onHero,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Active shift banner (when clocked in)
            if (workViewModel.isClockedIn) ...[
              const SizedBox(height: AppSpace.md),
              _ActiveShiftBanner(workViewModel: workViewModel),
            ],

            // Get set up checklist (if not completed)
            if (!viewModel.isSetupComplete) ...[
              const SizedBox(height: AppSpace.xl),
              Row(
                children: [
                  Expanded(child: Text(tr.getSetUp, style: text.titleMedium)),
                  Text(
                    tr.setupStepsProgress(viewModel.setupCompletedCount, 4),
                    style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ChecklistRow(
                      step: tr.formatNumber(1),
                      title: tr.addAccountChecklist,
                      subtitle: viewModel.hasAccounts
                          ? '${tr.done} · ${viewModel.snapshot.accounts.first.name}'
                          : tr.balanceRealSubtitle,
                      isDone: viewModel.hasAccounts,
                      onTap: () => context.push(AppRoutes.addAccount),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: tr.formatNumber(2),
                      title: tr.addJobChecklist,
                      subtitle: viewModel.hasJobs
                          ? '${tr.done} · ${viewModel.snapshot.jobs.first.name}'
                          : tr.shiftsLiveHereSubtitle,
                      isDone: viewModel.hasJobs,
                      onTap: () => context.push(AppRoutes.addJob),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: tr.formatNumber(3),
                      title: tr.setGoalChecklist,
                      subtitle: viewModel.hasGoals
                          ? '${tr.done} · ${viewModel.snapshot.goals.first.name}'
                          : tr.giveMoneyReasonSubtitle,
                      isDone: viewModel.hasGoals,
                      onTap: () => context.push(AppRoutes.addGoal),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: tr.formatNumber(4),
                      title: tr.turnOnAlertsChecklist,
                      subtitle: viewModel.hasAlerts
                          ? tr.done
                          : tr.neverMissShiftOrBillSubtitle,
                      isDone: viewModel.hasAlerts,
                      onTap: () => context.push(AppRoutes.alerts),
                    ),
                  ],
                ),
              ),
            ],

            // Quick actions
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                Expanded(
                  child: workViewModel.isClockedIn
                      ? AppButton(
                          tr.activeShift,
                          icon: HugeIcons.strokeRoundedClock01,
                          kind: AppButtonKind.success,
                          onPressed: () => context.push(AppRoutes.liveShift),
                        )
                      : AppButton(
                          tr.startShift,
                          icon: HugeIcons.strokeRoundedPlay,
                          kind: AppButtonKind.secondary,
                          onPressed: () => context.push(AppRoutes.startShift),
                        ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: AppButton(
                    tr.hyprAi,
                    icon: HugeIcons.strokeRoundedChatBot,
                    onPressed: () => context.push(AppRoutes.assistant),
                  ),
                ),
              ],
            ),

            if (viewModel.hasAccounts) HomeInsights(viewModel: viewModel),

            // This week section
            const SizedBox(height: AppSpace.xxl),
            SectionHeader(
              tr.upcomingEvents,
              actionLabel: tr.seeAll,
              onAction: () => context.go(AppRoutes.calendar),
            ),
            if (viewModel.upcomingEvents.isEmpty)
              AppCard(
                child: Text(
                  tr.noUpcomingEvents,
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
                    for (var i = 0; i < viewModel.upcomingEvents.take(4).length; i++) ...[
                      if (i > 0) const RowDivider(),
                      UpcomingEventRow(event: viewModel.upcomingEvents[i], currency: viewModel.baseCurrency),
                    ],
                  ],
                ),
              ),

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
                    for (var i = 0; i < viewModel.recentTransactions.length; i++) ...[
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
              child: isDone
                  ? Icon(Icons.check, size: 16, color: context.colors.income)
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
                      color: isDone ? context.colors.income : scheme.onSurfaceVariant,
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
    return '$h:$m:$s';
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
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
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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


