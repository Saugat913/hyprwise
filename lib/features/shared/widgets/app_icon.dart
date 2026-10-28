import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// HugeIcons glyph data (what `HugeIcons.strokeRounded*` returns).
typedef IconGlyph = List<List<dynamic>>;

/// The only way icons are drawn in the app. Defaults to the text colour.
class AppIcon extends StatelessWidget {
  const AppIcon(this.glyph, {super.key, this.size = 20, this.color});

  final IconGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => HugeIcon(
        icon: glyph,
        size: size,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );
}
