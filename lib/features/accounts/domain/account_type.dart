/// Account types available in the first version of Finance Planner.
enum AccountType {
  cash('cash', 'Cash'),
  bank('bank', 'Bank account'),
  savings('savings', 'Savings'),
  credit('credit', 'Credit account'),
  investment('investment', 'Investment'),
  other('other', 'Other');

  const AccountType(this.value, this.label);

  final String value;
  final String label;

  static AccountType fromValue(String value) => AccountType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => AccountType.other,
  );
}
