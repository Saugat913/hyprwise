import 'transaction_type.dart';

class TransactionCategory {
  const TransactionCategory(this.value, this.label, this.type);

  final String value;
  final String label;
  final TransactionType type;
}

/// Initial built-in categories. Keep values stable for database persistence.
abstract final class TransactionCategories {
  static const all = <TransactionCategory>[
    TransactionCategory('salary', 'Salary', TransactionType.income),
    TransactionCategory('business', 'Business', TransactionType.income),
    TransactionCategory('interest', 'Interest', TransactionType.income),
    TransactionCategory('gift_received', 'Gift received', TransactionType.income),
    TransactionCategory('other_income', 'Other income', TransactionType.income),
    TransactionCategory('food', 'Food & groceries', TransactionType.expense),
    TransactionCategory('transport', 'Transport', TransactionType.expense),
    TransactionCategory('housing', 'Housing', TransactionType.expense),
    TransactionCategory('utilities', 'Utilities', TransactionType.expense),
    TransactionCategory('health', 'Health', TransactionType.expense),
    TransactionCategory('shopping', 'Shopping', TransactionType.expense),
    TransactionCategory('education', 'Education', TransactionType.expense),
    TransactionCategory('entertainment', 'Entertainment', TransactionType.expense),
    TransactionCategory('family', 'Family', TransactionType.expense),
    TransactionCategory('other_expense', 'Other expense', TransactionType.expense),
  ];

  static List<TransactionCategory> forType(TransactionType type) =>
      all.where((category) => category.type == type).toList(growable: false);

  static TransactionCategory? find(String value, TransactionType type) {
    for (final category in all) {
      if (category.value == value && category.type == type) return category;
    }
    return null;
  }

  static TransactionCategory fromValue(String value, TransactionType type) =>
      find(value, type) ??
      (type == TransactionType.income ? all[4] : all.last);
}
