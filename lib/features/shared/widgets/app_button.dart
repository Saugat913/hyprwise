import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

enum AppButtonKind { primary, secondary, success, danger, outline, text }

/// Full-width pill-ish button used for every primary action.
class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final IconGlyph? icon;

  /// Shrinks to content (used in empty states and inline confirm cards).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final size = compact ? const Size(0, 44) : const Size.fromHeight(AppSize.button);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: AppSpace.xl)
        : EdgeInsets.symmetric(horizontal: icon != null ? AppSpace.md : AppSpace.xl);

    Widget child(Color fg) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[AppIcon(icon!, size: 18, color: fg), const SizedBox(width: AppSpace.sm)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        );

    return switch (kind) {
      AppButtonKind.secondary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: size,
            padding: padding,
            elevation: 0,
            backgroundColor: colors.fill,
            foregroundColor: scheme.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: child(scheme.onSurface),
        ),
      AppButtonKind.outline => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            padding: padding,
            backgroundColor: colors.fill.withValues(alpha: 0.5),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: child(scheme.onSurface),
        ),
      AppButtonKind.text => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(minimumSize: size, padding: padding),
          child: child(scheme.onSurfaceVariant),
        ),
      _ => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: size,
            padding: padding,
            backgroundColor: switch (kind) {
              AppButtonKind.success => colors.income,
              AppButtonKind.danger => colors.expense,
              _ => scheme.primary,
            },
            foregroundColor: kind == AppButtonKind.primary ? scheme.onPrimary : Colors.white,
          ),
          child: child(kind == AppButtonKind.primary ? scheme.onPrimary : Colors.white),
        ),
    };
  }
}

/// Round 40px icon button (back, bell, filter, add).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton(this.glyph, {super.key, required this.onPressed, this.filled = false});

  final IconGlyph glyph;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: filled ? scheme.primary : scheme.surface,
      shape: CircleBorder(side: BorderSide(color: filled ? scheme.primary : scheme.outlineVariant)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: AppSize.iconBox,
          height: AppSize.iconBox,
          child: Center(child: AppIcon(glyph, size: 18, color: filled ? scheme.onPrimary : null)),
        ),
      ),
    );
  }
}
