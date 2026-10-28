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
            // Projected balance in 3 months
            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.projectedBalanceIn3Months,
                    style: text.bodyMedium?.copyWith(color: colors.onHeroSecondary),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    MoneyFormatter.format(viewModel.projectedBalanceIn3Months, viewModel.baseCurrency),
                    style: text.displaySmall?.copyWith(
                      color: colors.onHero,
                      fontWeight: FontWeight.w700,
                    ),
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

                    // Quick chip additions
                    Wrap(
                      spacing: AppSpace.sm,
                      children: [
                        for (final amt in [20, 50, 100, 250])
                          ChoicePill(
                            '+${goal.currencyCode} $amt',
                            selected: false,
                            onTap: () {
                              final curr = double.tryParse(amountController.text) ?? 0.0;
                              amountController.text = (curr + amt).toStringAsFixed(0);
                            },
                          ),
                      ],
                    ),

                    if (accounts.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.lg),
                      Text(tr.transferFrom, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpace.xs),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedSourceAccountId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
                        ),
                        items: [
                          for (final acc in accounts)
                            DropdownMenuItem<int?>(
                              value: acc.id,
                              child: Text(
                                '${tr.accountDisplayName(acc.name)} (${MoneyFormatter.format(viewModel.financeStore.snapshot.balanceOf(acc.id), acc.currencyCode)})',
                              ),
                            ),
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(tr.directDepositOrExternal),
                          ),
                        ],
                        onChanged: (val) => setState(() => selectedSourceAccountId = val),
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
