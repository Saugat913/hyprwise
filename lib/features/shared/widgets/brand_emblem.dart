import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Hyprwise mark in a soft glowing circle. Single source of truth for the
/// logo treatment on setup/sync/loading screens. Pass [animation] to pulse it.
class BrandEmblem extends StatelessWidget {
  const BrandEmblem({super.key, this.animation, this.size = 84});

  final Animation<double>? animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emblem = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.08),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SvgPicture.asset(
        isDark
            ? 'assets/brandings/hyprwise_logo_white.svg'
            : 'assets/brandings/hyprwise_logo.svg',
      ),
    );
    final a = animation;
    return a == null ? emblem : ScaleTransition(scale: a, child: emblem);
  }
}
