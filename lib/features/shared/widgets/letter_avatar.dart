import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Returns bundled brand logo asset path if available.
String? merchantAssetSvg(String name) {
  final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (clean.contains('domino')) return 'assets/icons/merchants/dominos.svg';
  if (clean.contains('kfc')) return 'assets/icons/merchants/kfc.svg';
  if (clean.contains('mcdonald')) return 'assets/icons/merchants/mcdonalds.svg';
  if (clean.contains('ubereat')) return 'assets/icons/merchants/ubereats.svg';
  if (clean == 'uber') return 'assets/icons/merchants/uber.svg';
  if (clean.contains('netflix')) return 'assets/icons/merchants/netflix.svg';
  if (clean.contains('spotify')) return 'assets/icons/merchants/spotify.svg';
  if (clean.contains('primevideo') || clean.contains('prime')) {
    return 'assets/icons/merchants/primevideo.svg';
  }
  if (clean.contains('qfx')) return 'assets/icons/merchants/qfx.svg';
  if (clean.contains('woolworth')) return 'assets/icons/merchants/woolworths.svg';
  if (clean.contains('cole')) return 'assets/icons/merchants/coles.svg';
  if (clean.contains('aldi')) return 'assets/icons/merchants/aldi.svg';
  if (clean.contains('opal')) return 'assets/icons/merchants/opal.svg';
  if (clean.contains('shell')) return 'assets/icons/merchants/shell.svg';
  return null;
}

/// Returns dedicated icon for bill categories if applicable.
IconGlyph? merchantBillIcon(String name) {
  final clean = name.toLowerCase().trim();
  if (clean.contains('rent')) return HugeIcons.strokeRoundedHouse01;
  if (clean.contains('electr')) return HugeIcons.strokeRoundedFlash;
  if (clean.contains('internet') || clean.contains('wifi')) {
    return HugeIcons.strokeRoundedWifi01;
  }
  if (clean.contains('phone') || clean.contains('mobile')) {
    return HugeIcons.strokeRoundedCall02;
  }
  return null;
}

/// Rounded tile with merchant logo (or fallback first letter: W, D, N...).
class LetterAvatar extends StatelessWidget {
  const LetterAvatar(
    this.name, {
    super.key,
    this.size = AppSize.iconBox,
    this.isCircle = false,
  });

  final String name;
  final double size;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final svg = merchantAssetSvg(name);
    final billIcon = merchantBillIcon(name);

    Widget inner;
    if (svg != null) {
      inner = Padding(
        padding: EdgeInsets.all(size * 0.2),
        child: SvgPicture.asset(
          svg,
          width: size * 0.6,
          height: size * 0.6,
          fit: BoxFit.contain,
        ),
      );
    } else if (billIcon != null) {
      inner = AppIcon(billIcon, size: size * 0.5);
    } else {
      inner = Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F2),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(size * 0.3),
      ),
      child: inner,
    );
  }
}
