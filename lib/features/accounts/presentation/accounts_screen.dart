import 'package:flutter/material.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/account_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account_draft.dart';
import 'package:finance_tracker/features/accounts/domain/account_type.dart';
import 'package:hugeicons/hugeicons.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = getIt<AccountRepository>();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Account>>(
          stream: repository.watchAccounts(),
          builder: (context, snapshot) {
            final accounts = snapshot.data ?? const <Account>[];
            final totalMinor = accounts
                .where((account) => account.currencyCode == 'NPR')
                .fold<int>(0, (sum, account) => sum + account.openingBalanceMinor);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your money', style: theme.textTheme.headlineMedium),
                              const SizedBox(height: 6),
                              Text(
                                'Accounts and balances',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Add account',
                          onPressed: () => _showAccountForm(context, repository),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opening balances · NPR',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatMoney(totalMinor, 'NPR'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transactions will contribute to current balances in the next step.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(child: Text('Accounts', style: theme.textTheme.titleLarge)),
                        Text('${accounts.length}', style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
                if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Could not load accounts: ${snapshot.error}')),
                  )
                else if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (accounts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text('Start with an account', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Add cash, a bank account, or savings to establish your starting financial position.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _showAccountForm(context, repository),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add first account'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final type = AccountType.fromValue(account.type);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedBanknote,
                                  color: theme.colorScheme.onSecondaryContainer,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(account.name, style: theme.textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${type.label} · ${account.currencyCode}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatMoney(account.openingBalanceMinor, account.currencyCode),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAccountForm(
    BuildContext context,
    AccountRepository repository,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _AccountForm(repository: repository),
    );
  }

  static String _formatMoney(int minorUnits, String currencyCode) {
    final amount = minorUnits.abs();
    final major = amount ~/ 100;
    final minor = (amount % 100).toString().padLeft(2, '0');
    final sign = minorUnits < 0 ? '−' : '';
    return '$sign$currencyCode $major.$minor';
  }
}

class _AccountForm extends StatefulWidget {
  const _AccountForm({required this.repository});

  final AccountRepository repository;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');
  AccountType _type = AccountType.bank;
  String _currencyCode = 'NPR';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.parse(_balanceController.text.trim());
    final minorUnits = (parsed.abs() * 100).round() * (parsed < 0 ? -1 : 1);

    setState(() => _saving = true);
    try {
      await widget.repository.createAccount(
        AccountDraft(
          name: _nameController.text,
          type: _type,
          openingBalanceMinor: minorUnits,
          currencyCode: _currencyCode,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save account: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add account', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Enter the account details and its starting balance.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Account name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter an account name';
                  if (value.trim().length > 80) return 'Use 80 characters or fewer';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AccountType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Account type'),
                items: AccountType.values
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _currencyCode,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: const [
                  DropdownMenuItem(value: 'NPR', child: Text('NPR · Nepalese rupee')),
                  DropdownMenuItem(value: 'USD', child: Text('USD · US dollar')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR · Euro')),
                  DropdownMenuItem(value: 'INR', child: Text('INR · Indian rupee')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP · Pound sterling')),
                ],
                onChanged: (value) => setState(() => _currencyCode = value ?? _currencyCode),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Opening balance',
                  hintText: '0.00',
                  helperText: 'Use a negative amount for an account that starts in debt.',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  final amount = double.tryParse(text);
                  if (amount == null || !amount.isFinite) return 'Enter a valid amount';
                  if (amount.abs() > 999999999999) return 'Amount is too large';
                  if (text.contains('.') && text.split('.').last.length > 2) {
                    return 'Use no more than 2 decimal places';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_saving ? 'Saving…' : 'Save account'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
