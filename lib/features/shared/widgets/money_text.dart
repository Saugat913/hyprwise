import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/utils/money.dart';

/// Money with a muted cents part: A$2,480.50 (the ".50" is smaller).
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor,
    this.currency, {
    super.key,
    this.style,
    this.color,
    this.signed = false,
    this.showCents = true,
  });

  final int minor;
  final String currency;
  final TextStyle? style;
  final Color? color;
  final bool signed;
  final bool showCents;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (signed
            ? (minor > 0
                ? context.colors.income
                : (minor < 0 ? context.colors.expense : null))
            : null);
    final base = (style ?? Theme.of(context).textTheme.titleSmall)!.copyWith(color: effectiveColor);
    final full = MoneyFormatter.format(minor, currency, signed: signed);
    final dot = full.lastIndexOf('.');
    if (!showCents || dot < 0) return Text(full, style: base);
    return Text.rich(
      TextSpan(
        text: full.substring(0, dot),
        children: [
          TextSpan(
            text: full.substring(dot),
            style: TextStyle(fontSize: (base.fontSize ?? 14) * 0.55, color: base.color?.withValues(alpha: 0.65)),
          ),
        ],
      ),
      style: base,
    );
  }
}
