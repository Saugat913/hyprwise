import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';

enum HeroOutlookRange { d7, d30, d90 }

/// Interactive scrubbable balance outlook chart with solid past and dashed forecast.
class BalanceOutlookChart extends StatefulWidget {
  const BalanceOutlookChart({
    super.key,
    required this.viewModel,
    required this.range,
    required this.onRangeChanged,
    required this.scrubNotifier,
  });

  final HomeViewModel viewModel;
  final HeroOutlookRange range;
  final ValueChanged<HeroOutlookRange> onRangeChanged;
  final ValueNotifier<int?> scrubNotifier;

  @override
  State<BalanceOutlookChart> createState() => _BalanceOutlookChartState();
}

class _BalanceOutlookChartState extends State<BalanceOutlookChart> {
  int get pastDays {
    switch (widget.range) {
      case HeroOutlookRange.d7:
        return 7;
      case HeroOutlookRange.d30:
        return 30;
      case HeroOutlookRange.d90:
        return 90;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    final pastSeries = widget.viewModel.balanceSeries(pastDays);
    final forecastSeries = widget.viewModel.forecastSeries(days: 14);

    final allPoints = <BalancePoint>[
      ...pastSeries,
      if (forecastSeries.isNotEmpty) ...forecastSeries.skip(1),
    ];
    final splitIndex = pastSeries.isNotEmpty ? pastSeries.length - 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Readout row + Range chips
        ValueListenableBuilder<int?>(
          valueListenable: widget.scrubNotifier,
          builder: (context, scrubIndex, _) {
            final Widget readoutWidget;
            if (scrubIndex != null && scrubIndex >= 0 && scrubIndex < allPoints.length) {
              final pt = allPoints[scrubIndex];
              final isToday = scrubIndex == splitIndex;
              final isForecast = scrubIndex > splitIndex;
              final tag = isToday
                  ? tr.today
                  : (isForecast ? tr.forecastLabel : '');
              final formattedDate = AppDate.short(pt.date);
              final formattedVal = MoneyFormatter.format(pt.minor, widget.viewModel.baseCurrency);

              readoutWidget = Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$formattedDate ',
                      style: text.bodySmall?.copyWith(
                        color: colors.onHeroSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (tag.isNotEmpty) ...[
                      TextSpan(
                        text: '$tag ',
                        style: text.bodySmall?.copyWith(
                          color: isForecast ? colors.brand : colors.liquid,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    TextSpan(
                      text: formattedVal,
                      style: text.labelSmall?.copyWith(
                        color: colors.onHero,
                        fontFamily: 'RedditMono',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            } else {
              // Idle: "+{delta} in {n} days · range {min}–{max}"
              final int delta;
              final String deltaText;
              final Color deltaColor;
              if (forecastSeries.isNotEmpty) {
                delta = forecastSeries.last.minor - pastSeries.last.minor;
                final isPositive = delta > 0;
                final sign = isPositive ? '+' : '';
                deltaText = '$sign${MoneyFormatter.compact(delta, widget.viewModel.baseCurrency)} ${tr.inDays(14)}';
                deltaColor = isPositive ? colors.income : (delta < 0 ? colors.expense : colors.onHeroSecondary);
              } else {
                delta = pastSeries.last.minor - pastSeries.first.minor;
                final isPositive = delta > 0;
                final sign = isPositive ? '+' : '';
                deltaText = '$sign${MoneyFormatter.compact(delta, widget.viewModel.baseCurrency)} (${tr.rangeLabel} ${pastDays}d)';
                deltaColor = isPositive ? colors.income : (delta < 0 ? colors.expense : colors.onHeroSecondary);
              }

              final allMinors = allPoints.map((p) => p.minor).toList();
              final minVal = allMinors.isNotEmpty ? allMinors.reduce(math.min) : 0;
              final maxVal = allMinors.isNotEmpty ? allMinors.reduce(math.max) : 0;
              final rangeStr =
                  '${MoneyFormatter.compact(minVal, widget.viewModel.baseCurrency)}–${MoneyFormatter.compact(maxVal, widget.viewModel.baseCurrency)}';

              readoutWidget = Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$deltaText · ',
                      style: text.labelSmall?.copyWith(
                        color: deltaColor,
                        fontFamily: 'RedditMono',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    TextSpan(
                      text: rangeStr,
                      style: text.bodySmall?.copyWith(
                        color: colors.onHeroSecondary,
                        fontFamily: 'RedditMono',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: readoutWidget),
                const SizedBox(width: AppSpace.sm),
                // Range Chips
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RangeChip(
                      label: '7D',
                      isSelected: widget.range == HeroOutlookRange.d7,
                      onTap: () => widget.onRangeChanged(HeroOutlookRange.d7),
                    ),
                    const SizedBox(width: 4),
                    _RangeChip(
                      label: '30D',
                      isSelected: widget.range == HeroOutlookRange.d30,
                      onTap: () => widget.onRangeChanged(HeroOutlookRange.d30),
                    ),
                    const SizedBox(width: 4),
                    _RangeChip(
                      label: '90D',
                      isSelected: widget.range == HeroOutlookRange.d90,
                      onTap: () => widget.onRangeChanged(HeroOutlookRange.d90),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.sm),

        // Chart Area
        SizedBox(
          height: 140,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (allPoints.length < 2) {
                return _buildEmptyChart(context, tr);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) => _handleScrub(details.localPosition.dx, constraints.maxWidth, allPoints.length),
                onHorizontalDragUpdate: (details) => _handleScrub(details.localPosition.dx, constraints.maxWidth, allPoints.length),
                onHorizontalDragEnd: (_) => _resetScrub(),
                onHorizontalDragCancel: () => _resetScrub(),
                onTapDown: (details) => _handleScrub(details.localPosition.dx, constraints.maxWidth, allPoints.length),
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 140),
                    painter: _BalanceChartPainter(
                      points: allPoints,
                      splitIndex: splitIndex,
                      cursorNotifier: widget.scrubNotifier,
                      colors: colors,
                      baseCurrency: widget.viewModel.baseCurrency,
                      isRtl: Directionality.of(context) == TextDirection.rtl,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleScrub(double dx, double width, int pointCount) {
    if (pointCount < 2) return;
    const rightGutter = 38.0;
    final chartWidth = width - rightGutter;
    if (chartWidth <= 0) return;

    final clampedX = dx.clamp(0.0, chartWidth);
    final ratio = clampedX / chartWidth;
    final index = (ratio * (pointCount - 1)).round().clamp(0, pointCount - 1);

    if (widget.scrubNotifier.value != index) {
      HapticFeedback.selectionClick();
      widget.scrubNotifier.value = index;
    }
  }

  void _resetScrub() {
    widget.scrubNotifier.value = null;
  }

  Widget _buildEmptyChart(BuildContext context, AppStrings tr) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1.0,
            width: double.infinity,
            color: colors.hairline,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            tr.addTransactionsToSeeOutlook,
            style: text.bodySmall?.copyWith(
              color: colors.onHeroSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 26, minWidth: 32),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? colors.onHero.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: text.labelSmall?.copyWith(
              color: isSelected ? colors.onHero : colors.onHeroSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
              fontFamily: 'RedditMono',
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceChartPainter extends CustomPainter {
  _BalanceChartPainter({
    required this.points,
    required this.splitIndex,
    required this.cursorNotifier,
    required this.colors,
    required this.baseCurrency,
    required this.isRtl,
  }) : super(repaint: cursorNotifier);

  final List<BalancePoint> points;
  final int splitIndex;
  final ValueNotifier<int?> cursorNotifier;
  final AppColors colors;
  final String baseCurrency;
  final bool isRtl;

  static const double rightGutter = 38.0;
  static const double topPadding = 12.0;
  static const double bottomPadding = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final chartWidth = size.width - rightGutter;
    final chartHeight = size.height - topPadding - bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final minors = points.map((p) => p.minor).toList();
    var minVal = minors.reduce(math.min);
    var maxVal = minors.reduce(math.max);
    if (minVal == maxVal) {
      minVal -= 1000;
      maxVal += 1000;
    }
    final range = maxVal - minVal;

    double getY(int val) {
      final normalized = (val - minVal) / range;
      return topPadding + (1.0 - normalized) * chartHeight;
    }

    double getX(int idx) {
      return (idx / (points.length - 1)) * chartWidth;
    }

    // 1. Gridlines and Y labels
    final gridPaint = Paint()
      ..color = colors.hairline
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: colors.textMuted,
      fontSize: 10,
      fontFamily: 'RedditMono',
      fontWeight: FontWeight.w500,
    );

    const steps = 3;
    for (var i = 0; i <= steps; i++) {
      final tickVal = minVal + (range * (i / steps)).round();
      final y = getY(tickVal);

      // Dashed horizontal grid line
      _drawDashedLine(
        canvas: canvas,
        p1: Offset(0, y),
        p2: Offset(chartWidth, y),
        paint: gridPaint,
        dashWidth: 4,
        dashSpace: 4,
      );

      // Y-axis label on right gutter
      final label = MoneyFormatter.compact(tickVal, baseCurrency);
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartWidth + 6, y - tp.height / 2));
    }

    // 2. Today vertical separator line
    final todayX = getX(splitIndex);
    final todayLinePaint = Paint()
      ..color = colors.hairline
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(todayX, topPadding),
      Offset(todayX, topPadding + chartHeight),
      todayLinePaint,
    );

    // 3. Past Solid Area Fill & Line
    final pastPath = Path();
    final fillPath = Path();

    for (var i = 0; i <= splitIndex; i++) {
      final x = getX(i);
      final y = getY(points[i].minor);
      if (i == 0) {
        pastPath.moveTo(x, y);
        fillPath.moveTo(x, topPadding + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        pastPath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(todayX, topPadding + chartHeight);
    fillPath.close();

    // Fill under past line (flat liquid @14%)
    final fillPaint = Paint()
      ..color = colors.liquid.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke past solid line (2px, round joins)
    final pastLinePaint = Paint()
      ..color = colors.liquid
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(pastPath, pastLinePaint);

    // 4. Forecast Dashed Line (4/4 @75% opacity)
    if (splitIndex < points.length - 1) {
      final forecastPaint = Paint()
        ..color = colors.liquid.withValues(alpha: 0.75)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (var i = splitIndex; i < points.length - 1; i++) {
        final p1 = Offset(getX(i), getY(points[i].minor));
        final p2 = Offset(getX(i + 1), getY(points[i + 1].minor));
        _drawDashedLine(
          canvas: canvas,
          p1: p1,
          p2: p2,
          paint: forecastPaint,
          dashWidth: 4,
          dashSpace: 4,
        );
      }
    }

    // 5. Active Cursor / Scrub crosshair & dot
    final cursorIdx = cursorNotifier.value ?? splitIndex;
    if (cursorIdx >= 0 && cursorIdx < points.length) {
      final cx = getX(cursorIdx);
      final cy = getY(points[cursorIdx].minor);

      // Vertical crosshair line
      final crosshairPaint = Paint()
        ..color = colors.onHero.withValues(alpha: 0.25)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(cx, topPadding),
        Offset(cx, topPadding + chartHeight),
        crosshairPaint,
      );

      // Dot with ground-colored ring (2px ring in card hero color, 4px inner dot)
      final ringPaint = Paint()
        ..color = colors.hero
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 5.5, ringPaint);

      final dotPaint = Paint()
        ..color = cursorIdx > splitIndex ? colors.brand : colors.liquid
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 3.5, dotPaint);
    }

    // 6. X-axis Labels: start date, Today, end date
    final dateStyle = TextStyle(
      color: colors.onHeroSecondary,
      fontSize: 10,
      fontFamily: 'RedditMono',
    );

    // Start date
    final startTp = TextPainter(
      text: TextSpan(text: AppDate.short(points.first.date), style: dateStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    startTp.paint(canvas, Offset(0, size.height - bottomPadding + 6));

    // Today label
    final todayTp = TextPainter(
      text: TextSpan(text: 'Today', style: dateStyle.copyWith(fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    todayTp.paint(canvas, Offset(todayX - todayTp.width / 2, size.height - bottomPadding + 6));

    // End date
    final endTp = TextPainter(
      text: TextSpan(text: AppDate.short(points.last.date), style: dateStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    endTp.paint(canvas, Offset(chartWidth - endTp.width, size.height - bottomPadding + 6));
  }

  void _drawDashedLine({
    required Canvas canvas,
    required Offset p1,
    required Offset p2,
    required Paint paint,
    required double dashWidth,
    required double dashSpace,
  }) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;
    var current = 0.0;

    while (current < distance) {
      final start = current;
      final end = math.min(current + dashWidth, distance);
      canvas.drawLine(
        Offset(p1.dx + unitX * start, p1.dy + unitY * start),
        Offset(p1.dx + unitX * end, p1.dy + unitY * end),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.splitIndex != splitIndex ||
        oldDelegate.cursorNotifier != cursorNotifier ||
        oldDelegate.colors != colors;
  }
}
