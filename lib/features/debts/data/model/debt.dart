enum DebtType {
  lent('lent', 'Lent (They owe me)'),
  borrowed('borrowed', 'Borrowed (I owe them)');

  const DebtType(this.value, this.label);
  final String value;
  final String label;

  static DebtType fromValue(String value) =>
      DebtType.values.firstWhere((t) => t.value == value, orElse: () => DebtType.lent);
}
