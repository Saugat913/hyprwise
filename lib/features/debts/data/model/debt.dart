import 'package:finance_tracker/core/database/app_database.dart';

enum DebtType {
  lent('lent', 'Lent (They owe me)'),
  borrowed('borrowed', 'Borrowed (I owe them)');

  const DebtType(this.value, this.label);
  final String value;
  final String label;

  static DebtType fromValue(String value) =>
      DebtType.values.firstWhere((t) => t.value == value, orElse: () => DebtType.lent);
}

extension DebtPaymentDetails on Debt {
  static final RegExp _metaRegex = RegExp(r'\[meta:orig=(\d+),paid=(\d+)\]');

  /// Original principal amount in minor units (cents)
  int get originalAmountMinor {
    final n = note;
    if (n != null) {
      final match = _metaRegex.firstMatch(n);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? amountMinor;
      }
    }
    return isSettled ? (amountMinor > 0 ? amountMinor : 0) : amountMinor;
  }

  /// Cumulative amount paid so far in minor units (cents)
  int get paidAmountMinor {
    if (isSettled) return originalAmountMinor;
    final n = note;
    if (n != null) {
      final match = _metaRegex.firstMatch(n);
      if (match != null) {
        return int.tryParse(match.group(2)!) ?? 0;
      }
    }
    return 0;
  }

  /// Remaining unpaid balance
  int get remainingAmountMinor {
    if (isSettled) return 0;
    return amountMinor;
  }

  /// Repayment progress ratio from 0.0 to 1.0
  double get repaymentProgress {
    final orig = originalAmountMinor;
    if (orig <= 0) return 0.0;
    return (paidAmountMinor / orig).clamp(0.0, 1.0);
  }

  /// Clean user-facing note without internal metadata tags
  String get cleanNote {
    final n = note;
    if (n == null || n.isEmpty) return '';
    return n.replaceAll(_metaRegex, '').trim();
  }

  /// Helper to format a note preserving original and paid amounts
  static String formatNoteWithMetadata({
    required String? existingNote,
    required int originalAmountMinor,
    required int paidAmountMinor,
    String? logText,
  }) {
    final clean = (existingNote ?? '').replaceAll(_metaRegex, '').trim();
    final tag = '[meta:orig=$originalAmountMinor,paid=$paidAmountMinor]';
    final parts = <String>[tag];
    if (clean.isNotEmpty) parts.add(clean);
    if (logText != null && logText.isNotEmpty) parts.add(logText);
    return parts.join(' · ');
  }
}

/// Represents the aggregated status and history for a specific counterparty/person.
class DebtPartySummary {
  const DebtPartySummary({
    required this.personName,
    required this.debts,
    required this.totalLentMinor,
    required this.totalBorrowedMinor,
    required this.currencyCode,
  });

  final String personName;
  final List<Debt> debts;
  final int totalLentMinor;
  final int totalBorrowedMinor;
  final String currencyCode;

  List<Debt> get activeDebts => debts.where((d) => !d.isSettled).toList();
  List<Debt> get settledDebts => debts.where((d) => d.isSettled).toList();

  /// Net balance with this party:
  /// Positive: They owe you net (Receivable)
  /// Negative: You owe them net (Payable)
  /// Zero: Settled / perfectly balanced
  int get netBalanceMinor => totalLentMinor - totalBorrowedMinor;

  bool get isNetReceivable => netBalanceMinor > 0;
  bool get isNetPayable => netBalanceMinor < 0;
  bool get isSettled => netBalanceMinor == 0 && activeDebts.isEmpty;
  int get activeCount => activeDebts.length;
}
