import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class UpcomingEventRow extends StatelessWidget {
  const UpcomingEventRow({
    super.key,
    required this.event,
    required this.currency,
  });

  final ForecastEvent event;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isShift = event.kind == ForecastEventKind.shift;

    final icon = switch (event.kind) {
      ForecastEventKind.shift => HugeIcons.strokeRoundedClock01,
      ForecastEventKind.bill => HugeIcons.strokeRoundedReceiptText,
      ForecastEventKind.subscription => HugeIcons.strokeRoundedRepeat,
      _ => HugeIcons.strokeRoundedCoins01,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          IconTile(icon, size: 36),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.label, style: text.titleSmall),
                Text(
                  isShift
                      ? (event.rateFormatted ?? 'Scheduled shift')
                      : AppDate.weekdayDay(event.date),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isShift)
            Text(
              AppDate.weekdayDay(event.date),
              style: text.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            )
          else
            MoneyText(
              event.deltaMinor,
              currency,
              signed: true,
              style: text.titleSmall,
            ),
        ],
      ),
    );
  }
}
