import 'dart:async';

import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

enum AppButtonKind { primary, secondary, success, danger, outline, text }

/// Full-width pill-ish button used for every primary action.
/// If [onPressed] returns a Future the button shows a spinner and ignores
/// further taps until it completes (or while [loading] is true).
class AppButton extends StatefulWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.compact = false,
    this.loading = false,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final AppButtonKind kind;
  final IconGlyph? icon;
  final bool loading;

  /// Shrinks to content (used in empty states and inline confirm cards).
  final bool compact;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _busy = false;
  bool _showSpinner = false;

  Future<void> _handle() async {
    final r = widget.onPressed!();
    if (r is Future) {
      setState(() => _busy = true);
      // Only show the spinner for work that is actually slow, so buttons that
      // merely open a sheet or push a route don't flash a loader.
      final timer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && _busy) setState(() => _showSpinner = true);
      });
      try {
        await r;
      } finally {
        timer.cancel();
        if (mounted) {
          setState(() {
            _busy = false;
            _showSpinner = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final label = widget.label;
    final icon = widget.icon;
    final kind = widget.kind;
    final compact = widget.compact;
    final working = _busy || widget.loading;
    final spinning = _showSpinner || widget.loading;
    final VoidCallback? onPressed =
        (widget.onPressed == null || working) ? null : _handle;
    final size = compact ? const Size(0, 44) : const Size.fromHeight(AppSize.button);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: AppSpace.xl)
        : EdgeInsets.symmetric(horizontal: icon != null ? AppSpace.md : AppSpace.xl);

    Widget child(Color fg) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: spinning
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[AppIcon(icon, size: 18, color: fg), const SizedBox(width: AppSpace.sm)],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
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
              borderRadius: BorderRadius.circular(AppRadius.md),
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
