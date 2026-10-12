import 'package:drift/drift.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/domain/account_draft.dart';

/// Persistence API for accounts.
///
/// Drift streams are the source of truth; screens should listen to these
/// instead of maintaining a separate, potentially stale list in memory.
class AccountRepository {
  AccountRepository(this._database);

  final AppDatabase _database;

  Stream<List<Account>> watchAccounts({bool includeArchived = false}) {
    final query = _database.select(_database.accounts)
      ..orderBy([
        (account) => OrderingTerm.asc(account.isArchived),
        (account) => OrderingTerm.asc(account.name),
      ]);

    if (!includeArchived) {
      query.where((account) => account.isArchived.equals(false));
    }

    return query.watch();
  }

  Future<int> createAccount(AccountDraft draft) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _database.into(_database.accounts).insert(
      AccountsCompanion.insert(
        name: draft.name.trim(),
        type: draft.type.value,
        openingBalanceMinor: draft.openingBalanceMinor,
        currencyCode: draft.currencyCode.toUpperCase(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> updateAccount({
    required int id,
    required AccountDraft draft,
  }) async {
    final updated = await (_database.update(_database.accounts)
      ..where((account) => account.id.equals(id))).write(
      AccountsCompanion(
        name: Value(draft.name.trim()),
        type: Value(draft.type.value),
        openingBalanceMinor: Value(draft.openingBalanceMinor),
        currencyCode: Value(draft.currencyCode.toUpperCase()),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    return updated > 0;
  }

  Future<bool> archiveAccount(int id) async {
    final updated = await (_database.update(_database.accounts)
      ..where((account) => account.id.equals(id))).write(
      AccountsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    return updated > 0;
  }

  Future<bool> restoreAccount(int id) async {
    final updated = await (_database.update(_database.accounts)
      ..where((account) => account.id.equals(id))).write(
      AccountsCompanion(
        isArchived: const Value(false),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    return updated > 0;
  }

  Future<void> close() => _database.close();
}
