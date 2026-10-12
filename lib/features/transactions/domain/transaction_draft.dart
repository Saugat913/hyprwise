import 'transaction_type.dart';

/// Validated input for creating or editing a transaction.
class TransactionDraft {
  const TransactionDraft({
    required this.accountId,
    required this.type,
    required this.amountMinor,
    required this.category,
    required this.occurredAt,
    this.note,
  });

  final int accountId;
  final TransactionType type;
  final int amountMinor;
  final String category;
  final DateTime occurredAt;
  final String? note;
}
