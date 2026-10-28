import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CalendarItemRow extends StatelessWidget {
  const CalendarItemRow({super.key, required this.item});

  final CalendarItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final icon = switch (item.type) {
      CalendarItemType.shift => HugeIcons.strokeRoundedClock01,
      CalendarItemType.bill => HugeIcons.strokeRoundedReceiptText,
      CalendarItemType.goal => HugeIcons.strokeRoundedTarget02,
      CalendarItemType.income => HugeIcons.strokeRoundedArrowDownLeft01,
      CalendarItemType.expense => HugeIcons.strokeRoundedArrowUpRight01,
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
                Text(item.title, style: text.titleSmall),
                Text(item.subtitle, style: text.bodySmall),
              ],
            ),
          ),
          if (item.type == CalendarItemType.shift && item.status != 'completed')
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.endDate != null
                      ? '${AppDate.timeOnly(item.date)}–${AppDate.timeOnly(item.endDate!)}'
                      : AppDate.timeOnly(item.date),
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '≈ ${MoneyFormatter.format(item.amountMinor, item.currencyCode)}',
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            MoneyText(
              item.isIncome ? item.amountMinor : -item.amountMinor,
              item.currencyCode,
              signed: true,
              style: text.titleSmall,
            ),
        ],
      ),
    );
  }
}
