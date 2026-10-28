import 'package:flutter/material.dart';

import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Soft square or circular tile holding an icon.
class IconTile extends StatelessWidget {
  const IconTile(
    this.glyph, {
    super.key,
    this.size = 40,
    this.round = false,
    this.color,
    this.background,
  });

  final IconGlyph glyph;
  final double size;
  final bool round;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? scheme.surfaceContainerHighest,
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(size * 0.3),
      ),
      child: AppIcon(glyph, size: size * 0.5, color: color),
    );
  }
}
