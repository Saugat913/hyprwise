import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';

enum ChipTone { neutral, warning, success, danger }

/// "Due Fri", "Done", "Needs your OK".
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = ChipTone.neutral});

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = switch (tone) {
      ChipTone.warning => (colors.warningBg, colors.warning),
      ChipTone.success => (colors.incomeBg, colors.income),
      ChipTone.danger => (colors.expense.withValues(alpha: 0.12), colors.expense),
      ChipTone.neutral => (colors.fill, Theme.of(context).colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}
