import 'package:finance_tracker/core/l10n/app_strings.dart';

/// Account types.
enum AccountType {
  cash('cash', 'Cash'),
  bank('bank', 'Bank account'),
  wallet('wallet', 'Wallet'),
  savings('savings', 'Savings');

  const AccountType(this.value, this.label);

  final String value;
  final String label;

  String localizedLabel(AppStrings tr) => switch (this) {
        AccountType.cash => tr.cash,
        AccountType.bank => tr.everydayAccount,
        AccountType.wallet => tr.digitalWallet,
        AccountType.savings => tr.savingsAccount,
      };

  static AccountType fromValue(String value) => AccountType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => AccountType.bank,
  );
}
