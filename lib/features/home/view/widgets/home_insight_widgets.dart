import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/assistant/view/widgets/chat_widgets.dart' show WeekBars;
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

/// Home dashboard insight cards: week chart, savings ring, top category, bills.
class HomeInsights extends StatelessWidget {
  const HomeInsights({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final cur = viewModel.baseCurrency;
    final weekIn = viewModel.weekIncome;
    final weekOut = viewModel.weekExpense;
    final top = viewModel.topCategory;
    final bills = viewModel.billsDueSoon;
    final billsTotal = bills.fold<int>(0, (s, e) => s + e.deltaMinor.abs());
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.xxl),
        SectionHeader(tr.thisWeekTitle),
        _Reveal(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(tr.incomeVsSpend, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    _Dot(colors.brand, tr.income),
                    const SizedBox(width: AppSpace.md),
                    _Dot(colors.expense.withValues(alpha: 0.75), tr.expense),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                SizedBox(height: 84, child: WeekBars(income: weekIn, expense: weekOut)),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '${MoneyFormatter.format(weekIn.fold(0, (a, b) => a + b), cur)}  ·  ${MoneyFormatter.format(weekOut.fold(0, (a, b) => a + b), cur)}',
                  style: muted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Reveal(
                  delay: 100,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr.savingsRateTitle, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpace.md),
                        Center(child: _Ring(value: viewModel.savingsRate, color: colors.brand, track: colors.fill)),
                        const SizedBox(height: AppSpace.sm),
                        Text(tr.ofIncomeKept, style: muted, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _Reveal(
                  delay: 200,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr.topSpendingTitle, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpace.md),
                        if (top == null)
                          Text(tr.noSpendingYet, style: muted)
                        else ...[
                          AppIcon(HugeIcons.strokeRoundedChartHistogram, size: 22, color: colors.brand),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            _pretty(top.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(MoneyFormatter.format(top.value, cur), style: text.bodyMedium?.copyWith(color: colors.expense)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _Reveal(
          delay: 300,
          child: AppCard(
            child: Row(
              children: [
                IconTile(HugeIcons.strokeRoundedInvoice01, size: 40),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.billsDueSoonTitle, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        bills.isEmpty ? tr.noBillsDueSoon : bills.map((e) => e.label).take(2).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ],
                  ),
                ),
                if (bills.isNotEmpty)
                  Text(
                    MoneyFormatter.format(billsTotal, cur),
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.expense),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _pretty(String key) {
    final s = key.replaceAll('_', ' ');
    return s.isEmpty ? key : s[0].toUpperCase() + s.substring(1);
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

/// Fade + rise on first build, optionally staggered by [delay] ms.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + delay),
        curve: Interval(delay / (450 + delay), 1, curve: Curves.easeOutCubic),
        builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c)),
        child: child,
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => SizedBox(
          width: 78,
          height: 78,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: track,
                ),
              ),
              Text('${(v * 100).round()}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}
