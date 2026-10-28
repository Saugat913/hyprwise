import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// Pill tabs on a soft track: "All | Income | Expenses", "Week | Month | Year".
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({super.key, required this.options, required this.value, required this.onChanged});

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: context.colors.fill, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm + 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.key == value ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    entry.value,
                    style: text.labelMedium?.copyWith(
                      color: entry.key == value ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
