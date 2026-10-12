class TransferDraft {
  const TransferDraft({
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountMinor,
    required this.occurredAt,
    this.note,
  });

  final int sourceAccountId;
  final int destinationAccountId;
  final int amountMinor;
  final DateTime occurredAt;
  final String? note;
}
