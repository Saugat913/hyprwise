import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  group('Assistant Action & Workflow Execution', () {
    late AppDatabase db;
    late AccountRepository accountRepo;
    late TransactionRepository transactionRepo;
    late ShiftRepository shiftRepo;
    late GoalRepository goalRepo;
    late FinanceStore financeStore;
    late AssistantViewModel viewModel;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      accountRepo = AccountRepository(db);
      await accountRepo.ensureFixedTwoAccounts('USD');

      transactionRepo = TransactionRepository(db);
      final recurringRepo = RecurringRepository(db);
      final jobsRepo = JobRepository(db);
      shiftRepo = ShiftRepository(db);
      goalRepo = GoalRepository(db);
      final ratesRepo = ExchangeRateRepository(db);
      final settingsRepo = SettingsRepository(db);
      await settingsRepo.load();
      final debtsRepo = DebtRepository(db);

      financeStore = FinanceStore(
        accountsRepo: accountRepo,
        transactionsRepo: transactionRepo,
        recurringRepo: recurringRepo,
        jobsRepo: jobsRepo,
        shiftsRepo: shiftRepo,
        goalsRepo: goalRepo,
        ratesRepo: ratesRepo,
        settingsRepo: settingsRepo,
        debtsRepo: debtsRepo,
      );

      viewModel = AssistantViewModel(
        financeStore: financeStore,
        transactionRepo: transactionRepo,
        shiftRepo: shiftRepo,
        goalRepo: goalRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Direct command executes transaction and returns rich confirmation result', () async {
      await viewModel.sendMessage('Add 1500 to groceries expenses');

      // Check messages
      expect(viewModel.messages.length, 2);
      expect(viewModel.messages[0].isUser, isTrue);
      expect(viewModel.messages[0].text, 'Add 1500 to groceries expenses');

      final reply = viewModel.messages[1];
      expect(reply.isUser, isFalse);
      expect(reply.headline, 'Expense Added');
      expect(reply.isConfirmed, isTrue);
      expect(reply.createdTransactionId, isNotNull);
      expect(reply.confirmedSummary, contains('Groceries'));

      // Verify transaction exists in database
      final txs = await transactionRepo.watchAll().first;
      expect(txs.length, 1);
      expect(txs.first.amountMinor, 150000); // 1500 * 100
      expect(txs.first.category, 'Groceries');

      // Test undo workflow
      await viewModel.undoTransaction(reply);
      final txsAfterUndo = await transactionRepo.watchAll().first;
      expect(txsAfterUndo, isEmpty);
      expect(reply.createdTransactionId, isNull);
    });

    test('AssistantMessage supports imageBytes and imagePath for chat preview', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final msg = AssistantMessage(
        isUser: true,
        text: '📸 Scanned receipt: receipt.jpg',
        imageBytes: bytes,
        imagePath: '/tmp/receipt.jpg',
      );

      expect(msg.imageBytes, isNotNull);
      expect(msg.imageBytes!.length, 5);
      expect(msg.imagePath, '/tmp/receipt.jpg');
    });

    test('Assistant restricts unknown non-financial queries with explicit "I don\'t know that"', () async {
      await viewModel.sendMessage('Who is the president of France?');

      expect(viewModel.messages.length, 2);
      final reply = viewModel.messages[1];
      expect(reply.isUser, isFalse);
      expect(reply.text, contains("I don't know that"));
      expect(reply.headline, "I don't know that");
    });

    test('Assistant returns honest "No records found" when querying unrecorded spending', () async {
      await viewModel.sendMessage('How much did I spend at Gucci?');

      expect(viewModel.messages.length, 2);
      final reply = viewModel.messages[1];
      expect(reply.isUser, isFalse);
      expect(reply.headline, 'No records found');
      expect(reply.text, contains("I don't have any recorded transactions"));
    });

    test('Assistant reports no upcoming shifts when schedule is empty', () async {
      await viewModel.sendMessage('When is my next shift?');

      expect(viewModel.messages.length, 2);
      final reply = viewModel.messages[1];
      expect(reply.isUser, isFalse);
      expect(reply.headline, 'No upcoming shifts');
      expect(reply.text, contains("You have no upcoming shifts scheduled"));
    });
  });
}
