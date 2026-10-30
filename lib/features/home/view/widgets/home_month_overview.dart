import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/app_card.dart';
import 'package:finance_tracker/features/shared/widgets/row_divider.dart';
import 'package:finance_tracker/features/shared/widgets/section_header.dart';

/// A single, scannable cash-flow comparison with a full filled pie chart.
class HomeMonthOverview extends StatelessWidget {
  const HomeMonthOverview({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final tr = context.strings;
    final income = viewModel.monthIncome;
    final expense = viewModel.monthExpense;
    final totalFlow = income + expense;
    final net = income - expense;
    final netColor =
        net < 0
            ? colors.expense
            : (net > 0 ? colors.income : scheme.onSurfaceVariant);

    final incomeShare = totalFlow > 0 ? (income / totalFlow).clamp(0.0, 1.0) : 0.0;
    final expenseShare = totalFlow > 0 ? (expense / totalFlow).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title is strictly outside the white container with no logo
        SectionHeader(
          tr.thisMonthSoFar,
          padding: const EdgeInsets.fromLTRB(0, AppSpace.xl, 0, AppSpace.sm),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Full filled circular pie chart
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: CustomPaint(
                      painter: _CashflowPiePainter(
                        incomeRatio: incomeShare,
                        expenseRatio: expenseShare,
                        incomeColor: colors.income,
                        expenseColor: colors.expense,
                        emptyColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        dividerColor: scheme.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  // Income and Expense Breakdown Columns with generous divider padding
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _CashflowAmount(
                            label: tr.income,
                            amount: income,
                            percentage: totalFlow > 0 ? '${(incomeShare * 100).round()}%' : null,
                            color: colors.income,
                            currency: viewModel.baseCurrency,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                          child: Container(
                            width: 1,
                            height: 42,
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        Expanded(
                          child: _CashflowAmount(
                            label: tr.expense,
                            amount: expense,
                            percentage: totalFlow > 0 ? '${(expenseShare * 100).round()}%' : null,
                            color: colors.expense,
                            currency: viewModel.baseCurrency,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              const RowDivider(),
              const SizedBox(height: AppSpace.sm),
              // Single net cash flow summary readout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.net,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${net > 0 ? '+' : ''}${MoneyFormatter.format(net, viewModel.baseCurrency)}',
                    style: text.labelMedium?.copyWith(
                      color: netColor,
                      fontFamily: 'RedditMono',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CashflowAmount extends StatelessWidget {
  const _CashflowAmount({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.currency,
  });

  final String label;
  final int amount;
  final String? percentage;
  final Color color;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (percentage != null) ...[
              const SizedBox(width: 4),
              Text(
                percentage!,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                  fontFamily: 'RedditMono',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            MoneyFormatter.format(amount, currency),
            style: text.labelLarge?.copyWith(
              color: color,
              fontFamily: 'RedditMono',
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CashflowPiePainter extends CustomPainter {
  const _CashflowPiePainter({
    required this.incomeRatio,
    required this.expenseRatio,
    required this.incomeColor,
    required this.expenseColor,
    required this.emptyColor,
    required this.dividerColor,
  });

  final double incomeRatio;
  final double expenseRatio;
  final Color incomeColor;
  final Color expenseColor;
  final Color emptyColor;
  final Color dividerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Empty state (no income and no expense)
    if (incomeRatio <= 0 && expenseRatio <= 0) {
      canvas.drawCircle(center, radius, paint..color = emptyColor);
      return;
    }

    // Single source (100% income or 100% expense)
    if (incomeRatio > 0 && expenseRatio <= 0) {
      canvas.drawCircle(center, radius, paint..color = incomeColor);
      return;
    }
    if (expenseRatio > 0 && incomeRatio <= 0) {
      canvas.drawCircle(center, radius, paint..color = expenseColor);
      return;
    }

    // Both income and expense slices
    const startAngle = -math.pi / 2;
    final incomeSweep = 2 * math.pi * incomeRatio;
    final expenseSweep = 2 * math.pi * expenseRatio;

    // Draw income filled sector
    canvas.drawArc(
      rect,
      startAngle,
      incomeSweep,
      true,
      paint..color = incomeColor,
    );

    // Draw expense filled sector
    canvas.drawArc(
      rect,
      startAngle + incomeSweep,
      expenseSweep,
      true,
      paint..color = expenseColor,
    );

    // Draw subtle separation lines at slice boundaries
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = dividerColor
      ..isAntiAlias = true;

    final p1 = Offset(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );
    canvas.drawLine(center, p1, linePaint);

    final p2 = Offset(
      center.dx + radius * math.cos(startAngle + incomeSweep),
      center.dy + radius * math.sin(startAngle + incomeSweep),
    );
    canvas.drawLine(center, p2, linePaint);
  }

  @override
  bool shouldRepaint(_CashflowPiePainter oldDelegate) =>
      oldDelegate.incomeRatio != incomeRatio ||
      oldDelegate.expenseRatio != expenseRatio ||
      oldDelegate.incomeColor != incomeColor ||
      oldDelegate.expenseColor != expenseColor ||
      oldDelegate.dividerColor != dividerColor;
}
