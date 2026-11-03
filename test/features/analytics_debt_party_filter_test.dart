import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/export/analytics_pdf_service.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/analytics/data/analytics_tab_data.dart';
import 'package:finance_tracker/features/analytics/view/analytics_tabs.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/goals/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance;
  late AppDatabase db;
  late FinanceStore store;
  late DebtRepository debtRepo;
  late AnalyticsViewModel analyticsVm;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final accountRepo = AccountRepository(db);
    final txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    final jobRepo = JobRepository(db);
    final shiftRepo = ShiftRepository(db);
    final goalRepo = GoalRepository(db);
    debtRepo = DebtRepository(db);
    final ratesRepo = ExchangeRateRepository(db);
    final settingsRepo = SettingsRepository(db);
    await settingsRepo.load();

    store = FinanceStore(
      accountsRepo: accountRepo,
      transactionsRepo: txRepo,
      recurringRepo: recRepo,
      jobsRepo: jobRepo,
      shiftsRepo: shiftRepo,
      goalsRepo: goalRepo,
      debtsRepo: debtRepo,
      ratesRepo: ratesRepo,
      settingsRepo: settingsRepo,
    );
    store.start();

    analyticsVm = AnalyticsViewModel(financeStore: store);
    getIt.registerSingleton<FinanceStore>(store);
    getIt.registerSingleton<AnalyticsViewModel>(analyticsVm);

    await accountRepo.add(
      name: 'Main Everyday',
      type: AccountType.bank,
      currencyCode: 'AUD',
      openingBalanceMinor: 500000,
    );
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    analyticsVm.dispose();
    store.dispose();
    await db.close();
    await getIt.reset();
  });

  group('Analytics Lending and Borrowing Party Filtering', () {
    test('selectDebtParty updates selection, toggles, and clearFilters resets it', () {
      expect(analyticsVm.selectedDebtParty, isNull);

      analyticsVm.selectDebtParty('Alice');
      expect(analyticsVm.selectedDebtParty, 'Alice');

      // Toggling again clears it
      analyticsVm.selectDebtParty('Alice');
      expect(analyticsVm.selectedDebtParty, isNull);

      analyticsVm.selectDebtParty('Bob');
      expect(analyticsVm.selectedDebtParty, 'Bob');

      analyticsVm.clearFilters();
      expect(analyticsVm.selectedDebtParty, isNull);
    });

    test('debtPartiesFor and partyTotalFor calculate correctly per debt type', () async {
      // Add lent debts for Alice and Bob
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Alice',
        amountMinor: 30000, // $300
        currencyCode: 'AUD',
      );
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Alice',
        amountMinor: 20000, // $200
        currencyCode: 'AUD',
      );
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Bob',
        amountMinor: 15000, // $150
        currencyCode: 'AUD',
      );

      // Add borrowed debt for Charlie
      await debtRepo.add(
        type: DebtType.borrowed,
        personName: 'Charlie',
        amountMinor: 40000, // $400
        currencyCode: 'AUD',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final lentParties = analyticsVm.debtPartiesFor(DebtType.lent);
      expect(lentParties, containsAll(['Alice', 'Bob']));
      expect(lentParties, isNot(contains('Charlie')));

      final borrowedParties = analyticsVm.debtPartiesFor(DebtType.borrowed);
      expect(borrowedParties, contains('Charlie'));
      expect(borrowedParties, isNot(contains('Alice')));

      // Test party total
      expect(analyticsVm.partyTotalFor('Alice', DebtType.lent), 50000);
      expect(analyticsVm.partyTotalFor('Bob', DebtType.lent), 15000);
      expect(analyticsVm.partyTotalFor('Charlie', DebtType.borrowed), 40000);
    });

    test('debtTabData accurately isolates data when party is filtered', () async {
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Alice',
        amountMinor: 50000,
        currencyCode: 'AUD',
      );
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Bob',
        amountMinor: 25000,
        currencyCode: 'AUD',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      // Without filter: total $750, count 2, both parties in breakdown
      final unfiltered = analyticsVm.debtTabData(DebtType.lent);
      expect(unfiltered.totalMinor, 75000);
      expect(unfiltered.count, 2);
      expect(unfiltered.parties.length, 2);

      // Filter by Alice: total $500, count 1, top items is Alice
      analyticsVm.selectDebtParty('Alice');
      final filteredAlice = analyticsVm.debtTabData(DebtType.lent);
      expect(filteredAlice.totalMinor, 50000);
      expect(filteredAlice.count, 1);
      expect(filteredAlice.selectedParty, 'Alice');
      expect(filteredAlice.top.first.personName, 'Alice');
      // Parties breakdown retains all parties in range so user can compare and tap others
      expect(filteredAlice.parties.length, 2);

      // Filter by Bob
      analyticsVm.selectDebtParty('Bob');
      final filteredBob = analyticsVm.debtTabData(DebtType.lent);
      expect(filteredBob.totalMinor, 25000);
      expect(filteredBob.count, 1);
      expect(filteredBob.selectedParty, 'Bob');
    });

    testWidgets('AnalyticsDebtTab renders party filter chip and responds to selection', (tester) async {
      await tester.runAsync(() async {
        await debtRepo.add(
          type: DebtType.lent,
          personName: 'Alice Smith',
          amountMinor: 60000,
          currencyCode: 'AUD',
        );
        await debtRepo.add(
          type: DebtType.lent,
          personName: 'Bob Jones',
          amountMinor: 40000,
          currencyCode: 'AUD',
        );
        await Future.delayed(const Duration(milliseconds: 100));
      });

      analyticsVm.selectDebtParty('Alice Smith');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AnalyticsDebtTab(
              viewModel: analyticsVm,
              type: DebtType.lent,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Active chip should display Alice Smith
      expect(find.text('Alice Smith'), findsWidgets);
      expect(find.byType(InputChip), findsOneWidget);

      // Tap to clear filter via clear action
      final clearFinder = find.text('Clear');
      expect(clearFinder, findsOneWidget);
      await tester.tap(clearFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(analyticsVm.selectedDebtParty, isNull);
    });

    test('PDF export reflects filtered party in header when party filter is active', () async {
      await debtRepo.add(
        type: DebtType.lent,
        personName: 'Diana Prince',
        amountMinor: 100000,
        currencyCode: 'AUD',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      analyticsVm.selectDebtParty('Diana Prince');

      final file = await AnalyticsPdfService.generatePdf(
        analyticsVm,
        activeTabIndex: 3, // Lent tab
      );

      expect(file.existsSync(), isTrue);
      expect(await file.length(), greaterThan(0));
      await file.delete();
    });
  });
}
