import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/money/view/wizards/add_transaction_wizard.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';

void main() {
  group('TransactionCategories', () {
    test('find matches both value and label case-insensitively', () {
      expect(TransactionCategories.find('groceries', TransactionType.expense)?.value, 'groceries');
      expect(TransactionCategories.find('Groceries', TransactionType.expense)?.value, 'groceries');
      expect(TransactionCategories.find('GROCERIES', TransactionType.expense)?.value, 'groceries');
      expect(TransactionCategories.find('Eating out', TransactionType.expense)?.value, 'eating_out');
      expect(TransactionCategories.find('eating_out', TransactionType.expense)?.value, 'eating_out');

      expect(TransactionCategories.find('salary', TransactionType.income)?.value, 'salary');
      expect(TransactionCategories.find('Salary', TransactionType.income)?.value, 'salary');
      expect(TransactionCategories.find('Shift pay', TransactionType.income)?.value, 'shift_pay');
    });

    test('merchantsFor returns suggested merchants for label or value', () {
      expect(TransactionCategories.merchantsFor('groceries'), contains('Woolworths'));
      expect(TransactionCategories.merchantsFor('Groceries'), contains('Woolworths'));
      expect(TransactionCategories.merchantsFor('eating_out'), ["Domino's", 'KFC', "McDonald's", 'Uber Eats']);
      expect(TransactionCategories.merchantsFor('Entertainment'), ['Netflix', 'Spotify', 'QFX', 'Prime Video']);
    });

    test('AddTransactionWizard preserves initialType income', () {
      const wizard = AddTransactionWizard(initialType: TransactionType.income);
      expect(wizard.initialType, TransactionType.income);
    });
  });

  group('TransactionRepository Add', () {
    late AppDatabase db;
    late AccountRepository accountRepo;
    late TransactionRepository txRepo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      accountRepo = AccountRepository(db);
      txRepo = TransactionRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('successfully adds expense with category label', () async {
      final accountId = await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 0,
        currencyCode: 'AUD',
      );

      final txId = await txRepo.add(
        accountId: accountId,
        type: TransactionType.expense,
        amountMinor: 5420,
        category: 'Groceries',
        note: 'Woolworths',
        occurredAt: DateTime.now(),
      );

      expect(txId, greaterThan(0));

      final all = await txRepo.watchAll().first;
      expect(all.length, 1);
      expect(all.first.amountMinor, 5420);
      expect(all.first.category, 'Groceries');
      expect(all.first.type, 'expense');
    });

    test('successfully adds expense with category value', () async {
      final accountId = await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 0,
        currencyCode: 'AUD',
      );

      final txId = await txRepo.add(
        accountId: accountId,
        type: TransactionType.expense,
        amountMinor: 3000,
        category: 'transport',
        note: 'Uber',
        occurredAt: DateTime.now(),
      );

      expect(txId, greaterThan(0));
      final all = await txRepo.watchAll().first;
      expect(all.first.category, 'Transport');
    });

    test('rejects negative or zero amount', () async {
      final accountId = await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 0,
        currencyCode: 'AUD',
      );

      expect(
        () => txRepo.add(
          accountId: accountId,
          type: TransactionType.expense,
          amountMinor: 0,
          category: 'Groceries',
          occurredAt: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });
  });
}
