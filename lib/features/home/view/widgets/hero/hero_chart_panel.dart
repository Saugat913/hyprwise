import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/home/view/widgets/hero/balance_outlook_chart.dart';
import 'package:finance_tracker/features/home/view/widgets/hero/month_bars_chart.dart';

enum HeroPanelType { outlook, month }

/// Switched panel housing Outlook (balance forecast chart) & This Month (weekly bars).
class HeroChartPanel extends StatelessWidget {
  const HeroChartPanel({
    super.key,
    required this.viewModel,
    required this.panel,
    required this.onPanelChanged,
    required this.range,
    required this.onRangeChanged,
    required this.scrubNotifier,
    required this.selectedWeek,
    required this.onSelectWeek,
  });

  final HomeViewModel viewModel;
  final HeroPanelType panel;
  final ValueChanged<HeroPanelType> onPanelChanged;
  final HeroOutlookRange range;
  final ValueChanged<HeroOutlookRange> onRangeChanged;
  final ValueNotifier<int?> scrubNotifier;
  final int selectedWeek;
  final ValueChanged<int> onSelectWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1px hairline divider (16 above, 16 below)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            height: 1.0,
            color: colors.hairline,
          ),
        ),

        // Segmented control: Outlook | This month
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.segmentedBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: tr.outlook,
                  isSelected: panel == HeroPanelType.outlook,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPanelChanged(HeroPanelType.outlook);
                  },
                ),
              ),
              Expanded(
                child: _SegmentButton(
                  label: tr.thisMonth,
                  isSelected: panel == HeroPanelType.month,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPanelChanged(HeroPanelType.month);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // Switched View with IndexedStack to keep scrub & week selection state alive
        IndexedStack(
          index: panel == HeroPanelType.outlook ? 0 : 1,
          children: [
            BalanceOutlookChart(
              viewModel: viewModel,
              range: range,
              onRangeChanged: onRangeChanged,
              scrubNotifier: scrubNotifier,
            ),
            MonthBarsChart(
              viewModel: viewModel,
              selectedWeek: selectedWeek,
              onSelectWeek: onSelectWeek,
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          decoration: BoxDecoration(
            color: isSelected ? colors.segmentedSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: text.labelSmall?.copyWith(
              color: isSelected ? colors.onHero : colors.onHeroSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
