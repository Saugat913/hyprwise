import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Stream<List<Account>> watchAll() =>
      (_db.select(_db.accounts)..orderBy([
        (a) => OrderingTerm.asc(a.isArchived),
        (a) => OrderingTerm.asc(a.name),
      ])).watch();

  Future<List<Account>> getAll() =>
      (_db.select(_db.accounts)..orderBy([
        (a) => OrderingTerm.asc(a.isArchived),
        (a) => OrderingTerm.asc(a.name),
      ])).get();

  Future<int> add({
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    required String currencyCode,
  }) {
    _validate(name);
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name.trim(),
            type: type.value,
            openingBalanceMinor: openingBalanceMinor,
            currencyCode: currencyCode.toUpperCase(),
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Future<void> update(
    int id, {
    String? name,
    AccountType? type,
    int? openingBalanceMinor,
    String? currencyCode,
  }) async {
    if (name != null) _validate(name);
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        type: type != null ? Value(type.value) : const Value.absent(),
        openingBalanceMinor:
            openingBalanceMinor != null
                ? Value(openingBalanceMinor)
                : const Value.absent(),
        currencyCode:
            currencyCode != null
                ? Value(currencyCode.toUpperCase())
                : const Value.absent(),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> setArchived(int id, {required bool archived}) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(isArchived: Value(archived), updatedAt: Value(nowMs())),
    );
  }

  /// Enforces exactly two active accounts in the system: 'Everyday' and 'Savings'.
  /// Consolidates any legacy or extra accounts into these two.
  Future<({Account everyday, Account savings})> ensureFixedTwoAccounts(String baseCurrency) async {
    final existing = await (_db.select(_db.accounts)).get();
    Account? everyday = existing.where((a) => !a.isArchived && a.name.toLowerCase() == 'everyday').firstOrNull;
    Account? savings = existing.where((a) => !a.isArchived && (a.name.toLowerCase() == 'savings' || a.type == AccountType.savings.value)).firstOrNull;

    if (everyday == null) {
      final firstOperational = existing.where((a) => !a.isArchived && a.id != savings?.id).firstOrNull;
      if (firstOperational != null) {
        await update(firstOperational.id, name: 'Everyday', type: AccountType.bank, currencyCode: baseCurrency);
        everyday = await (_db.select(_db.accounts)..where((a) => a.id.equals(firstOperational.id))).getSingle();
      } else {
        final id = await add(
          name: 'Everyday',
          type: AccountType.bank,
          openingBalanceMinor: 0,
          currencyCode: baseCurrency,
        );
        everyday = await (_db.select(_db.accounts)..where((a) => a.id.equals(id))).getSingle();
      }
    } else if (everyday.currencyCode != baseCurrency) {
      await update(everyday.id, currencyCode: baseCurrency);
      everyday = await (_db.select(_db.accounts)..where((a) => a.id.equals(everyday!.id))).getSingle();
    }

    if (savings == null) {
      final id = await add(
        name: 'Savings',
        type: AccountType.savings,
        openingBalanceMinor: 0,
        currencyCode: baseCurrency,
      );
      savings = await (_db.select(_db.accounts)..where((a) => a.id.equals(id))).getSingle();
    } else {
      if (savings.name != 'Savings' || savings.type != AccountType.savings.value || savings.currencyCode != baseCurrency) {
        await update(savings.id, name: 'Savings', type: AccountType.savings, currencyCode: baseCurrency);
        savings = await (_db.select(_db.accounts)..where((a) => a.id.equals(savings!.id))).getSingle();
      }
    }

    // Consolidate any extraneous legacy accounts into the 2 fixed accounts
    for (final acc in existing) {
      if (acc.id != everyday.id && acc.id != savings.id) {
        final targetId = acc.type == AccountType.savings.value ? savings.id : everyday.id;
        await (_db.update(_db.transactions)..where((t) => t.accountId.equals(acc.id)))
            .write(TransactionsCompanion(accountId: Value(targetId)));
        await (_db.update(_db.transfers)..where((t) => t.sourceAccountId.equals(acc.id)))
            .write(TransfersCompanion(sourceAccountId: Value(targetId)));
        await (_db.update(_db.transfers)..where((t) => t.destinationAccountId.equals(acc.id)))
            .write(TransfersCompanion(destinationAccountId: Value(targetId)));
        await (_db.update(_db.goals)..where((g) => g.accountId.equals(acc.id)))
            .write(GoalsCompanion(accountId: Value(savings.id)));
        await (_db.delete(_db.accounts)..where((a) => a.id.equals(acc.id))).go();
      }
    }

    // Ensure all goals point to savings account
    await (_db.update(_db.goals)..where((g) => g.accountId.isNull() | g.accountId.isNotValue(savings!.id)))
        .write(GoalsCompanion(accountId: Value(savings.id)));

    return (everyday: everyday, savings: savings);
  }

  void _validate(String name) {
    if (name.trim().isEmpty) throw ArgumentError('Name is required.');
  }
}
