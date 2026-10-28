import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// "This week" ........ "See calendar >"
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.padding,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(0, AppSpace.xl, 0, AppSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: text.titleMedium)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(actionLabel!, style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(width: 2),
                  const AppIcon(HugeIcons.strokeRoundedArrowRight01, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
