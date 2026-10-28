import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';

/// Minimal line chart for the hero card and forecast.
class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, this.color, this.height = 56});

  final List<double> values;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SparkPainter(values, color ?? context.colors.heroAccent)),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final span = (values.reduce((a, b) => a > b ? a : b) - min).abs();
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = span == 0 ? size.height / 2 : size.height - (values[i] - min) / span * (size.height - 4) - 2;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}
