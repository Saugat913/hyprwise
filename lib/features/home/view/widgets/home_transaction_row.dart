import 'package:flutter/material.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/view/widgets/transaction_action_sheet.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class HomeTransactionRow extends StatelessWidget {
  const HomeTransactionRow({
    super.key,
    required this.transaction,
    required this.currency,
    this.onChanged,
  });

  final Transaction transaction;
  final String currency;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final isIncome = transaction.type == TransactionType.income.value;
    final locCat = TransactionCategories.localizedCategoryName(transaction.category);
    final rawNote = transaction.note ?? '';
    final name = rawNote.isNotEmpty ? tr.formatTransactionNote(rawNote) : locCat;
    final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);

    return InkWell(
      onTap: () => showTransactionActionSheet(
        context,
        transaction: transaction,
        currency: currency,
        onDeleted: onChanged,
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
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
                    '$locCat · ${DateFormatter.relative(date)} · ${AppDate.timeOnly(date)}',
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
      ),
    );
  }
}
