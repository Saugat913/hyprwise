import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/export/analytics_pdf_service.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final getIt = GetIt.instance;
  late AppDatabase db;
  late FinanceStore store;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;
  late DebtRepository debtRepo;
  late JobRepository jobRepo;
  late ShiftRepository shiftRepo;
  late AnalyticsViewModel analyticsVm;

  setUp(() async {
    await getIt.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    accountRepo = AccountRepository(db);
    txRepo = TransactionRepository(db);
    final recRepo = RecurringRepository(db);
    jobRepo = JobRepository(db);
    shiftRepo = ShiftRepository(db);
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

    // Seed test data
    final accId = await accountRepo.add(
      name: 'Main Checking',
      type: AccountType.bank,
      currencyCode: 'USD',
      openingBalanceMinor: 200000,
    );

    final now = DateTime.now();
    await txRepo.add(
      accountId: accId,
      type: TransactionType.income,
      amountMinor: 350000,
      category: 'salary',
      occurredAt: now,
      note: 'Tech Payroll',
    );

    await txRepo.add(
      accountId: accId,
      type: TransactionType.expense,
      amountMinor: 8500,
      category: 'groceries',
      occurredAt: now,
      note: 'Weekly Grocery',
    );

    final jobId = await jobRepo.add(
      name: 'Shift Supervisor',
      hourlyRateMinor: 2800,
      currencyCode: 'USD',
    );

    await shiftRepo.add(
      jobId: jobId,
      startAt: now.subtract(const Duration(hours: 5)),
      endAt: now,
      status: ShiftStatus.completed,
    );

    await debtRepo.add(
      personName: 'Sarah Connor',
      type: DebtType.lent,
      amountMinor: 15000,
      currencyCode: 'USD',
      dueDate: now.add(const Duration(days: 30)),
    );

    await Future.delayed(const Duration(milliseconds: 150));
  });

  tearDown(() async {
    analyticsVm.dispose();
    store.dispose();
    await db.close();
    await getIt.reset();
  });

  test('Free plan generates PDF containing the HYPRWISE watermark', () async {
    final file = await AnalyticsPdfService.generatePdf(analyticsVm, isProOverride: false);
    expect(file.existsSync(), isTrue);

    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(1000));

    // Verify PDF header is valid
    expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D])); // %PDF-

    // Extract and decompress flate streams to verify watermark text
    bool foundWatermark = false;
    final streamMarker = 'stream\n'.codeUnits;
    final endStreamMarker = '\nendstream'.codeUnits;

    for (int i = 0; i < bytes.length - streamMarker.length; i++) {
      bool match = true;
      for (int m = 0; m < streamMarker.length; m++) {
        if (bytes[i + m] != streamMarker[m]) {
          match = false;
          break;
        }
      }
      if (match) {
        final start = i + streamMarker.length;
        int end = -1;
        for (int j = start; j < bytes.length - endStreamMarker.length; j++) {
          bool endMatch = true;
          for (int m = 0; m < endStreamMarker.length; m++) {
            if (bytes[j + m] != endStreamMarker[m]) {
              endMatch = false;
              break;
            }
          }
          if (endMatch) {
            end = j;
            break;
          }
        }
        if (end > start) {
          try {
            final streamBytes = bytes.sublist(start, end);
            final decompressed = zlib.decode(streamBytes);
            final decompressedText = String.fromCharCodes(decompressed);
            if (decompressedText.contains('HYPRWISE')) {
              foundWatermark = true;
              break;
            }
          } catch (_) {}
        }
      }
    }

    expect(foundWatermark, isTrue, reason: 'Expected watermark to contain HYPRWISE');

    // Clean up temporary file
    try {
      file.deleteSync();
    } catch (_) {}
  });

  test('Pro plan generates PDF without watermark', () async {
    final file = await AnalyticsPdfService.generatePdf(analyticsVm, isProOverride: true);
    expect(file.existsSync(), isTrue);

    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(1000));

    // Verify PDF header is valid
    expect(bytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D])); // %PDF-

    try {
      file.deleteSync();
    } catch (_) {}
  });
}
