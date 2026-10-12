import 'package:drift/drift.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_draft.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_type.dart';

/// Offline-first persistence API for income and expense records.
class TransactionRepository {
  TransactionRepository(this._database);

  final AppDatabase _database;

  Stream<List<Transaction>> watchTransactions({
    int? accountId,
    TransactionType? type,
    DateTime? from,
    DateTime? through,
  }) {
    final query = _database.select(_database.transactions)
      ..orderBy([
        (transaction) => OrderingTerm.desc(transaction.occurredAt),
        (transaction) => OrderingTerm.desc(transaction.id),
      ]);

    if (accountId != null) {
      query.where((transaction) => transaction.accountId.equals(accountId));
    }
    if (type != null) {
      query.where((transaction) => transaction.type.equals(type.value));
    }
    if (from != null) {
      query.where(
        (transaction) => transaction.occurredAt.isBiggerOrEqualValue(
          from.millisecondsSinceEpoch,
        ),
      );
    }
    if (through != null) {
      query.where(
        (transaction) => transaction.occurredAt.isSmallerOrEqualValue(
          through.millisecondsSinceEpoch,
        ),
      );
    }

    return query.watch();
  }

  Future<int> createTransaction(TransactionDraft draft) async {
    _validateDraft(draft);
    final now = DateTime.now().millisecondsSinceEpoch;

    return _database.into(_database.transactions).insert(
      TransactionsCompanion.insert(
        accountId: draft.accountId,
        type: draft.type.value,
        amountMinor: draft.amountMinor,
        category: draft.category,
        note: Value(_normalizeNote(draft.note)),
        occurredAt: draft.occurredAt.millisecondsSinceEpoch,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> updateTransaction({
    required int id,
    required TransactionDraft draft,
  }) async {
    _validateDraft(draft);
    final updated = await (_database.update(_database.transactions)
      ..where((transaction) => transaction.id.equals(id))).write(
      TransactionsCompanion(
        accountId: Value(draft.accountId),
        type: Value(draft.type.value),
        amountMinor: Value(draft.amountMinor),
        category: Value(draft.category),
        note: Value(_normalizeNote(draft.note)),
        occurredAt: Value(draft.occurredAt.millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    return updated > 0;
  }

  Future<int> deleteTransaction(int id) =>
      (_database.delete(_database.transactions)
        ..where((transaction) => transaction.id.equals(id))).go();

  void _validateDraft(TransactionDraft draft) {
    if (draft.accountId <= 0) {
      throw ArgumentError.value(draft.accountId, 'accountId', 'Must be positive');
    }
    if (draft.amountMinor <= 0) {
      throw ArgumentError.value(
        draft.amountMinor,
        'amountMinor',
        'Transaction amount must be positive',
      );
    }
    if (draft.category.trim().isEmpty || draft.category.length > 40) {
      throw ArgumentError.value(draft.category, 'category', 'Invalid category');
    }
    if ((draft.note?.trim().length ?? 0) > 500) {
      throw ArgumentError.value(draft.note, 'note', 'Use 500 characters or fewer');
    }
  }

  String? _normalizeNote(String? note) {
    final normalized = note?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
