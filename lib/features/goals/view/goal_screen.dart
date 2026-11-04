// The detailed trajectory widgets remain available for the Analytics surface,
// but the Plan tab deliberately uses the compact outlook summary below.
// ignore_for_file: unused_element, unused_element_parameter

import 'dart:math' as math;
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
import 'package:finance_tracker/features/goals/data/model/goals.dart';
import 'package:finance_tracker/features/goals/viewmodels/goal_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<GoalViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;
        final forecasts = viewModel.filteredGoalForecasts;

        return TabPage(
          title: tr.goals,
          actions: [
            TopBarAction(
              HugeIcons.strokeRoundedPlusSign,
              tooltip: tr.newGoal,
              onPressed: () => context.push(AppRoutes.addGoal),
            ),
          ],
          children: [
            // Spacious and calm goal hero card matching Home hero card
            _PlanOutlookHero(viewModel: viewModel),
            const SizedBox(height: AppSpace.xl),

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
                        ne:
                            'प्रगतिमा (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        es:
                            'En curso (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        fr:
                            'En cours (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        de:
                            'In Arbeit (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        ja:
                            '進行中 (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        zh:
                            '进行中 (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                        it:
                            'In corso (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction < 1.0).length)})',
                      ),
                      isSelected: viewModel.filter == GoalFilter.inProgress,
                      onTap: () => viewModel.setFilter(GoalFilter.inProgress),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    _FilterPill(
                      label: tr.t(
                        'Completed (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        ne:
                            'सम्पन्न (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        es:
                            'Completados (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        fr:
                            'Terminés (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        de:
                            'Erreicht (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        ja:
                            '達成済み (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        zh:
                            '已达成 (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
                        it:
                            'Completati (${tr.formatNumber(viewModel.goalForecasts.where((g) => g.progress.fraction >= 1.0).length)})',
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    gf.goal.name,
                                    style: text.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    onTap: () => _showEditGoalSheet(context, viewModel, gf.goal),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: AppIcon(
                                        HugeIcons.strokeRoundedPencilEdit02,
                                        size: 16,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (gf.goal.priority == 'high') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.fill,
                              borderRadius: BorderRadius.circular(
                                AppRadius.md,
                              ),
                            ),
                            child: Text(
                              '${tr.formatNumber((gf.progress.fraction * 100).round())}%',
                              style: text.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyFormatter.format(gf.progress.savedMinor, gf.goal.currencyCode)} '
                        '${tr.ofTarget(MoneyFormatter.format(gf.goal.targetAmountMinor, gf.goal.currencyCode))}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      ProgressLine(gf.progress.fraction),
                      if (gf.progress.fraction < 1.0) ...[
                        const SizedBox(height: AppSpace.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusChip(
                            gf.onTrack
                                ? tr.t(
                                  'On track',
                                  ne: 'ठीक बाटोमा',
                                  es: 'En camino',
                                  fr: 'Dans les temps',
                                  de: 'Im Plan',
                                  ja: '順調',
                                  zh: '进度正常',
                                  it: 'In linea',
                                )
                                : '${tr.t('Short by', ne: 'कम', es: 'Faltan', fr: 'Manque', de: 'Fehlt', ja: '不足', zh: '缺口', it: 'Mancano')} ${MoneyFormatter.format(gf.shortfallMinor, gf.goal.currencyCode)}',
                            tone:
                                gf.onTrack
                                    ? ChipTone.success
                                    : ChipTone.warning,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.md),
                      Row(
                        children: [
                          if (gf.goal.accountId != null) ...[
                            Builder(
                              builder: (context) {
                                final acc = viewModel.accountById(
                                  gf.goal.accountId,
                                );
                                return Expanded(
                                  child: Row(
                                    children: [
                                      const AppIcon(
                                        HugeIcons.strokeRoundedSafe,
                                        size: 14,
                                        color: Color(0xFF1F7A45),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          acc != null
                                              ? tr.accountDisplayName(acc.name)
                                              : tr.savingsAccount,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.md,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                            icon: const AppIcon(
                              HugeIcons.strokeRoundedAddCircleHalfDot,
                              size: 15,
                              color: Color(0xFF1F7A45),
                            ),
                            label: Text(
                              tr.depositOrSave,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed:
                                () => _showAddSavingsDialog(
                                  context,
                                  viewModel,
                                  gf.goal,
                                ),
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

  void _showAddSavingsDialog(
    BuildContext context,
    PlanViewModel viewModel,
    Goal goal,
  ) {
    final amountController = TextEditingController();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;
    final accounts =
        viewModel.accounts
            .where((a) => a.id != goal.accountId && !a.isArchived)
            .toList();
    int? selectedSourceAccountId =
        accounts.isNotEmpty ? accounts.first.id : null;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
                child: SingleChildScrollView(
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
                            color: const Color(
                              0xFF1F7A45,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: const AppIcon(
                            HugeIcons.strokeRoundedTarget02,
                            size: 22,
                            color: Color(0xFF1F7A45),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.depositToGoalName(goal.name),
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal.accountId != null
                                    ? tr.distributesIntoLinkedSavings
                                    : tr.contributeFundsTowardsGoal,
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                    AppButton(
                      tr.saveToGoal,
                      onPressed: () async {
                        final amt = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (amt == null || amt <= 0) {
                          showErrorToast(ctx, tr.enterValidAmount);
                          return;
                        }
                        final amountMinor = (amt * 100).round();
                        if (selectedSourceAccountId != null) {
                          final currentBalance = viewModel.financeStore.snapshot
                              .balanceOf(selectedSourceAccountId!);
                          if (currentBalance < amountMinor) {
                            final accCurrency = viewModel.financeStore.snapshot
                                .currencyOf(selectedSourceAccountId!);
                            showErrorToast(
                              ctx,
                              tr.t(
                                'Insufficient balance: Only ${MoneyFormatter.format(currentBalance, accCurrency)} available in this account.',
                                ne:
                                    'अपर्याप्त ब्यालेन्स: यस खातामा मात्र ${MoneyFormatter.format(currentBalance, accCurrency)} उपलब्ध छ।',
                                es:
                                    'Saldo insuficiente: Solo ${MoneyFormatter.format(currentBalance, accCurrency)} disponible.',
                                fr:
                                    'Solde insuffisant : Seulement ${MoneyFormatter.format(currentBalance, accCurrency)} disponible.',
                                de:
                                    'Unzureichender Saldo: Nur ${MoneyFormatter.format(currentBalance, accCurrency)} verfügbar.',
                                ja:
                                    '残高不足: この口座には${MoneyFormatter.format(currentBalance, accCurrency)}しかありません。',
                                zh:
                                    '余额不足：该账户中仅有 ${MoneyFormatter.format(currentBalance, accCurrency)} 可用。',
                                it:
                                    'Saldo insufficiente: Solo ${MoneyFormatter.format(currentBalance, accCurrency)} disponibile.',
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
                          showToast(
                            context,
                            tr.addedToGoalMessage(
                              MoneyFormatter.format(
                                amountMinor,
                                goal.currencyCode,
                              ),
                              goal.name,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  void _showEditGoalSheet(
    BuildContext context,
    PlanViewModel viewModel,
    Goal goal,
  ) {
    final nameController = TextEditingController(text: goal.name);
    final targetController = TextEditingController(
      text: (goal.targetAmountMinor / 100).toStringAsFixed(2),
    );
    final noteController = TextEditingController(text: goal.note ?? '');
    DateTime? selectedDate = goal.targetDate != null
        ? DateTime.fromMillisecondsSinceEpoch(goal.targetDate!)
        : null;
    var priority = goal.priority == 'high' ? GoalPriority.high : GoalPriority.normal;

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
                child: SingleChildScrollView(
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
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            alignment: Alignment.center,
                            child: AppIcon(
                              HugeIcons.strokeRoundedPencilEdit02,
                              size: 22,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.t(
                                    'Edit Goal',
                                    ne: 'लक्ष्य सम्पादन गर्नुहोस्',
                                    es: 'Editar meta',
                                    fr: 'Modifier l\'objectif',
                                    de: 'Ziel bearbeiten',
                                    ja: '目標を編集',
                                    zh: '编辑目标',
                                    it: 'Modifica obiettivo',
                                  ),
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr.t(
                                    'Update name, target amount, or timeline',
                                    ne: 'नाम, लक्ष्य रकम वा समयसीमा परिवर्तन गर्नुहोस्',
                                    es: 'Actualiza nombre, monto o plazo',
                                    fr: 'Mettez à jour le nom, le montant ou l\'échéance',
                                    de: 'Name, Zielbetrag oder Zeitplan aktualisieren',
                                    ja: '名前、目標額、期限を更新',
                                    zh: '更新名称、目标金额或期限',
                                    it: 'Aggiorna nome, importo o scadenza',
                                  ),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),

                      UnderlineField(
                        label: tr.t(
                          'Goal Name',
                          ne: 'लक्ष्यको नाम',
                          es: 'Nombre de meta',
                          fr: 'Nom de l\'objectif',
                          de: 'Zielname',
                          ja: '目標名',
                          zh: '目标名称',
                          it: 'Nome obiettivo',
                        ),
                        hint: tr.myGoal,
                        controller: nameController,
                        autofocus: false,
                      ),
                      const SizedBox(height: AppSpace.md),

                      UnderlineField(
                        label: tr.t(
                          'Target Amount (${goal.currencyCode})',
                          ne: 'लक्ष्य रकम (${goal.currencyCode})',
                          es: 'Monto objetivo (${goal.currencyCode})',
                          fr: 'Montant cible (${goal.currencyCode})',
                          de: 'Zielbetrag (${goal.currencyCode})',
                          ja: '目標金額 (${goal.currencyCode})',
                          zh: '目标金额 (${goal.currencyCode})',
                          it: 'Importo obiettivo (${goal.currencyCode})',
                        ),
                        hint: '1000.00',
                        controller: targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),

                      Text(
                        tr.t(
                          'Target Date',
                          ne: 'लक्ष्य मिति',
                          es: 'Fecha objetivo',
                          fr: 'Date cible',
                          de: 'Zieldatum',
                          ja: '目標期日',
                          zh: '目标日期',
                          it: 'Data obiettivo',
                        ),
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate ??
                                DateTime.now().add(const Duration(days: 90)),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.sm + 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              AppIcon(
                                HugeIcons.strokeRoundedCalendar03,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Text(
                                  selectedDate != null
                                      ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, "0")}-${selectedDate!.day.toString().padLeft(2, "0")}'
                                      : tr.t(
                                          'No target date set',
                                          ne: 'कुनै मिति तोकिएको छैन',
                                        ),
                                  style: text.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (selectedDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(() => selectedDate = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),

                      Text(
                        tr.t(
                          'Priority',
                          ne: 'प्राथमिकता',
                          es: 'Prioridad',
                          fr: 'Priorité',
                          de: 'Priorität',
                          ja: '優先度',
                          zh: '优先级',
                          it: 'Priorità',
                        ),
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Center(
                                child: Text(
                                  tr.t('Normal', ne: 'सामान्य', es: 'Normal'),
                                ),
                              ),
                              selected: priority == GoalPriority.normal,
                              onSelected: (val) {
                                if (val) {
                                  setState(() => priority = GoalPriority.normal);
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: ChoiceChip(
                              label: Center(
                                child: Text(
                                  tr.highPriority,
                                  style: TextStyle(
                                    color: priority == GoalPriority.high
                                        ? const Color(0xFFB45309)
                                        : null,
                                    fontWeight: priority == GoalPriority.high
                                        ? FontWeight.w700
                                        : null,
                                  ),
                                ),
                              ),
                              selected: priority == GoalPriority.high,
                              selectedColor: const Color(0xFFFEF3C7),
                              onSelected: (val) {
                                if (val) {
                                  setState(() => priority = GoalPriority.high);
                                }
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xl),

                      AppButton(
                        tr.t(
                          'Save Changes',
                          ne: 'परिवर्तनहरू सुरक्षित गर्नुहोस्',
                          es: 'Guardar cambios',
                          fr: 'Enregistrer les modifications',
                          de: 'Änderungen speichern',
                          ja: '変更を保存',
                          zh: '保存更改',
                          it: 'Salva modifiche',
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            showErrorToast(
                              ctx,
                              tr.t(
                                'Please enter a goal name',
                                ne: 'कृपया लक्ष्यको नाम प्रविष्ट गर्नुहोस्',
                              ),
                            );
                            return;
                          }
                          final amt = double.tryParse(
                            targetController.text.trim(),
                          );
                          if (amt == null || amt <= 0) {
                            showErrorToast(ctx, tr.enterValidAmount);
                            return;
                          }
                          final targetMinor = (amt * 100).round();
                          await viewModel.updateGoal(
                            id: goal.id,
                            name: name,
                            targetAmountMinor: targetMinor,
                            targetDate: selectedDate,
                            accountId: goal.accountId,
                            priority: priority,
                            note: noteController.text.trim().isNotEmpty
                                ? noteController.text.trim()
                                : goal.note,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            showToast(
                              context,
                              tr.t(
                                'Goal updated successfully',
                                ne: 'लक्ष्य सफलतापूर्वक अद्यावधिक गरियो',
                                es: 'Meta actualizada',
                                fr: 'Objectif mis à jour',
                                de: 'Ziel aktualisiert',
                                ja: '目標を更新しました',
                                zh: '目标已更新',
                                it: 'Obiettivo aggiornato',
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: AppSpace.sm),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(
                            color: scheme.error.withValues(alpha: 0.5),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: Text(
                                tr.t('Delete Goal?', ne: 'लक्ष्य मेटाउने?'),
                              ),
                              content: Text(
                                tr.t(
                                  'Are you sure you want to delete "${goal.name}"? This action cannot be undone.',
                                  ne:
                                      'के तपाईं "${goal.name}" मेटाउन निश्चित हुनुहुन्छ?',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: Text(tr.cancel),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: scheme.error,
                                  ),
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  child: Text(tr.delete),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await viewModel.deleteGoal(goal.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              showToast(
                                context,
                                tr.t('Goal deleted', ne: 'लक्ष्य मेटाइयो'),
                              );
                            }
                          }
                        },
                        child: Text(
                          tr.t(
                            'Delete Goal',
                            ne: 'लक्ष्य मेटाउनुहोस्',
                            es: 'Eliminar meta',
                            fr: 'Supprimer l\'objectif',
                            de: 'Ziel löschen',
                            ja: '目標を削除',
                            zh: '删除目标',
                            it: 'Elimina obiettivo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Compact plan summary that matches the information hierarchy of Home's
/// balance hero: one answer first, followed by the smallest useful context.
class _PlanOutlookHero extends StatelessWidget {
  const _PlanOutlookHero({required this.viewModel});

  final PlanViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;
    final monthlyDelta = viewModel.monthlyNetDeltaMinor;
    final deltaColor =
        monthlyDelta < 0
            ? colors.expense
            : (monthlyDelta > 0 ? colors.income : colors.onHeroSecondary);

    return HeroCard(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -86,
            right: -88,
            child: IgnorePointer(
              child: Container(
                width: 248,
                height: 248,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brand.withValues(alpha: 0.10),
                  border: Border.all(
                    color: colors.brand.withValues(alpha: 0.12),
                    width: 30,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.projectedBalanceIn3Months,
                style: text.bodySmall?.copyWith(
                  color: colors.onHeroSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  MoneyFormatter.format(
                    viewModel.projectedBalanceIn3Months,
                    viewModel.baseCurrency,
                  ),
                  style: text.displaySmall?.copyWith(
                    color: colors.onHero,
                    fontFamily: 'RedditMono',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                tr.t(
                  'Based on your planned income and bills',
                  ne: 'तपाईंको योजना गरिएको आम्दानी र बिलमा आधारित',
                  hi: 'आपकी नियोजित आय और बिलों के आधार पर',
                  es: 'Según tus ingresos y facturas planificados',
                  fr: 'Selon vos revenus et factures prévus',
                  de: 'Basierend auf Ihren geplanten Einnahmen und Rechnungen',
                  ja: '予定収入と請求額に基づく見通し',
                  zh: '基于您的计划收入和账单',
                  it: 'In base a entrate e bollette pianificate',
                ),
                style: text.bodySmall?.copyWith(color: colors.onHeroSecondary),
              ),
              const SizedBox(height: AppSpace.lg),
              Divider(height: 1, color: colors.onHero.withValues(alpha: 0.12)),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: _PlanHeroMetric(
                      label: tr.t(
                        'Current balance',
                        ne: 'हालको ब्यालेन्स',
                        hi: 'वर्तमान बैलेंस',
                        es: 'Saldo actual',
                        fr: 'Solde actuel',
                        de: 'Aktueller Kontostand',
                        ja: '現在の残高',
                        zh: '当前余额',
                        it: 'Saldo attuale',
                      ),
                      value: MoneyFormatter.format(
                        viewModel.currentTotalBalanceMinor,
                        viewModel.baseCurrency,
                      ),
                      color: colors.onHero,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: colors.onHero.withValues(alpha: 0.12),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpace.md),
                      child: _PlanHeroMetric(
                        label: tr.t(
                          'Monthly change',
                          ne: 'मासिक परिवर्तन',
                          hi: 'मासिक बदलाव',
                          es: 'Cambio mensual',
                          fr: 'Variation mensuelle',
                          de: 'Monatliche Veränderung',
                          ja: '月ごとの変化',
                          zh: '每月变化',
                          it: 'Variazione mensile',
                        ),
                        value:
                            '${monthlyDelta > 0 ? '+' : ''}${MoneyFormatter.format(monthlyDelta, viewModel.baseCurrency)}',
                        color: deltaColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanHeroMetric extends StatelessWidget {
  const _PlanHeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(color: colors.onHeroSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpace.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: text.labelLarge?.copyWith(
              color: color,
              fontFamily: 'RedditMono',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
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

class _PlanVelocityBadge extends StatelessWidget {
  const _PlanVelocityBadge({required this.viewModel});

  final PlanViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final heroIsDark = colors.hero.computeLuminance() < 0.5;

    final deltaMinor = viewModel.monthlyNetDeltaMinor;
    final growthRate = viewModel.threeMonthGrowthRatePercent;

    final IconData icon;
    final Color bg;
    final Color fg;
    final String label;

    if (deltaMinor > 0) {
      icon = Icons.trending_up_rounded;
      final tone = _heroTone(true, heroIsDark);
      bg = tone.bg;
      fg = tone.fg;
      final deltaFormatted = MoneyFormatter.format(
        deltaMinor,
        viewModel.baseCurrency,
      );
      final rateStr =
          growthRate != null
              ? ' · +${growthRate.abs().toStringAsFixed(1)}% (90d)'
              : '';
      label = '+$deltaFormatted / mo$rateStr';
    } else if (deltaMinor < 0) {
      icon = Icons.trending_down_rounded;
      final tone = _heroTone(false, heroIsDark);
      bg = tone.bg;
      fg = tone.fg;
      final deltaFormatted = MoneyFormatter.format(
        deltaMinor.abs(),
        viewModel.baseCurrency,
      );
      final rateStr =
          growthRate != null
              ? ' · -${growthRate.abs().toStringAsFixed(1)}% (90d)'
              : '';
      label = '−$deltaFormatted / mo$rateStr';
    } else {
      icon = Icons.trending_flat_rounded;
      bg = colors.onHero.withValues(alpha: 0.12);
      fg = colors.onHeroSecondary;
      final zeroFormatted = MoneyFormatter.format(0, viewModel.baseCurrency);
      label = '$zeroFormatted / mo · Steady';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: 'RedditMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanMetricBridge extends StatelessWidget {
  const _PlanMetricBridge({required this.viewModel});

  final PlanViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;
    final heroIsDark = colors.hero.computeLuminance() < 0.5;

    final netChange = viewModel.threeMonthNetChangeMinor;
    final isPositiveNet = netChange > 0;
    final isNegativeNet = netChange < 0;

    final ({Color bg, Color fg}) netTone;
    final String netPrefix;
    if (isPositiveNet) {
      netTone = _heroTone(true, heroIsDark);
      netPrefix = '+';
    } else if (isNegativeNet) {
      netTone = _heroTone(false, heroIsDark);
      netPrefix = '';
    } else {
      netTone = (
        bg: colors.onHero.withValues(alpha: 0.12),
        fg: colors.onHeroSecondary,
      );
      netPrefix = '';
    }

    final netFormatted = MoneyFormatter.format(
      netChange,
      viewModel.baseCurrency,
    );
    final netChangeText = '$netPrefix$netFormatted (90d)';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: colors.onHero.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.onHero.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Left: Current Balance
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr.t(
                    'Current',
                    ne: 'हाल',
                    es: 'Actual',
                    fr: 'Actuel',
                    de: 'Aktuell',
                    ja: '現在',
                    zh: '当前',
                    it: 'Attuale',
                  ),
                  style: text.labelSmall?.copyWith(
                    color: colors.onHeroSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    MoneyFormatter.format(
                      viewModel.currentTotalBalanceMinor,
                      viewModel.baseCurrency,
                    ),
                    style: text.labelMedium?.copyWith(
                      color: colors.onHero,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RedditMono',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Center: Directional capsule pill showing 90-day net change
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: netTone.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    netChangeText,
                    style: text.labelSmall?.copyWith(
                      color: netTone.fg,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RedditMono',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right: Projected Balance
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr.t(
                    'In 3 months',
                    ne: '३ महिनामा',
                    es: 'En 3 meses',
                    fr: 'Dans 3 mois',
                    de: 'In 3 Monaten',
                    ja: '3ヶ月後',
                    zh: '3个月后',
                    it: 'In 3 mesi',
                  ),
                  style: text.labelSmall?.copyWith(
                    color: colors.onHeroSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    MoneyFormatter.format(
                      viewModel.projectedBalanceIn3Months,
                      viewModel.baseCurrency,
                    ),
                    style: text.labelMedium?.copyWith(
                      color: colors.onHero,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RedditMono',
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

class _PlanTrajectoryVector extends StatelessWidget {
  const _PlanTrajectoryVector({
    required this.points,
    required this.currencyCode,
    this.monthlyNetDeltaMinor = 0,
  });

  final List<PlanForecastPoint> points;
  final String currencyCode;
  final int monthlyNetDeltaMinor;
  static const double height = 60.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;
    final heroIsDark = colors.hero.computeLuminance() < 0.5;

    if (points.isEmpty) return const SizedBox.shrink();

    final forecastColor =
        monthlyNetDeltaMinor < 0
            ? (heroIsDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C))
            : colors.brand;

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
        border: Border.all(
          color: colors.onHero.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
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
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size.infinite,
              painter: _PlanTrajectoryPainter(
                points: points,
                onHero: colors.onHero,
                onHeroSecondary: colors.onHeroSecondary,
                forecastColor: forecastColor,
                heroBackground: colors.hero,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              for (final point in points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color:
                          point.isForecast
                              ? forecastColor
                              : colors.onHeroSecondary,
                      fontWeight:
                          point.isForecast ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanTrajectoryPainter extends CustomPainter {
  _PlanTrajectoryPainter({
    required this.points,
    required this.onHero,
    required this.onHeroSecondary,
    required this.forecastColor,
    required this.heroBackground,
  });

  final List<PlanForecastPoint> points;
  final Color onHero;
  final Color onHeroSecondary;
  final Color forecastColor;
  final Color heroBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final balances = points.map((p) => p.balanceMinor.toDouble()).toList();
    final actualMin = balances.reduce(math.min);
    final actualMax = balances.reduce(math.max);

    // Normalizes across all points including 0
    final minVal = math.min(0.0, actualMin);
    final maxVal = math.max(0.0, actualMax);
    var range = maxVal - minVal;
    if (range == 0) range = 100.0;

    const topPadding = 6.0;
    const bottomPadding = 6.0;
    final usableHeight = size.height - topPadding - bottomPadding;

    double yFor(double val) {
      return topPadding + usableHeight * (1.0 - (val - minVal) / range);
    }

    final n = points.length;
    final colWidth = size.width / n;
    final offsets = <Offset>[];
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) * colWidth;
      final y = yFor(balances[i]);
      offsets.add(Offset(x, y));
    }

    // Zero-baseline: if trajectory crosses zero or approaches zero
    final hasNegative = balances.any((b) => b < 0);
    final hasZero = balances.any((b) => b == 0);
    final approachesZero = actualMin <= range * 0.25;
    if (hasNegative || hasZero || approachesZero) {
      final zeroY = yFor(0.0);
      final zeroPaint =
          Paint()
            ..color = onHero.withValues(alpha: 0.18)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

      const dashWidth = 3.0;
      const dashSpace = 3.0;
      var curX = 0.0;
      while (curX < size.width) {
        canvas.drawLine(
          Offset(curX, zeroY),
          Offset(math.min(curX + dashWidth, size.width), zeroY),
          zeroPaint,
        );
        curX += dashWidth + dashSpace;
      }
    }

    // Historical path (M-2 to M0): indices 0 to histEndIndex
    final firstForecastIndex = points.indexWhere((p) => p.isForecast);
    final histEndIndex =
        (firstForecastIndex > 0) ? (firstForecastIndex - 1) : (n ~/ 2);

    final histPaint =
        Paint()
          ..color = onHeroSecondary.withValues(alpha: 0.4)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (var i = 0; i < histEndIndex; i++) {
      _drawDashedSegment(canvas, offsets[i], offsets[i + 1], histPaint);
    }

    // Small historical vertex dots
    final histDotPaint =
        Paint()
          ..color = onHeroSecondary.withValues(alpha: 0.45)
          ..style = PaintingStyle.fill;
    for (var i = 0; i <= histEndIndex; i++) {
      canvas.drawCircle(offsets[i], 2.5, histDotPaint);
    }

    // Forecast trajectory (M0 to M+3): indices histEndIndex to n - 1
    if (histEndIndex < n - 1) {
      final forecastPaint =
          Paint()
            ..color = forecastColor
            ..strokeWidth = 2.4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

      final forecastPath =
          Path()..moveTo(offsets[histEndIndex].dx, offsets[histEndIndex].dy);
      for (var i = histEndIndex + 1; i < n; i++) {
        forecastPath.lineTo(offsets[i].dx, offsets[i].dy);
      }
      canvas.drawPath(forecastPath, forecastPaint);

      // Intermediate forecast dots
      final intermediateDotPaint =
          Paint()
            ..color = forecastColor.withValues(alpha: 0.6)
            ..style = PaintingStyle.fill;
      for (var i = histEndIndex + 1; i < n - 1; i++) {
        canvas.drawCircle(offsets[i], 2.5, intermediateDotPaint);
      }

      // Terminating solid milestone dot at M+3 (last offset)
      final milestoneFill =
          Paint()
            ..color = forecastColor
            ..style = PaintingStyle.fill;
      final milestoneRing =
          Paint()
            ..color = heroBackground
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke;

      final lastOffset = offsets.last;
      canvas.drawCircle(lastOffset, 4.5, milestoneFill);
      canvas.drawCircle(lastOffset, 4.5, milestoneRing);
    }
  }

  void _drawDashedSegment(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    const dashLen = 4.0;
    const spaceLen = 3.0;
    var drawn = 0.0;
    while (drawn < dist) {
      final startFrac = drawn / dist;
      final endFrac = math.min((drawn + dashLen) / dist, 1.0);
      canvas.drawLine(
        Offset(p1.dx + dx * startFrac, p1.dy + dy * startFrac),
        Offset(p1.dx + dx * endFrac, p1.dy + dy * endFrac),
        paint,
      );
      drawn += dashLen + spaceLen;
    }
  }

  @override
  bool shouldRepaint(covariant _PlanTrajectoryPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.forecastColor != forecastColor ||
        oldDelegate.onHero != onHero ||
        oldDelegate.onHeroSecondary != onHeroSecondary ||
        oldDelegate.heroBackground != heroBackground;
  }
}

/// Readable positive/negative tones that contrast with the hero card in both themes.
({Color bg, Color fg}) _heroTone(bool positive, bool heroIsDark) {
  if (positive) {
    return heroIsDark
        ? (
          bg: const Color(0xFF22C55E).withValues(alpha: 0.2),
          fg: const Color(0xFF4ADE80),
        )
        : (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF15803D));
  }
  return heroIsDark
      ? (
        bg: const Color(0xFFEF4444).withValues(alpha: 0.2),
        fg: const Color(0xFFF87171),
      )
      : (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
}

/// Backwards compatibility alias for PlanScreen
typedef PlanScreen = GoalScreen;
