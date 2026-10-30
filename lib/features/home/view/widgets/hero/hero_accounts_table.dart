import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/transfers/presentation/transfers_screen.dart';

/// Interactive vertical accounts table below the stack bar & brackets.
class HeroAccountsTable extends StatelessWidget {
  const HeroAccountsTable({
    super.key,
    required this.viewModel,
    required this.selectedAccountId,
    required this.onSelectAccount,
  });

  final HomeViewModel viewModel;
  final int? selectedAccountId;
  final ValueChanged<int?> onSelectAccount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;

    final slices = viewModel.accountSlices;
    final totalNet = viewModel.netPositionMinor;

    // Check if savings fallback row is needed
    final hasSavings = slices.any((s) => !s.isSpendable);
    final showSavingsFallback = !hasSavings;

    // Build visible rows up to 5
    final displaySlices = slices.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row: "Accounts" left, "Transfer" pill right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                tr.accounts,
                style: text.bodySmall?.copyWith(
                  color: colors.onHeroSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (viewModel.accounts.length >= 2) ...[
              const SizedBox(width: AppSpace.sm),
              InkWell(
                onTap: () => showTransferFormModal(
                  context,
                  accounts: viewModel.accounts,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: colors.hairline, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        HugeIcons.strokeRoundedExchange01,
                        size: 14,
                        color: colors.onHero,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tr.transfer,
                        style: text.labelSmall?.copyWith(
                          color: colors.onHero,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.xs),

        // Account rows
        for (final slice in displaySlices) ...[
          _AccountRowItem(
            slice: slice,
            isSelected: selectedAccountId == slice.id,
            hasSelection: selectedAccountId != null,
            totalNet: totalNet,
            dotColor: slice.isSpendable ? colors.liquid : colors.reserved,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelectAccount(selectedAccountId == slice.id ? null : slice.id);
            },
            onOpen: () {
              if (slice.isSpendable) {
                context.push(AppRoutes.accounts);
              } else {
                context.push(AppRoutes.plan);
              }
            },
          ),
        ],

        // Savings fallback row if no savings account exists
        if (showSavingsFallback) ...[
          _SavingsFallbackRow(
            viewModel: viewModel,
            onTap: () => context.push(AppRoutes.plan),
          ),
        ],

        // View All row if more than 5 accounts exist
        if (slices.length > 5) ...[
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.hairlineSoft, width: 1.0)),
            ),
            child: InkWell(
              onTap: () => context.push(AppRoutes.accounts),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr.viewAll,
                      style: text.labelSmall?.copyWith(
                        color: colors.onHeroSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: colors.onHeroSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountRowItem extends StatelessWidget {
  const _AccountRowItem({
    required this.slice,
    required this.isSelected,
    required this.hasSelection,
    required this.totalNet,
    required this.dotColor,
    required this.onTap,
    required this.onOpen,
  });

  final HeroAccountSlice slice;
  final bool isSelected;
  final bool hasSelection;
  final int totalNet;
  final Color dotColor;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;

    final opacity = (!hasSelection || isSelected) ? 1.0 : 0.40;
    final sharePct = totalNet > 0 && slice.balanceInBaseMinor > 0
        ? ((slice.balanceInBaseMinor / totalNet) * 100).round()
        : null;

    final formattedAmt = MoneyFormatter.format(slice.balanceMinor, slice.currency);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.hairlineSoft, width: 1.0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onOpen,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // 10x10 dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),

                // Name (13px, ellipsis)
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          slice.name,
                          style: text.bodyMedium?.copyWith(
                            color: colors.onHero,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (sharePct != null) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              tr.percentOfNet(tr.formatNumber(sharePct)),
                              style: text.labelSmall?.copyWith(
                                color: colors.textMuted,
                                fontSize: 11,
                                fontFamily: 'RedditMono',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),

                // Balance right-aligned RedditMono 13 w500 in account currency
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      formattedAmt,
                      style: text.labelMedium?.copyWith(
                        color: slice.balanceMinor < 0 ? colors.expense : colors.onHero,
                        fontFamily: 'RedditMono',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Trailing chevron if selected
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.onHeroSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    onPressed: onOpen,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsFallbackRow extends StatelessWidget {
  const _SavingsFallbackRow({
    required this.viewModel,
    required this.onTap,
  });

  final HomeViewModel viewModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.hairlineSoft, width: 1.0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.reserved,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr.savings,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onHero,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    MoneyFormatter.format(
                      viewModel.savingsBalanceMinor,
                      viewModel.baseCurrency,
                    ),
                    style: text.labelMedium?.copyWith(
                      color: colors.onHero,
                      fontFamily: 'RedditMono',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
