import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/notifications/shift_notification_service.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/data/repository/debt_repository.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

class DebtsViewModel extends ChangeNotifier {
  DebtsViewModel({
    required this.financeStore,
    required this.debtRepo,
    required this.transactionRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final DebtRepository debtRepo;
  final TransactionRepository transactionRepo;

  void _onStoreChanged() => notifyListeners();

  List<Debt> get debts => financeStore.debts;

  List<Debt> get activeDebts =>
      financeStore.debts.where((d) => !d.isSettled).toList();

  List<Debt> get settledDebts =>
      financeStore.debts.where((d) => d.isSettled).toList();

  List<Debt> get lentDebts =>
      financeStore.debts.where((d) => d.type == DebtType.lent.value && !d.isSettled).toList();

  List<Debt> get borrowedDebts =>
      financeStore.debts.where((d) => d.type == DebtType.borrowed.value && !d.isSettled).toList();

  int get totalLentMinor =>
      lentDebts.fold<int>(0, (sum, d) => sum + d.amountMinor);

  int get totalBorrowedMinor =>
      borrowedDebts.fold<int>(0, (sum, d) => sum + d.amountMinor);

  /// Net balance: positive = they owe you net, negative = you owe them net.
  int get netBalanceMinor => totalLentMinor - totalBorrowedMinor;

  String get baseCurrency => financeStore.baseCurrency;

  /// Unique list of parties (debtors & creditors) for suggestions & filtering
  List<String> get existingParties => financeStore.debts
      .map((d) => d.personName.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  /// Net balance with a specific party: positive = they owe net, negative = you owe net
  int netForParty(String partyName) {
    final partyDebts = financeStore.debts.where(
      (d) =>
          d.personName.trim().toLowerCase() == partyName.trim().toLowerCase() &&
          !d.isSettled,
    );
    int lent = 0;
    int borrowed = 0;
    for (final d in partyDebts) {
      if (d.type == DebtType.lent.value) {
        lent += d.amountMinor;
      } else {
        borrowed += d.amountMinor;
      }
    }
    return lent - borrowed;
  }

  /// Aggregated party summary grouped by person/counterparty
  List<DebtPartySummary> get partiesSummary {
    final Map<String, List<Debt>> grouped = {};
    for (final debt in financeStore.debts) {
      final key = debt.personName.trim().toLowerCase();
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(debt);
    }

    final list = <DebtPartySummary>[];
    for (final entry in grouped.entries) {
      final debts = entry.value;
      final displayName = debts.first.personName.trim();
      int lent = 0;
      int borrowed = 0;
      for (final d in debts) {
        if (!d.isSettled) {
          if (d.type == DebtType.lent.value) {
            lent += d.amountMinor;
          } else {
            borrowed += d.amountMinor;
          }
        }
      }
      list.add(
        DebtPartySummary(
          personName: displayName,
          debts: debts..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          totalLentMinor: lent,
          totalBorrowedMinor: borrowed,
          currencyCode: debts.first.currencyCode,
        ),
      );
    }

    // Sort: Active parties with non-zero balance first (highest absolute net first), then settled
    list.sort((a, b) {
      if (!a.isSettled && b.isSettled) return -1;
      if (a.isSettled && !b.isSettled) return 1;
      final diff = b.netBalanceMinor.abs().compareTo(a.netBalanceMinor.abs());
      if (diff != 0) return diff;
      return a.personName.toLowerCase().compareTo(b.personName.toLowerCase());
    });
    return list;
  }

  Future<int> addDebt({
    required String personName,
    required DebtType type,
    required int amountMinor,
    required String currencyCode,
    DateTime? dueDate,
    String? note,
    int? accountId,
    bool linkCashFlow = true,
    double? interestRatePercent,
  }) async {
    final effectiveAccountId = accountId ?? financeStore.everydayAccount?.id;

    var effectiveAmount = amountMinor;
    String? fullNote = note;
    if (interestRatePercent != null && interestRatePercent > 0) {
      final interest = (amountMinor * (interestRatePercent / 100)).round();
      effectiveAmount += interest;
      fullNote = '${note != null && note.isNotEmpty ? '$note · ' : ''}Includes $interestRatePercent% interest';
    }

    final debtId = await debtRepo.add(
      personName: personName,
      type: type,
      amountMinor: effectiveAmount,
      currencyCode: currencyCode,
      dueDate: dueDate,
      note: fullNote,
      accountId: effectiveAccountId,
    );

    // Connect to cash flow in Everyday account
    if (linkCashFlow && effectiveAccountId != null) {
      if (type == DebtType.lent) {
        final currentBalance = financeStore.snapshot.balanceOf(effectiveAccountId);
        if (currentBalance < amountMinor) {
          throw StateError('Insufficient balance in Everyday account to lend this amount.');
        }
        // Lent money: Outflow from Everyday account
        await transactionRepo.add(
          accountId: effectiveAccountId,
          type: TransactionType.expense,
          amountMinor: amountMinor,
          category: 'Lending',
          note: 'Lent to $personName',
          occurredAt: DateTime.now(),
        );
      } else {
        // Borrowed money: Inflow into Everyday account
        await transactionRepo.add(
          accountId: effectiveAccountId,
          type: TransactionType.income,
          amountMinor: amountMinor,
          category: 'Borrowing',
          note: 'Borrowed from $personName',
          occurredAt: DateTime.now(),
        );
      }
    }

    if (dueDate != null) {
      ShiftNotificationService.instance.scheduleDebtReminder(
        debtId: debtId,
        partyName: personName,
        amountMinor: effectiveAmount,
        currencyCode: currencyCode,
        dueDate: dueDate,
        isLent: type == DebtType.lent,
      );
    }

    return debtId;
  }

  /// Records partial payment or full settlement, with cash flow tracking
  Future<void> recordPayment({
    required Debt debt,
    required int paymentMinor,
    bool linkCashFlow = true,
  }) async {
    if (paymentMinor <= 0) return;

    final origMinor = debt.originalAmountMinor;
    final currentPaid = debt.paidAmountMinor;
    final remainingMinor = debt.remainingAmountMinor;

    // Clamp payment so it never exceeds remaining balance!
    // Prevents overcharging the user's cash flow and prevents invalid state.
    final effectivePayment = paymentMinor.clamp(1, remainingMinor);
    final newPaidMinor = currentPaid + effectivePayment;
    final newRemainingMinor = (origMinor - newPaidMinor).clamp(0, origMinor);
    final isFullSettlement = newRemainingMinor <= 0;

    final effectiveAccountId = debt.accountId ?? financeStore.everydayAccount?.id;

    // Connect repayment to cash flow
    if (linkCashFlow && effectiveAccountId != null) {
      if (debt.type == DebtType.lent.value) {
        // Lent money repaid: Inflow into Everyday
        await transactionRepo.add(
          accountId: effectiveAccountId,
          type: TransactionType.income,
          amountMinor: effectivePayment,
          category: 'Debt Repayment',
          note: 'Repayment from ${debt.personName}',
          occurredAt: DateTime.now(),
        );
      } else {
        // Borrowed money repaid: Outflow from Everyday
        await transactionRepo.add(
          accountId: effectiveAccountId,
          type: TransactionType.expense,
          amountMinor: effectivePayment,
          category: 'Debt Repayment',
          note: 'Repayment to ${debt.personName}',
          occurredAt: DateTime.now(),
        );
      }
    }

    final nowFormatted = DateFormat('MMM d').format(DateTime.now());
    final paymentLog = 'Paid ${(effectivePayment / 100).toStringAsFixed(2)} on $nowFormatted';
    final updatedNote = DebtPaymentDetails.formatNoteWithMetadata(
      existingNote: debt.cleanNote,
      originalAmountMinor: origMinor,
      paidAmountMinor: newPaidMinor,
      logText: paymentLog,
    );

    if (isFullSettlement) {
      await debtRepo.update(
        debt.id,
        personName: debt.personName,
        type: DebtType.fromValue(debt.type),
        amountMinor: origMinor,
        currencyCode: debt.currencyCode,
        dueDate: debt.dueDate != null ? DateTime.fromMillisecondsSinceEpoch(debt.dueDate!) : null,
        note: updatedNote,
        accountId: debt.accountId,
      );
      await debtRepo.settle(debt.id);
      ShiftNotificationService.instance.cancelNotification(30000 + (debt.id % 50000));
    } else {
      await debtRepo.update(
        debt.id,
        personName: debt.personName,
        type: DebtType.fromValue(debt.type),
        amountMinor: newRemainingMinor,
        currencyCode: debt.currencyCode,
        dueDate: debt.dueDate != null ? DateTime.fromMillisecondsSinceEpoch(debt.dueDate!) : null,
        note: updatedNote,
        accountId: debt.accountId,
      );
    }
  }

  /// Settles all active debts with a specific party in one go
  Future<void> settleParty(String personName, {bool linkCashFlow = true}) async {
    final partyDebts = financeStore.debts.where(
      (d) =>
          d.personName.trim().toLowerCase() == personName.trim().toLowerCase() &&
          !d.isSettled,
    ).toList();
    for (final debt in partyDebts) {
      await settleDebt(debt.id, linkCashFlow: linkCashFlow);
    }
  }

  Future<void> settleDebt(int id, {bool linkCashFlow = true}) async {
    final debt = financeStore.debts.where((d) => d.id == id).firstOrNull;
    if (debt != null) {
      await recordPayment(debt: debt, paymentMinor: debt.amountMinor, linkCashFlow: linkCashFlow);
    } else {
      await debtRepo.settle(id);
    }
    ShiftNotificationService.instance.cancelNotification(30000 + (id % 50000));
  }

  Future<void> unsettleDebt(int id) => debtRepo.unsettle(id);

  Future<void> deleteDebt(int id) {
    ShiftNotificationService.instance.cancelNotification(30000 + (id % 50000));
    return debtRepo.delete(id);
  }

  Future<void> updateDebt(
    int id, {
    required String personName,
    required DebtType type,
    required int amountMinor,
    required String currencyCode,
    DateTime? dueDate,
    String? note,
    int? accountId,
  }) {
    return debtRepo.update(
      id,
      personName: personName,
      type: type,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      dueDate: dueDate,
      note: note,
      accountId: accountId,
    );
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
