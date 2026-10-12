import 'package:flutter/material.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/account_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account_type.dart';
import 'package:finance_tracker/features/transactions/data/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_categories.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_draft.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_type.dart';
import 'package:hugeicons/hugeicons.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountRepository = getIt<AccountRepository>();
    final transactionRepository = getIt<TransactionRepository>();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Account>>(
          stream: accountRepository.watchAccounts(),
          builder: (context, accountSnapshot) {
            final accounts = accountSnapshot.data ?? const <Account>[];

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
                              Text('Transactions', style: theme.textTheme.headlineMedium),
                              const SizedBox(height: 6),
                              Text(
                                'Income and spending, in one place',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Add transaction',
                          onPressed: accounts.isEmpty
                              ? null
                              : () => _showForm(context, accounts, transactionRepository),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _filter == null,
                            onTap: () => setState(() => _filter = null),
                          ),
                          _FilterChip(
                            label: 'Income',
                            selected: _filter == TransactionType.income,
                            onTap: () => setState(() => _filter = TransactionType.income),
                          ),
                          _FilterChip(
                            label: 'Expenses',
                            selected: _filter == TransactionType.expense,
                            onTap: () => setState(() => _filter = TransactionType.expense),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (accountSnapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Could not load accounts: ${accountSnapshot.error}')),
                  )
                else if (accounts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      title: 'Add an account first',
                      message: 'Transactions belong to an account. Create one in Money to start recording activity.',
                      icon: HugeIcons.strokeRoundedWallet01,
                    ),
                  )
                else
                  StreamBuilder(
                    stream: transactionRepository.watchTransactions(type: _filter),
                    builder: (context, snapshot) {
                      final transactions = snapshot.data ?? const [];
                      final accountById = {
                        for (final account in accounts) account.id: account,
                      };

                      if (snapshot.hasError) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('Could not load transactions: ${snapshot.error}')),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (transactions.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(
                            title: 'Nothing recorded yet',
                            message: 'Add income or an expense to start understanding where your money goes.',
                            icon: HugeIcons.strokeRoundedWallet01,
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final type = TransactionType.fromValue(transaction.type);
                            final category = TransactionCategories.fromValue(
                              transaction.category,
                              type,
                            );
                            final account = accountById[transaction.accountId];
                            final color = type == TransactionType.income
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      type == TransactionType.income
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(category.label, style: theme.textTheme.titleSmall),
                                        const SizedBox(height: 3),
                                        Text(
                                          [
                                            if (account != null) account.name,
                                            _formatDate(DateTime.fromMillisecondsSinceEpoch(
                                              transaction.occurredAt,
                                            )),
                                          ].join(' · '),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if ((transaction.note as String?)?.isNotEmpty == true) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            transaction.note as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${type == TransactionType.income ? '+' : '−'}${_formatMoney(transaction.amountMinor as int, account?.currencyCode ?? 'NPR')}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Transaction actions',
                                    onSelected: (value) async {
                                      if (value != 'delete') return;
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text('Delete transaction?'),
                                          content: const Text('This record will be permanently removed.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(dialogContext, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true && context.mounted) {
                                        await transactionRepository.deleteTransaction(transaction.id as int);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    List<Account> accounts,
    TransactionRepository repository,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _TransactionForm(accounts: accounts, repository: repository),
      );

  static String _formatMoney(int minorUnits, String currencyCode) {
    final amount = minorUnits.abs();
    final major = amount ~/ 100;
    final minor = (amount % 100).toString().padLeft(2, '0');
    return '$currencyCode $major.$minor';
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final dynamic icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: icon, size: 46, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionForm extends StatefulWidget {
  const _TransactionForm({required this.accounts, required this.repository});

  final List<Account> accounts;
  final TransactionRepository repository;

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late int _accountId = widget.accounts.first.id;
  TransactionType _type = TransactionType.expense;
  late String _category = TransactionCategories.forType(_type).first.value;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final minorUnits = (amount * 100).round();

    setState(() => _saving = true);
    try {
      await widget.repository.createTransaction(
        TransactionDraft(
          accountId: _accountId,
          type: _type,
          amountMinor: minorUnits,
          category: _category,
          note: _noteController.text,
          occurredAt: _date,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save transaction: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categories = TransactionCategories.forType(_type);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add transaction', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Record money in or money out.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.north_east_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.south_west_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    _category = TransactionCategories.forType(_type).first.value;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  final amount = double.tryParse(text);
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Enter an amount greater than zero';
                  }
                  if (amount > 999999999999 || (text.contains('.') && text.split('.').last.length > 2)) {
                    return 'Use a valid amount with up to 2 decimal places';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _accountId,
                decoration: const InputDecoration(labelText: 'Account'),
                items: widget.accounts
                    .map((account) => DropdownMenuItem(
                          value: account.id,
                          child: Text('${account.name} · ${account.currencyCode}'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _accountId = value ?? _accountId),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((category) => DropdownMenuItem(
                          value: category.value,
                          child: Text(category.label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (selected != null) setState(() => _date = selected);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'What was this for?',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_saving ? 'Saving…' : 'Save transaction'),
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
