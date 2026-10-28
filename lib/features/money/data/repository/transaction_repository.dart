import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

/// Transactions and transfers between accounts.
class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  Stream<List<Transaction>> watchAll() =>
      (_db.select(_db.transactions)..orderBy([
        (t) => OrderingTerm.desc(t.occurredAt),
        (t) => OrderingTerm.desc(t.id),
      ])).watch();

  /// Returns the new id so the UI can offer Undo via [delete].
  Future<int> add({
    required int accountId,
    required TransactionType type,
    required int amountMinor,
    required String category,
    required DateTime occurredAt,
    String? note,
  }) {
    _validate(amountMinor, category, type);
    final categoryLabel =
        TransactionCategories.find(category, type)?.label ?? category;
    return _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            accountId: accountId,
            type: type.value,
            amountMinor: amountMinor,
            category: categoryLabel,
            note: Value(normalizeText(note)),
            occurredAt: occurredAt.millisecondsSinceEpoch,
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Future<void> update(
    int id, {
    required int accountId,
    required TransactionType type,
    required int amountMinor,
    required String category,
    required DateTime occurredAt,
    String? note,
  }) async {
    _validate(amountMinor, category, type);
    final categoryLabel =
        TransactionCategories.find(category, type)?.label ?? category;
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        accountId: Value(accountId),
        type: Value(type.value),
        amountMinor: Value(amountMinor),
        category: Value(categoryLabel),
        note: Value(normalizeText(note)),
        occurredAt: Value(occurredAt.millisecondsSinceEpoch),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

  Stream<List<Transfer>> watchTransfers() =>
      (_db.select(_db.transfers)..orderBy([
        (t) => OrderingTerm.desc(t.occurredAt),
        (t) => OrderingTerm.desc(t.id),
      ])).watch();

  /// Moves money between two active accounts. For cross-currency transfers
  /// pass [destinationAmountMinor] or [exchangeRate]; otherwise the amount is
  /// carried over 1:1.
  Future<int> addTransfer({
    required int sourceAccountId,
    required int destinationAccountId,
    required int amountMinor,
    required DateTime occurredAt,
    int? destinationAmountMinor,
    double? exchangeRate,
    String? note,
  }) async {
    if (sourceAccountId == destinationAccountId) {
      throw ArgumentError('Choose two different accounts.');
    }
    if (amountMinor <= 0) {
      throw ArgumentError('Transfer amount must be positive.');
    }
    final source =
        await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(sourceAccountId))).getSingleOrNull();
    final destination =
        await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(destinationAccountId))).getSingleOrNull();
    if (source == null || destination == null) {
      throw ArgumentError('Both accounts must exist.');
    }
    if (source.isArchived || destination.isArchived) {
      throw ArgumentError('Transfers require active accounts.');
    }

    final sameCurrency = source.currencyCode == destination.currencyCode;
    final destAmount =
        sameCurrency
            ? amountMinor
            : (destinationAmountMinor ??
                (exchangeRate != null
                    ? (amountMinor * exchangeRate).round()
                    : amountMinor));
    final rateScaled =
        sameCurrency
            ? null
            : (exchangeRate != null
                ? (exchangeRate * ExchangeRateQuote.scale).round()
                : (destAmount * ExchangeRateQuote.scale / amountMinor)
                    .round());

    return _db
        .into(_db.transfers)
        .insert(
          TransfersCompanion.insert(
            sourceAccountId: sourceAccountId,
            destinationAccountId: destinationAccountId,
            amountMinor: amountMinor,
            destinationAmountMinor: Value(destAmount),
            exchangeRateScaled: Value(rateScaled),
            note: Value(normalizeText(note)),
            occurredAt: occurredAt.millisecondsSinceEpoch,
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Future<void> deleteTransfer(int id) =>
      (_db.delete(_db.transfers)..where((t) => t.id.equals(id))).go();

  void _validate(int amountMinor, String category, TransactionType type) {
    if (amountMinor <= 0) {
      throw ArgumentError('Amount must be positive.');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError('Choose a valid category.');
    }
  }
}
