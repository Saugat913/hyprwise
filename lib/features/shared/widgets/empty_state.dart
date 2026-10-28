import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/shared/widgets/icon_tile.dart';

/// Centered icon, title, one line of help and a single CTA. Every empty
/// screen in the design follows this shape.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.outlineAction = false,
  });

  final IconGlyph icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool outlineAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxxl, vertical: AppSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(icon, size: 56, round: true),
            const SizedBox(height: AppSpace.lg),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.sm),
            Text(message, style: text.bodySmall, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.xl),
              AppButton(
                actionLabel!,
                onPressed: onAction,
                compact: true,
                kind: outlineAction ? AppButtonKind.outline : AppButtonKind.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
