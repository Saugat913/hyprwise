import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// One row of a setup / sync checklist: done tick, active spinner or pending dot.
class SetupStepTile extends StatelessWidget {
  const SetupStepTile({
    super.key,
    required this.title,
    required this.isDone,
    required this.isActive,
  });

  final String title;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isDone
                ? Icon(Icons.check_circle_rounded, key: const ValueKey('done'), size: 18, color: colors.income)
                : isActive
                    ? SizedBox(
                        key: const ValueKey('active'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: scheme.primary),
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: const ValueKey('pending'),
                        size: 18,
                        color: scheme.outlineVariant,
                      ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              title,
              style: text.bodySmall?.copyWith(
                color: isDone ? scheme.onSurface : (isActive ? scheme.primary : scheme.onSurfaceVariant),
                fontWeight: isDone || isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
