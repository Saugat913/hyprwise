import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

class AccountsViewModel extends ChangeNotifier {
  AccountsViewModel({
    required this.financeStore,
    required this.accountRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final AccountRepository accountRepo;

  void _onStoreChanged() {
    notifyListeners();
  }

  String get baseCurrency => financeStore.baseCurrency;
  List<Account> get accounts => financeStore.accounts.where((a) => !a.isArchived).toList();

  int get totalBalanceMinor => financeStore.snapshot.netWorthMinor;

  int balanceOf(int accountId) => financeStore.snapshot.balanceOf(accountId);

  Future<int> addAccount({
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    String? currencyCode,
  }) async {
    final id = await accountRepo.add(
      name: name,
      type: type,
      openingBalanceMinor: openingBalanceMinor,
      currencyCode: currencyCode ?? baseCurrency,
    );
    TelemetryService.instance.trackEvent('account_added', {'type': type.value});
    return id;
  }

  Future<void> updateAccount(int id, {String? name, AccountType? type}) async {
    await accountRepo.update(id, name: name, type: type);
    TelemetryService.instance.trackEvent('account_updated', {'id': id});
  }

  Future<void> deleteAccount(int id) async {
    await accountRepo.setArchived(id, archived: true);
    TelemetryService.instance.trackEvent('account_archived', {'id': id});
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
