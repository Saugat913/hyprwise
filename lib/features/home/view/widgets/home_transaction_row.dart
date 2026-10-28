import 'package:flutter/material.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class HomeTransactionRow extends StatelessWidget {
  const HomeTransactionRow({
    super.key,
    required this.transaction,
    required this.currency,
  });

  final Transaction transaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isIncome = transaction.type == TransactionType.income.value;
    final name = (transaction.note?.isNotEmpty ?? false)
        ? transaction.note!
        : transaction.category;
    final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          LetterAvatar(name),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleSmall),
                Text(
                  '${transaction.category} · ${AppDate.short(date)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          MoneyText(
            isIncome ? transaction.amountMinor : -transaction.amountMinor,
            currency,
            signed: true,
            style: text.titleSmall,
          ),
        ],
      ),
    );
  }
}
