import 'package:drift/drift.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/transfers/domain/transfer_draft.dart';

/// Offline-first persistence API for transfers between accounts.
class TransferRepository {
  TransferRepository(this._database);

  final AppDatabase _database;

  Stream<List<Transfer>> watchTransfers({int? accountId}) {
    final query = _database.select(_database.transfers)
      ..orderBy([
        (transfer) => OrderingTerm.desc(transfer.occurredAt),
        (transfer) => OrderingTerm.desc(transfer.id),
      ]);

    if (accountId != null) {
      query.where(
        (transfer) =>
            transfer.sourceAccountId.equals(accountId) |
            transfer.destinationAccountId.equals(accountId),
      );
    }

    return query.watch();
  }

  Future<int> createTransfer(TransferDraft draft) async {
    _validateDraft(draft);

    if (draft.sourceAccountId == draft.destinationAccountId) {
      throw ArgumentError('Choose two different accounts.');
    }

    final source = await (_database.select(_database.accounts)
      ..where((account) => account.id.equals(draft.sourceAccountId)))
      .getSingleOrNull();
    final destination = await (_database.select(_database.accounts)
      ..where((account) => account.id.equals(draft.destinationAccountId)))
      .getSingleOrNull();

    if (source == null || destination == null) {
      throw ArgumentError('Both accounts must exist.');
    }
    if (source.isArchived || destination.isArchived) {
      throw ArgumentError('Transfers require active accounts.');
    }
    if (source.currencyCode != destination.currencyCode) {
      throw ArgumentError('Transfers must use accounts with the same currency.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return _database.into(_database.transfers).insert(
      TransfersCompanion.insert(
        sourceAccountId: draft.sourceAccountId,
        destinationAccountId: draft.destinationAccountId,
        amountMinor: draft.amountMinor,
        note: Value(_normalizeNote(draft.note)),
        occurredAt: draft.occurredAt.millisecondsSinceEpoch,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<int> deleteTransfer(int id) =>
      (_database.delete(_database.transfers)
        ..where((transfer) => transfer.id.equals(id))).go();

  void _validateDraft(TransferDraft draft) {
    if (draft.sourceAccountId <= 0 || draft.destinationAccountId <= 0) {
      throw ArgumentError('Choose valid source and destination accounts.');
    }
    if (draft.amountMinor <= 0) {
      throw ArgumentError.value(
        draft.amountMinor,
        'amountMinor',
        'Transfer amount must be positive.',
      );
    }
    if ((draft.note?.trim().length ?? 0) > 500) {
      throw ArgumentError.value(draft.note, 'note', 'Use 500 characters or fewer.');
    }
  }

  String? _normalizeNote(String? note) {
    final normalized = note?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
