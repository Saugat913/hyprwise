import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// Thin progress line (goals, checklist, month spend).
class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key, this.height = 4, this.color});

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          minHeight: height,
          backgroundColor: context.colors.fill,
          valueColor: AlwaysStoppedAnimation(color ?? Theme.of(context).colorScheme.onSurface),
        ),
      );
}
