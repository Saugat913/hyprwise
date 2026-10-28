import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// A chevron for navigation rows.
class Chevron extends StatelessWidget {
  const Chevron({super.key});

  @override
  Widget build(BuildContext context) => AppIcon(
        HugeIcons.strokeRoundedArrowRight01,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}
