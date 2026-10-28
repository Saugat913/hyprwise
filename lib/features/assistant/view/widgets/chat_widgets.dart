import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/shared/data/snapshot_stats.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

/// Fades and slides its child in once, with an optional stagger [delay].
class ChatEntrance extends StatelessWidget {
  const ChatEntrance({
    super.key,
    required this.child,
    this.fromRight = false,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool fromRight;
  final Duration delay;

  @override
  Widget build(BuildContext context) => _Delayed(
    delay: delay,
    builder:
        (go) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: go ? 1 : 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder:
              (_, v, c) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(
                    (fromRight ? 16 : -16) * (1 - v),
                    12 * (1 - v),
                  ),
                  child: c,
                ),
              ),
          child: child,
        ),
  );
}

class _Delayed extends StatefulWidget {
  const _Delayed({required this.delay, required this.builder});

  final Duration delay;
  final Widget Function(bool go) builder;

  @override
  State<_Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<_Delayed> {
  late bool _go = widget.delay == Duration.zero;

  @override
  void initState() {
    super.initState();
    if (!_go) {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _go = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_go);
}

/// Three bouncing dots inside an assistant-style bubble.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder:
              (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 7,
                      height: 7,
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                      transform: Matrix4.translationValues(
                        0,
                        -4 *
                            math.max(
                              0,
                              math.sin((_c.value - i * 0.15) * 2 * math.pi),
                            ),
                        0,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }
}

/// Wrap of tappable chips that pop in one after another.
class AnimatedSuggestionChips extends StatelessWidget {
  const AnimatedSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (var i = 0; i < suggestions.length; i++)
          _Delayed(
            delay: Duration(milliseconds: 120 * i),
            builder:
                (go) => AnimatedScale(
                  scale: go ? 1 : 0.8,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: go ? 1 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: ActionChip(
                      label: Text(suggestions[i]),
                      onPressed: () => onTap(suggestions[i]),
                      side: BorderSide(
                        color: context.colors.brand.withValues(alpha: 0.5),
                      ),
                      backgroundColor: context.colors.brandBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
          ),
      ],
    ),
  );
}

enum ChatChartKind { spendingPie, incomeBars }

/// Picks an inline chart for a user question, or null when none fits.
ChatChartKind? chartKindForQuery(String query) {
  final q = query.toLowerCase();
  if (RegExp(
    r'\b(earn|earned|earning|earnings|income|paid me|salary)\b',
  ).hasMatch(q)) {
    return ChatChartKind.incomeBars;
  }
  if (RegExp(
    r'\b(spend|spent|spending|expense|expenses|overspend|overspending|budget)\b',
  ).hasMatch(q)) {
    return ChatChartKind.spendingPie;
  }
  return null;
}

/// Small animated chart card shown under spending / income answers.
class ChatChartCard extends StatelessWidget {
  const ChatChartCard({
    super.key,
    required this.kind,
    required this.snapshot,
    required this.currency,
  });

  final ChatChartKind kind;
  final FinanceSnapshot snapshot;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final Widget body;
    final String title;

    if (kind == ChatChartKind.spendingPie) {
      final cats = snapshot.topSpendCategories;
      if (cats.isEmpty) return const SizedBox.shrink();
      title = tr.spendingBreakdown;
      final shown = cats.take(4).toList();
      final other = cats.skip(4).fold<int>(0, (s, e) => s + e.value);
      final slices = [
        ...shown,
        if (other > 0) MapEntry(tr.otherCategory, other),
      ];
      final total = slices.fold<int>(0, (s, e) => s + e.value);
      final palette = [
        colors.brand,
        colors.expense,
        colors.warning,
        colors.income,
        colors.fill,
      ];
      body = Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder:
                  (_, v, _) => CustomPaint(
                    painter: _PiePainter(
                      [for (final s in slices) s.value.toDouble()],
                      palette,
                      v,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < slices.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _label(slices[i].key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall,
                          ),
                        ),
                        Text(
                          '${tr.formatNumber((slices[i].value * 100 / total).round())}%',
                          style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      final income = snapshot.dailyTotals(TransactionType.income);
      final expense = snapshot.dailyTotals(TransactionType.expense);
      if (income.every((e) => e == 0) && expense.every((e) => e == 0)) {
        return const SizedBox.shrink();
      }
      title = '${tr.incomeVsSpend} · ${tr.last7Days}';
      body = SizedBox(
        height: 90,
        child: WeekBars(income: income, expense: expense),
      );
    }

    return ChatEntrance(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md, right: 32),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    HugeIcons.strokeRoundedChartHistogram,
                    size: 16,
                    color: colors.brand,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              body,
              if (kind == ChatChartKind.incomeBars) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  '${tr.income}: ${MoneyFormatter.format(snapshot.dailyTotals(TransactionType.income).fold(0, (a, b) => a + b), currency)}'
                  '  ·  ${tr.expense}: ${MoneyFormatter.format(snapshot.dailyTotals(TransactionType.expense).fold(0, (a, b) => a + b), currency)}',
                  style: text.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String key) {
    final tr = AppStrings.current();
    return tr.categoryLabel(key, key.replaceAll('_', ' '));
  }
}

/// Animated paired income/expense bars, one pair per day.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.income, required this.expense});

  final List<int> income;
  final List<int> expense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder:
          (_, v, _) => CustomPaint(
            size: Size.infinite,
            painter: _BarsPainter(
              income,
              expense,
              colors.brand,
              colors.expense.withValues(alpha: 0.75),
              v,
            ),
          ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.a, this.b, this.ca, this.cb, this.t);

  final List<int> a;
  final List<int> b;
  final Color ca;
  final Color cb;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = [...a, ...b].fold<int>(1, math.max).toDouble();
    final n = a.length;
    final slot = size.width / n;
    final barW = math.min(10.0, slot / 3);
    void bar(double x, int v, Color c) {
      final h = math.max(v == 0 ? 0.0 : 3.0, v / maxV * (size.height - 2)) * t;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barW, h),
          const Radius.circular(3),
        ),
        Paint()..color = c,
      );
    }

    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      bar(cx - barW - 1, a[i], ca);
      bar(cx + 1, b[i], cb);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter o) => o.t != t || o.a != a || o.b != b;
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.values, this.colors, this.t);

  final List<double> values;
  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Rect.fromLTWH(7, 7, size.width - 14, size.height - 14);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi * t;
      canvas.drawArc(
        rect,
        start,
        math.max(0, sweep - 0.04),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = colors[i % colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter o) => o.t != t || o.values != values;
}
