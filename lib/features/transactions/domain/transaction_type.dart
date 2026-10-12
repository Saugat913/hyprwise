enum TransactionType {
  income('income', 'Income'),
  expense('expense', 'Expense');

  const TransactionType(this.value, this.label);

  final String value;
  final String label;

  static TransactionType fromValue(String value) => TransactionType.values
      .firstWhere(
        (type) => type.value == value,
        orElse: () => TransactionType.expense,
      );
}
