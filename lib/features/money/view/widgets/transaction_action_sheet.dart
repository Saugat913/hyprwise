import 'package:flutter/material.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

/// Shows an action bottom sheet when a transaction tile is tapped.
Future<void> showTransactionActionSheet(
  BuildContext context, {
  required Transaction transaction,
  required String currency,
  VoidCallback? onDeleted,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final scheme = Theme.of(ctx).colorScheme;
      final colors = ctx.colors;
      final tr = ctx.strings;
      final isIncome = transaction.type == TransactionType.income.value;
      final locCat = TransactionCategories.localizedCategoryName(
        transaction.category,
      );
      final rawNote = transaction.note ?? '';
      final title =
          rawNote.isNotEmpty ? tr.formatTransactionNote(rawNote) : locCat;
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
      final store = getIt<FinanceStore>();
      final account =
          store.accounts
              .where((a) => a.id == transaction.accountId)
              .firstOrNull;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.page,
            vertical: AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon, title, and amount
              Row(
                children: [
                  LetterAvatar(title),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$locCat${account != null ? ' · ${account.name}' : ''}',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  MoneyText(
                    isIncome
                        ? transaction.amountMinor
                        : -transaction.amountMinor,
                    currency,
                    signed: true,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isIncome ? colors.income : colors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),

              // Transaction Meta Details Card
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    _MetaRow(
                      label: tr.date,
                      value:
                          '${AppDate.header(date)}, ${AppDate.timeOnly(date)}',
                    ),
                    const SizedBox(height: AppSpace.sm),
                    _MetaRow(
                      label: tr.typeLabel,
                      value: isIncome ? tr.income : tr.expense,
                      valueColor: isIncome ? colors.income : colors.expense,
                    ),
                    if (rawNote.isNotEmpty && rawNote != title) ...[
                      const SizedBox(height: AppSpace.sm),
                      _MetaRow(label: tr.notes, value: rawNote),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.expense,
                        side: BorderSide(
                          color: colors.expense.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(tr.delete),
                      onPressed: () async {
                        final confirm = await showConfirmDialog(
                          ctx,
                          title: tr.deleteTransactionTitle,
                          message: tr.deleteTransactionSubtitle,
                          confirmLabel: tr.delete,
                          destructive: true,
                        );
                        if (confirm == true) {
                          await getIt<TransactionRepository>().delete(
                            transaction.id,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          onDeleted?.call();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(tr.edit),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditTransactionSheet(context, transaction);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Flexible(
          child: Text(
            value,
            style: text.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? scheme.onSurface,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Future<void> _showEditTransactionSheet(
  BuildContext context,
  Transaction transaction,
) async {
  final tr = context.strings;
  final text = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;
  final repo = getIt<TransactionRepository>();

  final amountController = TextEditingController(
    text: (transaction.amountMinor / 100).toStringAsFixed(
      transaction.amountMinor % 100 == 0 ? 0 : 2,
    ),
  );
  final noteController = TextEditingController(text: transaction.note ?? '');
  var selectedCategory = transaction.category;
  DateTime selectedDate = DateTime.fromMillisecondsSinceEpoch(
    transaction.occurredAt,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final isIncome = transaction.type == TransactionType.income.value;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpace.page,
                right: AppSpace.page,
                top: AppSpace.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpace.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr.edit,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: tr.amount,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: tr.noteOptional,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                      ),
                      title: Text(AppDate.header(selectedDate)),
                      subtitle: Text(AppDate.timeOnly(selectedDate)),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null && ctx.mounted) {
                          final pickedTime = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: AppSpace.xl),
                    AppButton(
                      tr.saveChanges,
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountController.text.trim()) ?? 0;
                        if (amount <= 0) return;
                        final minor = (amount * 100).round();
                        await repo.update(
                          transaction.id,
                          accountId: transaction.accountId,
                          type:
                              isIncome
                                  ? TransactionType.income
                                  : TransactionType.expense,
                          amountMinor: minor,
                          category: selectedCategory,
                          occurredAt: selectedDate,
                          note:
                              noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
