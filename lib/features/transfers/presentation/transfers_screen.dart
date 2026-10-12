import 'package:flutter/material.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/account_repository.dart';
import 'package:finance_tracker/features/transfers/data/transfer_repository.dart';
import 'package:finance_tracker/features/transfers/domain/transfer_draft.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountRepository = getIt<AccountRepository>();
    final transferRepository = getIt<TransferRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Transfers')),
      floatingActionButton: StreamBuilder<List<Account>>(
        stream: accountRepository.watchAccounts(),
        builder: (context, snapshot) {
          final accounts = (snapshot.data ?? const <Account>[])
              .where((account) => !account.isArchived)
              .toList();
          return FloatingActionButton.extended(
            onPressed: !_hasCompatibleAccountPair(accounts)
                ? null
                : () => _showTransferForm(context, accounts, transferRepository),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Transfer money'),
          );
        },
      ),
      body: StreamBuilder<List<Account>>(
        stream: accountRepository.watchAccounts(),
        builder: (context, accountSnapshot) {
          final accounts = accountSnapshot.data ?? const <Account>[];
          final accountById = {for (final account in accounts) account.id: account};

          return StreamBuilder(
            stream: transferRepository.watchTransfers(),
            builder: (context, transferSnapshot) {
              final transfers = transferSnapshot.data ?? const [];

              if (accountSnapshot.hasError || transferSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load transfers: ${accountSnapshot.error ?? transferSnapshot.error}',
                  ),
                );
              }
              if ((accountSnapshot.connectionState == ConnectionState.waiting &&
                      !accountSnapshot.hasData) ||
                  (transferSnapshot.connectionState == ConnectionState.waiting &&
                      !transferSnapshot.hasData)) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!_hasCompatibleAccountPair(accounts)) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 44, color: theme.colorScheme.primary),
                        const SizedBox(height: 14),
                        Text('Two accounts needed', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Create at least two active accounts with the same currency in Money. Transfers do not count as income or expense.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (transfers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 44, color: theme.colorScheme.primary),
                        const SizedBox(height: 14),
                        Text('No transfers yet', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Move money between your own accounts without changing your total wealth.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: transfers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final transfer = transfers[index];
                  final source = accountById[transfer.sourceAccountId];
                  final destination = accountById[transfer.destinationAccountId];
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
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(Icons.swap_horiz_rounded,
                              color: theme.colorScheme.onSecondaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${source?.name ?? 'Deleted account'} → ${destination?.name ?? 'Deleted account'}',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(DateTime.fromMillisecondsSinceEpoch(
                                  transfer.occurredAt,
                                )),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (transfer.note?.isNotEmpty == true) ...[
                                const SizedBox(height: 3),
                                Text(
                                  transfer.note!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatMoney(
                                transfer.amountMinor,
                                source?.currencyCode ?? 'NPR',
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Transfer actions',
                              onSelected: (value) async {
                                if (value != 'delete') return;
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete transfer?'),
                                    content: const Text(
                                      'The account balances will be recalculated without this transfer.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  await transferRepository.deleteTransfer(transfer.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showTransferForm(
    BuildContext context,
    List<Account> accounts,
    TransferRepository repository,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _TransferForm(accounts: accounts, repository: repository),
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

class _TransferForm extends StatefulWidget {
  const _TransferForm({required this.accounts, required this.repository});

  final List<Account> accounts;
  final TransferRepository repository;

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late int _sourceId = _sourceOptions.first.id;
  late int _destinationId = _destinations.first.id;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<Account> get _sourceOptions => widget.accounts
      .where((source) => widget.accounts.any(
            (other) =>
                other.id != source.id &&
                other.currencyCode == source.currencyCode,
          ))
      .toList();

  List<Account> get _destinations => widget.accounts
      .where((account) =>
          account.id != _sourceId &&
          account.currencyCode ==
              widget.accounts.firstWhere((account) => account.id == _sourceId).currencyCode)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amountText = _amountController.text.trim();
    final amount = double.parse(amountText);
    setState(() => _saving = true);
    try {
      await widget.repository.createTransfer(
        TransferDraft(
          sourceAccountId: _sourceId,
          destinationAccountId: _destinationId,
          amountMinor: (amount * 100).round(),
          occurredAt: _date,
          note: _noteController.text,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save transfer: $error')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final destinations = _destinations;
    if (!destinations.any((account) => account.id == _destinationId)) {
      _destinationId = destinations.first.id;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transfer money', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Move money between accounts in the same currency. This will not be recorded as income or expense.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                initialValue: _sourceId,
                decoration: const InputDecoration(labelText: 'From account'),
                items: _sourceOptions
                    .map((account) => DropdownMenuItem(
                          value: account.id,
                          child: Text('${account.name} · ${account.currencyCode}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _sourceId = value;
                    final destinations = _destinations;
                    if (destinations.isNotEmpty &&
                        !destinations.any((account) => account.id == _destinationId)) {
                      _destinationId = destinations.first.id;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                key: ValueKey('destination-$_sourceId'),
                initialValue: _destinationId,
                decoration: const InputDecoration(labelText: 'To account'),
                items: destinations
                    .map((account) => DropdownMenuItem(
                          value: account.id,
                          child: Text('${account.name} · ${account.currencyCode}'),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _destinationId = value ?? _destinationId),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  final amount = double.tryParse(text);
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Enter an amount greater than zero';
                  }
                  if (amount > 999999999999 ||
                      (text.contains('.') && text.split('.').last.length > 2)) {
                    return 'Use a valid amount with up to 2 decimal places';
                  }
                  return null;
                },
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
                  hintText: 'Why are you moving this money?',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving || destinations.isEmpty ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_saving ? 'Saving…' : 'Save transfer'),
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


bool _hasCompatibleAccountPair(List<Account> accounts) {
  final activeAccounts = accounts.where((account) => !account.isArchived);
  return activeAccounts.any(
    (source) => activeAccounts.any(
      (destination) =>
          destination.id != source.id &&
          destination.currencyCode == source.currencyCode,
    ),
  );
}
