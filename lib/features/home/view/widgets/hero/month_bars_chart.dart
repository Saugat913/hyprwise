import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';

/// Week-by-week cash-flow comparison. Horizontal bars make relative income
/// and spending legible at a glance and keep the amounts aligned on phones.
class MonthBarsChart extends StatelessWidget {
  const MonthBarsChart({
    super.key,
    required this.viewModel,
    required this.selectedWeek,
    required this.onSelectWeek,
  });

  final HomeViewModel viewModel;
  final int selectedWeek;
  final ValueChanged<int> onSelectWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;
    final buckets = viewModel.monthWeeklyBuckets;
    final maximum = buckets.fold<int>(
      1,
      (value, bucket) =>
          math.max(value, math.max(bucket.income, bucket.expense)),
    );

    if (buckets.isEmpty) {
      return Text(
        tr.analyticsNoEntriesInPeriod,
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < buckets.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpace.sm),
          _WeekComparisonRow(
            bucket: buckets[index],
            maximum: maximum,
            selected: index == selectedWeek,
            incomeColor: colors.income,
            expenseColor: colors.expense,
            mutedColor: scheme.onSurfaceVariant,
            currency: viewModel.baseCurrency,
            incomeLabel: tr.income,
            expenseLabel: tr.expense,
            onTap: () {
              if (index != selectedWeek) HapticFeedback.selectionClick();
              onSelectWeek(index);
            },
          ),
        ],
      ],
    );
  }
}

class _WeekComparisonRow extends StatelessWidget {
  const _WeekComparisonRow({
    required this.bucket,
    required this.maximum,
    required this.selected,
    required this.incomeColor,
    required this.expenseColor,
    required this.mutedColor,
    required this.currency,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.onTap,
  });

  final ({String label, int income, int expense}) bucket;
  final int maximum;
  final bool selected;
  final Color incomeColor;
  final Color expenseColor;
  final Color mutedColor;
  final String currency;
  final String incomeLabel;
  final String expenseLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final incomeFraction = (bucket.income / maximum).clamp(0.0, 1.0);
    final expenseFraction = (bucket.expense / maximum).clamp(0.0, 1.0);

    return Material(
      color:
          selected
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  bucket.label,
                  style: text.labelSmall?.copyWith(
                    color: selected ? scheme.onSurface : mutedColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  children: [
                    _ComparisonBar(
                      fraction: incomeFraction,
                      color: incomeColor,
                    ),
                    const SizedBox(height: 5),
                    _ComparisonBar(
                      fraction: expenseFraction,
                      color: expenseColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MoneyFormatter.compact(bucket.income, currency),
                      style: text.labelSmall?.copyWith(
                        color: incomeColor,
                        fontFamily: 'RedditMono',
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyFormatter.compact(bucket.expense, currency),
                      style: text.labelSmall?.copyWith(
                        color: expenseColor,
                        fontFamily: 'RedditMono',
                        fontWeight: FontWeight.w700,
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

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: SizedBox(
      height: 6,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: color.withValues(alpha: 0.12)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: ColoredBox(color: color),
            ),
          ),
        ],
      ),
    ),
  );
}
