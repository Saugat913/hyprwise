import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/plan/viewmodels/plan_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<PlanViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;
        final forecasts = viewModel.filteredGoalForecasts;

        return TabPage(
          title: tr.plan,
          overline: tr.forecastAndGoals,
          actions: [
            TopBarAction(
              HugeIcons.strokeRoundedPlusSign,
              tooltip: tr.newGoal,
              onPressed: () => context.push(AppRoutes.addGoal),
            ),
          ],
          children: [
            // Projected balance in 3 months with Up/Down trajectory and forecast chart
            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.projectedBalanceIn3Months,
                              style: text.bodyMedium?.copyWith(
                                color: colors.onHeroSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpace.xs),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                MoneyFormatter.format(
                                  viewModel.projectedBalanceIn3Months,
                                  viewModel.baseCurrency,
                                ),
                                style: text.headlineMedium?.copyWith(
                                  color: colors.onHero,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'RedditMono',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      // Up / Down trajectory badge
                      Builder(
                        builder: (context) {
                          final isUp = viewModel.monthlyNetDeltaMinor >= 0;
                          final deltaMinor =
                              viewModel.monthlyNetDeltaMinor.abs();
                          final deltaFormatted = MoneyFormatter.format(
                            deltaMinor,
                            viewModel.baseCurrency,
                          );
                          final heroIsDark = colors.hero.computeLuminance() < 0.5;
                          final tone = _heroTone(isUp, heroIsDark);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm + 2,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tone.bg,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUp
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  size: 14,
                                  color: tone.fg,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isUp ? "+" : "−"}$deltaFormatted ${tr.perMonth}',
                                  style: text.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tone.fg,
                                    fontFamily: 'RedditMono',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Text(
                        '${tr.t('Current', ne: 'हाल', es: 'Actual', fr: 'Actuel', de: 'Aktuell', ja: '現在', zh: '当前', it: 'Attuale')}: ${MoneyFormatter.format(viewModel.currentTotalBalanceMinor, viewModel.baseCurrency)}',
                        style: text.bodySmall?.copyWith(
                          color: colors.onHeroSecondary,
                          fontFamily: 'RedditMono',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${viewModel.threeMonthNetChangeMinor >= 0 ? "+" : ""}${MoneyFormatter.format(viewModel.threeMonthNetChangeMinor, viewModel.baseCurrency)} (90d)',
                        style: text.bodySmall?.copyWith(
                          color: _heroTone(viewModel.threeMonthNetChangeMinor >= 0, colors.hero.computeLuminance() < 0.5).fg,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RedditMono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _PlanTrajectoryChart(
                    points: viewModel.trajectoryPoints,
                    currencyCode: viewModel.baseCurrency,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),

            // Goals section header
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr.goals,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            if (viewModel.goals.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterPill(
                      label: tr.allWithCount(viewModel.goals.length),
                      isSelected: viewModel.filter == GoalFilter.all,
                      onTap: () => viewModel.setFilter(GoalFilter.all),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    _FilterPill(
                      label: tr.t(
                        'In progress (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        ne: 'प्रगतिमा (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        es: 'En curso (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        fr: 'En cours (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        de: 'In Arbeit (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        ja: '進行中 (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        zh: '进行中 (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        it: 'In corso (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                      ),
                      isSelected: viewModel.filter == GoalFilter.inProgress,
                      onTap: () => viewModel.setFilter(GoalFilter.inProgress),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    _FilterPill(
                      label: tr.t(
                        'Completed (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        ne: 'सम्पन्न (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        es: 'Completados (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        fr: 'Terminés (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        de: 'Erreicht (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        ja: '達成済み (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        zh: '已达成 (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        it: 'Completati (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                      ),
                      isSelected: viewModel.filter == GoalFilter.completed,
                      onTap: () => viewModel.setFilter(GoalFilter.completed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],

            if (viewModel.goals.isEmpty)
              EmptyState(
                icon: HugeIcons.strokeRoundedTarget02,
                title: tr.noGoalsYet,
                message: tr.goalPlanningAdvice,
                actionLabel: tr.setGoalChecklist,
                onAction: () => context.push(AppRoutes.addGoal),
              )
            else if (forecasts.isEmpty)
              EmptyState(
                icon: HugeIcons.strokeRoundedTarget02,
                title: tr.noMatchingGoals,
                message: tr.tryDifferentFilter,
              )
            else ...[
              for (final gf in forecasts) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              gf.goal.name,
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (gf.goal.priority == 'high') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: Text(
                                tr.highPriority,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.fill,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '${tr.formatNumber((gf.progress.fraction * 100).round())}%',
                              style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyFormatter.format(gf.progress.savedMinor, gf.goal.currencyCode)} '
                        '${tr.ofTarget(MoneyFormatter.format(gf.goal.targetAmountMinor, gf.goal.currencyCode))}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpace.md),
                      ProgressLine(gf.progress.fraction),
                      if (gf.progress.fraction < 1.0) ...[
                        const SizedBox(height: AppSpace.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusChip(
                            gf.onTrack
                                ? tr.t('On track', ne: 'ठीक बाटोमा', es: 'En camino', fr: 'Dans les temps', de: 'Im Plan', ja: '順調', zh: '进度正常', it: 'In linea')
                                : '${tr.t('Short by', ne: 'कम', es: 'Faltan', fr: 'Manque', de: 'Fehlt', ja: '不足', zh: '缺口', it: 'Mancano')} ${MoneyFormatter.format(gf.shortfallMinor, gf.goal.currencyCode)}',
                            tone: gf.onTrack ? ChipTone.success : ChipTone.warning,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.md),
                      Row(
                        children: [
                          if (gf.goal.accountId != null) ...[
                            Builder(
                              builder: (context) {
                                final acc = viewModel.accountById(gf.goal.accountId);
                                return Expanded(
                                  child: Row(
                                    children: [
                                      const AppIcon(HugeIcons.strokeRoundedSafe, size: 14, color: Color(0xFF1F7A45)),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          acc != null ? tr.accountDisplayName(acc.name) : tr.savingsAccount,
                                          style: text.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F7A45),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ] else
                            const Spacer(),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                            ),
                            icon: const AppIcon(HugeIcons.strokeRoundedAddCircleHalfDot, size: 15, color: Color(0xFF1F7A45)),
                            label: Text(tr.depositOrSave, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () => _showAddSavingsDialog(context, viewModel, gf.goal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
            ],
          ],
        );
      },
    );
  }

  void _showAddSavingsDialog(BuildContext context, PlanViewModel viewModel, Goal goal) {
    final amountController = TextEditingController();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;
    final accounts = viewModel.accounts.where((a) => a.id != goal.accountId && !a.isArchived).toList();
    int? selectedSourceAccountId = accounts.isNotEmpty ? accounts.first.id : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.lg,
                  AppSpace.page,
                  MediaQuery.of(ctx).viewInsets.bottom + AppSpace.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F7A45).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: const AppIcon(HugeIcons.strokeRoundedTarget02, size: 22, color: Color(0xFF1F7A45)),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr.depositToGoalName(goal.name), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                goal.accountId != null
                                    ? tr.distributesIntoLinkedSavings
                                    : tr.contributeFundsTowardsGoal,
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),

                    UnderlineField(
                      label: tr.amountToAddWithCurrency(goal.currencyCode),
                      hint: '50.00',
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSpace.md),

                    // Quick addition cards (spacious horizontal cards)
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final amt in [20, 50, 100, 250])
                          Builder(
                            builder: (context) {
                              final curr =
                                  double.tryParse(amountController.text) ?? 0.0;
                              final isSelected = curr == amt.toDouble();
                              return InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                onTap: () {
                                  amountController.text = amt.toString();
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.md,
                                    vertical: AppSpace.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? scheme.primary.withValues(
                                              alpha: 0.12,
                                            )
                                            : scheme.surfaceContainerHighest
                                                .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? scheme.primary
                                              : scheme.outlineVariant
                                                  .withValues(alpha: 0.6),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    '+${goal.currencyCode} $amt',
                                    style: text.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isSelected
                                              ? scheme.primary
                                              : scheme.onSurface,
                                      fontFamily: 'RedditMono',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),

                    if (accounts.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        tr.transferFrom,
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      SizedBox(
                        height: 74,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final acc in accounts)
                              Builder(
                                builder: (context) {
                                  final isSelected =
                                      selectedSourceAccountId == acc.id;
                                  final bal = viewModel.financeStore.snapshot
                                      .balanceOf(acc.id);
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: AppSpace.sm,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      onTap:
                                          () => setState(
                                            () =>
                                                selectedSourceAccountId =
                                                    acc.id,
                                          ),
                                      child: Container(
                                        width: 154,
                                        padding: const EdgeInsets.all(
                                          AppSpace.sm + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? scheme.primary.withValues(
                                                    alpha: 0.1,
                                                  )
                                                  : scheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? scheme.primary
                                                    : scheme.outlineVariant
                                                        .withValues(alpha: 0.6),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                const AppIcon(
                                                  HugeIcons.strokeRoundedSafe,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    tr.accountDisplayName(
                                                      acc.name,
                                                    ),
                                                    style: text.bodySmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              isSelected
                                                                  ? FontWeight
                                                                      .w700
                                                                  : FontWeight
                                                                      .w600,
                                                          color:
                                                              isSelected
                                                                  ? scheme
                                                                      .primary
                                                                  : scheme
                                                                      .onSurface,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 14,
                                                    color: scheme.primary,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              MoneyFormatter.format(
                                                bal,
                                                acc.currencyCode,
                                              ),
                                              style: text.labelSmall?.copyWith(
                                                fontFamily: 'RedditMono',
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            // External / direct deposit card
                            Builder(
                              builder: (context) {
                                final isSelected =
                                    selectedSourceAccountId == null;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  onTap:
                                      () => setState(
                                        () => selectedSourceAccountId = null,
                                      ),
                                  child: Container(
                                    width: 144,
                                    padding: const EdgeInsets.all(
                                      AppSpace.sm + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? scheme.primary.withValues(
                                                alpha: 0.1,
                                              )
                                              : scheme.surfaceContainerHighest
                                                  .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? scheme.primary
                                                : scheme.outlineVariant
                                                    .withValues(alpha: 0.6),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            const AppIcon(
                                              HugeIcons.strokeRoundedCoins01,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                tr.directDepositOrExternal,
                                                style: text.bodySmall?.copyWith(
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                  color:
                                                      isSelected
                                                          ? scheme.primary
                                                          : scheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: scheme.primary,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tr.t(
                                            'External funds',
                                            ne: 'बाह्य रकम',
                                            es: 'Fondos externos',
                                          ),
                                          style: text.labelSmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpace.xl),
                    FilledButton(
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim());
                        if (amt == null || amt <= 0) {
                          showErrorToast(ctx, tr.enterValidAmount);
                          return;
                        }
                        final amountMinor = (amt * 100).round();
                        if (selectedSourceAccountId != null) {
                          final currentBalance = viewModel.financeStore.snapshot.balanceOf(selectedSourceAccountId!);
                          if (currentBalance < amountMinor) {
                            final accCurrency = viewModel.financeStore.snapshot.currencyOf(selectedSourceAccountId!);
                            showErrorToast(
                              ctx,
                              tr.t(
                                'Insufficient balance: Only ${MoneyFormatter.format(currentBalance, accCurrency)} available in this account.',
                                ne: 'अपर्याप्त ब्यालेन्स: यस खातामा मात्र ${MoneyFormatter.format(currentBalance, accCurrency)} उपलब्ध छ।',
                                es: 'Saldo insuficiente: Solo ${MoneyFormatter.format(currentBalance, accCurrency)} disponible.',
                                fr: 'Solde insuffisant : Seulement ${MoneyFormatter.format(currentBalance, accCurrency)} disponible.',
                                de: 'Unzureichender Saldo: Nur ${MoneyFormatter.format(currentBalance, accCurrency)} verfügbar.',
                                ja: '残高不足: この口座には${MoneyFormatter.format(currentBalance, accCurrency)}しかありません。',
                                zh: '余额不足：该账户中仅有 ${MoneyFormatter.format(currentBalance, accCurrency)} 可用。',
                                it: 'Saldo insufficiente: Solo ${MoneyFormatter.format(currentBalance, accCurrency)} disponibile.',
                              ),
                            );
                            return;
                          }
                        }
                        await viewModel.addSavingsToGoal(
                          goal: goal,
                          amountMinor: amountMinor,
                          fromAccountId: selectedSourceAccountId,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          showToast(context, tr.addedToGoalMessage(MoneyFormatter.format(amountMinor, goal.currencyCode), goal.name));
                        }
                      },
                      child: Text(tr.saveToGoal),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PlanTrajectoryChart extends StatelessWidget {
  const _PlanTrajectoryChart({
    required this.points,
    required this.currencyCode,
  });

  final List<PlanForecastPoint> points;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;
    final maxBal = points.fold<int>(
      1,
      (max, p) => p.balanceMinor > max ? p.balanceMinor : max,
    );
    final effectiveMax = maxBal <= 0 ? 100 : maxBal;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: colors.onHero.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.t(
                  '6-Month Balance Trajectory',
                  ne: '६-महिने ब्यालेन्स प्रक्षेपण',
                  es: 'Trayectoria de saldo de 6 meses',
                  fr: 'Trajectoire du solde sur 6 mois',
                  de: '6-Monats-Saldoverlauf',
                  ja: '6ヶ月の残高予測',
                  zh: '6个月余额走势',
                  it: 'Traiettoria del saldo a 6 mesi',
                ),
                style: text.labelSmall?.copyWith(
                  color: colors.onHeroSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  tr.t(
                    '3 mo Forecast',
                    ne: '३ महिना पूर्वानुमान',
                    es: 'Pronóstico 3 m',
                    fr: 'Prévision 3 mois',
                    de: '3-Monats-Prognose',
                    ja: '3ヶ月予測',
                    zh: '3个月预测',
                    it: 'Previsione a 3 m',
                  ),
                  style: text.labelSmall?.copyWith(
                    color: colors.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              MoneyFormatter.compact(
                                point.balanceMinor,
                                currencyCode,
                              ),
                              style: text.labelSmall?.copyWith(
                                color:
                                    point.isForecast
                                        ? colors.brand
                                        : colors.onHero,
                                fontFamily: 'RedditMono',
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final h = (point.balanceMinor /
                                          effectiveMax *
                                          constraints.maxHeight)
                                      .clamp(6.0, constraints.maxHeight);
                                  return Container(
                                    height: h,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          point.isForecast
                                              ? colors.brand.withValues(
                                                alpha: 0.85,
                                              )
                                              : colors.onHero.withValues(
                                                alpha: 0.35,
                                              ),
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          point.isForecast
                                              ? Border.all(
                                                color: colors.brand,
                                                width: 1,
                                              )
                                              : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            point.label,
                            style: text.labelSmall?.copyWith(
                              color:
                                  point.isForecast
                                      ? colors.brand
                                      : colors.onHeroSecondary,
                              fontWeight:
                                  point.isForecast
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



/// Readable positive/negative tones that contrast with the hero card in both themes.
({Color bg, Color fg}) _heroTone(bool positive, bool heroIsDark) {
  if (positive) {
    return heroIsDark
        ? (bg: const Color(0xFF22C55E).withValues(alpha: 0.2), fg: const Color(0xFF4ADE80))
        : (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF15803D));
  }
  return heroIsDark
      ? (bg: const Color(0xFFEF4444).withValues(alpha: 0.2), fg: const Color(0xFFF87171))
      : (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
}
