import 'package:flutter/material.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';

/// Top header of the redesigned Home Hero section.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.viewModel,
    required this.focusedAccount,
  });

  final HomeViewModel viewModel;
  final HeroAccountSlice? focusedAccount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;

    // Series title: Focused account's name or global "Net position"
    final seriesLabel = focusedAccount?.name ?? tr.netPosition;

    // Value to show: account balance in its currency or overall net position
    final String mainValueFormatted;
    final Color mainValueColor;
    if (focusedAccount != null) {
      mainValueFormatted = MoneyFormatter.format(
        focusedAccount!.balanceMinor,
        focusedAccount!.currency,
      );
      mainValueColor = focusedAccount!.balanceMinor < 0
          ? colors.expense
          : colors.onHero;
    } else {
      mainValueFormatted = MoneyFormatter.format(
        viewModel.netPositionMinor,
        viewModel.baseCurrency,
      );
      mainValueColor = viewModel.netPositionMinor < 0
          ? colors.expense
          : colors.onHero;
    }

    // Subtitle computation
    final Widget subtitleWidget;
    if (focusedAccount != null) {
      final totalNet = viewModel.netPositionMinor;
      final sharePct = totalNet > 0
          ? ((focusedAccount!.balanceInBaseMinor / totalNet) * 100).round()
          : 0;
      final typeLabel = focusedAccount!.isSpendable
          ? tr.spendable
          : tr.reserved;
      subtitleWidget = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: tr.percentOfNet(tr.formatNumber(sharePct)),
              style: text.bodySmall?.copyWith(
                color: colors.onHeroSecondary,
                fontSize: 12,
                fontFamily: 'RedditMono',
              ),
            ),
            TextSpan(
              text: ' · $typeLabel',
              style: text.bodySmall?.copyWith(
                color: colors.onHeroSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      // Idle: "+{monthNet} this month" (income colour mono + grey text; expense if negative)
      final monthNet = viewModel.monthIncome - viewModel.monthExpense;
      final isPositive = monthNet > 0;
      final isNegative = monthNet < 0;
      final netColor = isPositive
          ? colors.income
          : (isNegative ? colors.expense : colors.onHeroSecondary);
      final netPrefix = isPositive ? '+' : '';
      final formattedNet = '$netPrefix${MoneyFormatter.format(monthNet, viewModel.baseCurrency)}';

      subtitleWidget = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: formattedNet,
              style: text.bodySmall?.copyWith(
                color: netColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'RedditMono',
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: ' ${tr.thisMonth}',
              style: text.bodySmall?.copyWith(
                color: colors.onHeroSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label & Liquid Pill Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  seriesLabel,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onHeroSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (focusedAccount == null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: colors.onHeroSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
            if (viewModel.usableRatio > 0 && focusedAccount == null) ...[
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.liquid.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: colors.liquid.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.liquid,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tr.formatNumber((viewModel.usableRatio * 100).round())}% liquid',
                      style: text.labelSmall?.copyWith(
                        color: colors.liquid,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RedditMono',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.xs + 2),

        // Big Main Value + Sparkline Wave
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      mainValueFormatted,
                      style: text.displaySmall?.copyWith(
                        color: mainValueColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'RedditMono',
                        fontSize: 34,
                        letterSpacing: -0.02 * 34,
                        height: 1.1,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 18),
                    child: subtitleWidget,
                  ),
                ],
              ),
            ),
            if (focusedAccount == null) ...[
              const SizedBox(width: AppSpace.sm),
              RepaintBoundary(
                child: CustomPaint(
                  size: const Size(78, 38),
                  painter: _HeaderWavePainter(
                    points: viewModel.balanceSeries(14),
                    color: colors.liquid,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderWavePainter extends CustomPainter {
  const _HeaderWavePainter({
    required this.points,
    required this.color,
  });

  final List<BalancePoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5),
        linePaint,
      );
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(size.width, size.height * 0.5), 3.0, dotPaint);
      return;
    }

    final minors = points.map((p) => p.minor).toList();
    var minVal = minors.first;
    var maxVal = minors.first;
    for (final v in minors) {
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }
    final range = (maxVal - minVal).abs();
    final span = range == 0 ? 1.0 : range.toDouble();

    final stepX = size.width / (points.length - 1);
    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i].minor - minVal) / span;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      offsets.add(Offset(x, y));
    }

    // Smooth Bezier Curve Path
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // End glowing dot
    final endOffset = offsets.last;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endOffset, 6.0, glowPaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endOffset, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(_HeaderWavePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
