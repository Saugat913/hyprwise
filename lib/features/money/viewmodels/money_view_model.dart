import 'package:flutter/foundation.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

enum MoneyFilterTab { all, income, expenses, lending, borrowing }

class MoneyViewModel extends ChangeNotifier {
  MoneyViewModel({
    required this.financeStore,
    required this.transactionRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final TransactionRepository transactionRepo;

  MoneyFilterTab _tab = MoneyFilterTab.all;
  MoneyFilterTab get tab => _tab;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  int? _selectedAccountId;
  int? get selectedAccountId => _selectedAccountId;

  void _onStoreChanged() {
    notifyListeners();
  }

  String get baseCurrency => financeStore.baseCurrency;
  FinanceSnapshot get snapshot => financeStore.snapshot;
  List<Account> get accounts => financeStore.accounts;

  void setTab(MoneyFilterTab tab) {
    _tab = tab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void selectAccount(int? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  List<String> get availableCategories {
    return financeStore.transactions.map((t) => t.category).toSet().toList();
  }

  List<Debt> get debts => financeStore.debts;
  List<Debt> get lentDebts =>
      financeStore.debts.where((d) => d.type == DebtType.lent.value).toList();
  List<Debt> get borrowedDebts =>
      financeStore.debts.where((d) => d.type == DebtType.borrowed.value).toList();

  List<Transaction> get transactions {
    var list = financeStore.transactions;

    if (_tab == MoneyFilterTab.income) {
      list = list.where((t) => t.type == TransactionType.income.value).toList();
    } else if (_tab == MoneyFilterTab.expenses) {
      list = list.where((t) => t.type == TransactionType.expense.value).toList();
    } else if (_tab == MoneyFilterTab.lending) {
      list = list.where((t) =>
        t.category.toLowerCase().contains('lend') ||
        (t.note != null && t.note!.toLowerCase().contains('lent'))
      ).toList();
    } else if (_tab == MoneyFilterTab.borrowing) {
      list = list.where((t) =>
        t.category.toLowerCase().contains('borrow') ||
        (t.note != null && t.note!.toLowerCase().contains('borrowed'))
      ).toList();
    }

    if (_selectedCategory != null) {
      final sel = _selectedCategory!.trim().toLowerCase();
      list = list.where((t) {
        final cat = t.category.trim().toLowerCase();
        return cat == sel ||
            TransactionCategories.find(sel, TransactionType.expense)?.label.toLowerCase() == cat ||
            TransactionCategories.find(sel, TransactionType.income)?.label.toLowerCase() == cat ||
            TransactionCategories.find(cat, TransactionType.expense)?.value.toLowerCase() == sel ||
            TransactionCategories.find(cat, TransactionType.income)?.value.toLowerCase() == sel;
      }).toList();
    }

    if (_selectedAccountId != null) {
      list = list.where((t) => t.accountId == _selectedAccountId).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((t) {
        final c = t.category.toLowerCase();
        final n = t.note?.toLowerCase() ?? '';
        return c.contains(q) || n.contains(q);
      }).toList();
    }

    return list;
  }

  Future<int> ensureDefaultAccount() async {
    final existing = financeStore.accounts;
    if (existing.isNotEmpty) {
      return existing.first.id;
    }
    return getIt<AccountRepository>().add(
      name: 'Everyday',
      type: AccountType.bank,
      openingBalanceMinor: 0,
      currencyCode: baseCurrency,
    );
  }

  Future<int> addTransaction({
    int? accountId,
    required int amountMinor,
    required TransactionType type,
    required String category,
    String? merchant,
    String? note,
    DateTime? occurredAt,
  }) async {
    final effectiveAccountId = (accountId != null && accountId > 0)
        ? accountId
        : await ensureDefaultAccount();

    final combinedNote = (merchant != null && merchant.isNotEmpty)
        ? ((note != null && note.isNotEmpty) ? '$merchant · $note' : merchant)
        : note;
    final id = await transactionRepo.add(
      accountId: effectiveAccountId,
      amountMinor: amountMinor,
      type: type,
      category: category,
      note: combinedNote,
      occurredAt: occurredAt ?? DateTime.now(),
    );

    TelemetryService.instance.trackEvent('transaction_added', {
      'type': type.value,
      'category': category,
      'amount': amountMinor,
    });

    return id;
  }

  Future<void> deleteTransaction(int id) async {
    await transactionRepo.delete(id);
    TelemetryService.instance.trackEvent('transaction_deleted', {'id': id});
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
