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
    final colors = context.colors;

    return Material(
      color: colors.hero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: border is Border
            ? (border as Border).top
            : BorderSide(
                color: colors.hairline,
                width: 1.0,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.xl),
        child: child,
      ),
    );
  }
}
