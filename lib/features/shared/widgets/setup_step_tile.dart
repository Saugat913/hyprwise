import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// One row of a setup / cloud backup sync checklist:
/// WCAG-compliant done check badge, active spinner, or pending indicator.
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
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isDone
                ? Container(
                    key: const ValueKey('done'),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.incomeBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      HugeIcons.strokeRoundedTick02,
                      size: 14,
                      color: colors.income,
                    ),
                  )
                : isActive
                    ? Container(
                        key: const ValueKey('active'),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.brandBg,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.brandText,
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('pending'),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.fill,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              title,
              style: text.bodySmall?.copyWith(
                color: isDone || isActive
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
                fontWeight: isDone || isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
