import 'package:flutter/material.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class TransactionItemRow extends StatelessWidget {
  const TransactionItemRow({
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
    final title = (transaction.note?.isNotEmpty ?? false)
        ? transaction.note!
        : transaction.category;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          LetterAvatar(title),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                Text(transaction.category, style: text.bodySmall),
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
