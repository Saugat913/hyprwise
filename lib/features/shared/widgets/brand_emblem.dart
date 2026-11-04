import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Canonical flat Hyprwise vector mark used across login, setup, sync, and AI screens.
/// Pass [animation] to subtly pulse the mark during active background work.
class BrandEmblem extends StatelessWidget {
  const BrandEmblem({super.key, this.animation, this.size = 64});

  final Animation<double>? animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emblem = SvgPicture.asset(
      isDark
          ? 'assets/brandings/hyprwise_logo_white.svg'
          : 'assets/brandings/hyprwise_logo.svg',
      width: size,
      height: size,
    );
    final a = animation;
    return a == null ? emblem : ScaleTransition(scale: a, child: emblem);
  }
}
