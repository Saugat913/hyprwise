import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';

/// Two-column bracket indicators under the stack bar (Spendable & Reserved).
class LiquidityBrackets extends StatelessWidget {
  const LiquidityBrackets({
    super.key,
    required this.viewModel,
    required this.compact,
  });

  final HomeViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.strings;

    final usableRatio = viewModel.usableRatio;
    final nonUsableRatio = viewModel.nonUsableRatio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _BracketColumn(
            topBorderColor: colors.liquid,
            label: tr.spendable,
            percentage: '${tr.formatNumber((usableRatio * 100).round())}%',
            amount: MoneyFormatter.format(
              viewModel.usableBalanceMinor,
              viewModel.baseCurrency,
            ),
            subtitle: tr.everydayAndCash,
            compact: compact,
            onTap: () => context.push(AppRoutes.accounts),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: _BracketColumn(
            topBorderColor: colors.reserved,
            label: tr.reserved,
            percentage: '${tr.formatNumber((nonUsableRatio * 100).round())}%',
            amount: MoneyFormatter.format(
              viewModel.nonUsableBalanceMinor,
              viewModel.baseCurrency,
            ),
            subtitle: tr.savingsAndGoals,
            compact: compact,
            onTap: () => context.push(AppRoutes.plan),
          ),
        ),
      ],
    );
  }
}

class _BracketColumn extends StatelessWidget {
  const _BracketColumn({
    required this.topBorderColor,
    required this.label,
    required this.percentage,
    required this.amount,
    required this.subtitle,
    required this.compact,
    required this.onTap,
  });

  final Color topBorderColor;
  final String label;
  final String percentage;
  final String amount;
  final String subtitle;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: topBorderColor, width: 2.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label + Percentage Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      color: colors.onHeroSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  percentage,
                  style: text.labelSmall?.copyWith(
                    color: colors.onHeroSecondary,
                    fontSize: 12,
                    fontFamily: 'RedditMono',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Amount figure (mono 14 w500)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                amount,
                style: text.labelLarge?.copyWith(
                  color: colors.onHero,
                  fontFamily: 'RedditMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),

            // Subtitle
            Text(
              subtitle,
              style: text.bodySmall?.copyWith(
                color: colors.textMuted,
                fontSize: 11,
              ),
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
