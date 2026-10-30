import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/app_card.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/shared/widgets/row_divider.dart';
import 'package:finance_tracker/features/shared/widgets/section_header.dart';

/// Top Spending Categories card with proportional progress bars.
class TopSpendingCard extends StatelessWidget {
  const TopSpendingCard({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  static IconGlyph _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('grocer') || lower.contains('food') || lower.contains('market')) {
      return HugeIcons.strokeRoundedShoppingBag01;
    }
    if (lower.contains('din') || lower.contains('rest') || lower.contains('cafe') || lower.contains('eat')) {
      return HugeIcons.strokeRoundedRestaurant01;
    }
    if (lower.contains('bill') || lower.contains('util') || lower.contains('elect') || lower.contains('water')) {
      return HugeIcons.strokeRoundedInvoice;
    }
    if (lower.contains('rent') || lower.contains('home') || lower.contains('hous')) {
      return HugeIcons.strokeRoundedHome01;
    }
    if (lower.contains('trans') || lower.contains('fuel') || lower.contains('gas') || lower.contains('car')) {
      return HugeIcons.strokeRoundedCar01;
    }
    if (lower.contains('shop') || lower.contains('cloth')) {
      return HugeIcons.strokeRoundedShoppingBag02;
    }
    if (lower.contains('health') || lower.contains('med') || lower.contains('doc')) {
      return HugeIcons.strokeRoundedHealth;
    }
    if (lower.contains('fun') || lower.contains('game') || lower.contains('mov') || lower.contains('sub')) {
      return HugeIcons.strokeRoundedPlay;
    }
    return HugeIcons.strokeRoundedTag01;
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final categories = viewModel.topSpendingCategories;
    final totalExpense = viewModel.monthExpense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section title is strictly outside the white container with no logo
        SectionHeader(
          tr.topSpendingTitle,
          actionLabel: tr.seeAll,
          onAction: () => context.push(AppRoutes.analytics),
          padding: const EdgeInsets.fromLTRB(0, AppSpace.xl, 0, AppSpace.sm),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: categories.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: Text(
                    tr.noSpendingYet,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < categories.take(4).length; i++) ...[
                      if (i > 0) const RowDivider(),
                      InkWell(
                        onTap: () => context.push(AppRoutes.analytics),
                        child: _CategoryRow(
                          category: categories[i].key,
                          amountMinor: categories[i].value,
                          totalExpenseMinor: totalExpense,
                          currency: viewModel.baseCurrency,
                          icon: _iconForCategory(categories[i].key),
                          colors: colors,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amountMinor,
    required this.totalExpenseMinor,
    required this.currency,
    required this.icon,
    required this.colors,
  });

  final String category;
  final int amountMinor;
  final int totalExpenseMinor;
  final String currency;
  final IconGlyph icon;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final shareFraction = totalExpenseMinor > 0
        ? (amountMinor / totalExpenseMinor).clamp(0.0, 1.0)
        : 0.0;
    final sharePct = (shareFraction * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  tr.categoryLabel(category, category.replaceAll('_', ' ')),
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                '$sharePct%',
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  fontFamily: 'RedditMono',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    MoneyFormatter.format(amountMinor, currency),
                    style: text.bodyMedium?.copyWith(
                      fontFamily: 'RedditMono',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Stack(
              children: [
                Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: colors.expense.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: shareFraction,
                  child: Container(
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: colors.expense,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
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
