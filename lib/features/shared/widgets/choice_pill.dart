import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// Small pill used for category, weekday and suggestion choices.
class ChoicePill extends StatelessWidget {
  const ChoicePill(this.label, {super.key, required this.selected, required this.onTap, this.round = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Fixed circle (weekday chips) instead of a text pill.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = text.labelMedium?.copyWith(color: selected ? scheme.onPrimary : scheme.onSurface);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        width: round ? 44 : null,
        height: round ? 44 : null,
        padding: round ? null : const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm + 2),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          shape: round ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: round ? null : BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant),
        ),
        child: Text(label, style: style),
      ),
    );
  }
}
