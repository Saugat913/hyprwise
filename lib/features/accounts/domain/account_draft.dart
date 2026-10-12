import 'account_type.dart';

/// Validated values used to create or edit an account.
class AccountDraft {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.currencyCode,
  });

  final String name;
  final AccountType type;
  final int openingBalanceMinor;
  final String currencyCode;
}
