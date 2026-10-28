import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// The hero card ("Net position", forecast, accounts total).
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.border,
  });

  final Widget child;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBorder = Border.all(
      color: isDark ? const Color(0xFF474D5E) : const Color(0xFF222B26),
      width: 1.2,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: context.colors.hero,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: border ?? defaultBorder,
      ),
      child: child,
    );
  }
}
