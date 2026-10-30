import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Single outlined strip summarizing active debts (Lent vs Borrowed).
class HeroDebtsStrip extends StatelessWidget {
  const HeroDebtsStrip({
    super.key,
    required this.viewModel,
    required this.compact,
  });

  final HomeViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;

    final lent = viewModel.totalLentMinor;
    final borrowed = viewModel.totalBorrowedMinor;
    final activeCount = viewModel.activeDebts.length;

    // Show only if debts exist or non-zero amounts
    if (lent <= 0 && borrowed <= 0 && activeCount == 0) {
      return const SizedBox.shrink();
    }

    final lentFormatted = MoneyFormatter.compact(lent, viewModel.baseCurrency);
    final borrowedFormatted = MoneyFormatter.compact(borrowed, viewModel.baseCurrency);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () => context.push(AppRoutes.debts),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.hairline, width: 1.0),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(
                          HugeIcons.strokeRoundedExchange01,
                          size: 14,
                          color: colors.onHeroSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${tr.debts} · ${tr.activeWithCount(activeCount)}',
                            style: text.bodySmall?.copyWith(
                              color: colors.onHeroSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colors.onHeroSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${tr.lentLabel} ',
                          style: text.bodySmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          lentFormatted,
                          style: text.labelSmall?.copyWith(
                            color: colors.onHero,
                            fontFamily: 'RedditMono',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' · ${tr.borrowedLabel} ',
                          style: text.bodySmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          borrowedFormatted,
                          style: text.labelSmall?.copyWith(
                            color: colors.onHero,
                            fontFamily: 'RedditMono',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    AppIcon(
                      HugeIcons.strokeRoundedExchange01,
                      size: 14,
                      color: colors.onHeroSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${tr.debts} · ${tr.activeWithCount(activeCount)}',
                        style: text.bodySmall?.copyWith(
                          color: colors.onHeroSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${tr.lentLabel} ',
                              style: text.bodySmall?.copyWith(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              lentFormatted,
                              style: text.labelSmall?.copyWith(
                                color: colors.onHero,
                                fontFamily: 'RedditMono',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' · ${tr.borrowedLabel} ',
                              style: text.bodySmall?.copyWith(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              borrowedFormatted,
                              style: text.labelSmall?.copyWith(
                                color: colors.onHero,
                                fontFamily: 'RedditMono',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: colors.onHeroSecondary,
                            ),
                          ],
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
