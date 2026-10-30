import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';

/// One-piece stacked proportion bar representing accounts composition.
class AccountStackBar extends StatelessWidget {
  const AccountStackBar({
    super.key,
    required this.slices,
    required this.selectedAccountId,
    required this.onSelectAccount,
    required this.totalNetMinor,
  });

  final List<HeroAccountSlice> slices;
  final int? selectedAccountId;
  final ValueChanged<int?> onSelectAccount;
  final int totalNetMinor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.strings;

    // Filter out zero and negative balances from the stack bar, and render neutral track if net position <= 0
    if (totalNetMinor <= 0) {
      return Container(
        height: 6.0,
        constraints: const BoxConstraints(maxHeight: 6.0),
        decoration: BoxDecoration(
          color: colors.onHero.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      );
    }
    final validSlices = slices.where((s) => s.balanceInBaseMinor > 0).toList();
    if (validSlices.isEmpty) {
      return Container(
        height: 6.0,
        constraints: const BoxConstraints(maxHeight: 6.0),
        decoration: BoxDecoration(
          color: colors.onHero.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      );
    }

    // Assign color opacities: Spendable gets 100%, 60%, 35%, 35%... Savings gets reserved
    var spendableIndex = 0;
    final segmentColors = <int, Color>{};
    for (final s in validSlices) {
      if (s.isSpendable) {
        final double opacity;
        if (spendableIndex == 0) {
          opacity = 1.0;
        } else if (spendableIndex == 1) {
          opacity = 0.60;
        } else {
          opacity = 0.35;
        }
        segmentColors[s.id] = colors.liquid.withValues(alpha: opacity);
        spendableIndex++;
      } else {
        segmentColors[s.id] = colors.reserved;
      }
    }

    return Container(
      height: 6.0,
      constraints: const BoxConstraints(maxHeight: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Row(
          children: [
            for (var i = 0; i < validSlices.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _buildSegment(
                context: context,
                slice: validSlices[i],
                index: i,
                totalCount: validSlices.length,
                color: segmentColors[validSlices[i].id] ?? colors.liquid,
                tr: tr,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required HeroAccountSlice slice,
    required int index,
    required int totalCount,
    required Color color,
    required AppStrings tr,
  }) {
    final isSelected = selectedAccountId == slice.id;
    final hasSelection = selectedAccountId != null;
    final opacity = (!hasSelection || isSelected) ? 1.0 : 0.28;

    final sharePct = totalNetMinor > 0
        ? ((slice.balanceInBaseMinor / totalNetMinor) * 100).round()
        : 0;
    final formattedAmt = MoneyFormatter.format(slice.balanceMinor, slice.currency);
    final semanticLabel =
        '${slice.name}, $formattedAmt, $sharePct percent of net';

    return Expanded(
      flex: math.max(1, slice.balanceInBaseMinor),
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelectAccount(isSelected ? null : slice.id);
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: opacity,
            child: ColoredBox(
              color: slice.isSpendable
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF64748B),
              child: const SizedBox(
                height: 6.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
