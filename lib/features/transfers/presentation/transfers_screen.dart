import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/transfers/data/transfer_repository.dart';
import 'package:finance_tracker/features/transfers/domain/transfer_draft.dart';

class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.strings;
    final accountRepository = getIt<AccountRepository>();
    final transferRepository = getIt<TransferRepository>();

    return Scaffold(
      appBar: AppTopBar(
        title: tr.transfer,
        actions: [
          StreamBuilder<List<Account>>(
            stream: accountRepository.watchAccounts(),
            builder: (context, snapshot) {
              final accounts = (snapshot.data ?? const <Account>[])
                  .where((account) => !account.isArchived)
                  .toList();
              if (!_hasCompatibleAccountPair(accounts)) {
                return const SizedBox.shrink();
              }
              return TopBarAction(
                HugeIcons.strokeRoundedPlusSign,
                tooltip: tr.transfer,
                onPressed: () => _showTransferForm(context, accounts, transferRepository),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Account>>(
          stream: accountRepository.watchAccounts(),
          builder: (context, accountSnapshot) {
            final accounts = accountSnapshot.data ?? const <Account>[];
            final activeAccounts = accounts.where((a) => !a.isArchived).toList();
            final accountById = {for (final account in accounts) account.id: account};

            return StreamBuilder(
              stream: transferRepository.watchTransfers(),
              builder: (context, transferSnapshot) {
                final transfers = transferSnapshot.data ?? const [];

                if (accountSnapshot.hasError || transferSnapshot.hasError) {
                  return EmptyState(
                    illustration: EmptyIllustration.accounts,
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    title: tr.couldNotSave('${accountSnapshot.error ?? transferSnapshot.error}'),
                    message: tr.t(
                      'Please try again in a moment.',
                      ne: 'कृपया केही समयपछि पुनः प्रयास गर्नुहोस्।',
                      hi: 'कृपया थोड़ी देर बाद फिर से प्रयास करें।',
                      es: 'Inténtalo de nuevo en un momento.',
                      fr: 'Veuillez réessayer dans un instant.',
                      de: 'Bitte versuche es gleich erneut.',
                      ja: 'しばらくしてからもう一度お試しください。',
                      zh: '请稍后再试。',
                      it: 'Riprova tra poco.',
                    ),
                  );
                }
                if ((accountSnapshot.connectionState == ConnectionState.waiting &&
                        !accountSnapshot.hasData) ||
                    (transferSnapshot.connectionState == ConnectionState.waiting &&
                        !transferSnapshot.hasData)) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!_hasCompatibleAccountPair(activeAccounts)) {
                  return EmptyState(
                    illustration: EmptyIllustration.accounts,
                    icon: HugeIcons.strokeRoundedCoinsSwap,
                    title: tr.t(
                      'Two accounts needed',
                      ne: 'कम्तिमा दुई खाता आवश्यक छ',
                      hi: 'कम से कम दो खाते आवश्यक हैं',
                      es: 'Se necesitan dos cuentas',
                      fr: 'Deux comptes requis',
                      de: 'Zwei Konten erforderlich',
                      ja: '2つの口座が必要です',
                      zh: '至少需要两个账户',
                      it: 'Servono due conti',
                    ),
                    message: tr.t(
                      'Create at least two active accounts to move money between them without affecting net worth.',
                      ne: 'कुल सम्पत्ति नबदली रकम सार्न कम्तिमा दुई सक्रिय खाता बनाउनुहोस्।',
                      hi: 'कुल संपत्ति बदले बिना पैसे ट्रांसफर करने के लिए कम से कम दो सक्रिय खाते बनाएं।',
                      es: 'Crea al menos dos cuentas activas para mover dinero entre ellas sin cambiar tu patrimonio.',
                      fr: 'Créez au moins deux comptes actifs pour transférer de l\'argent entre eux.',
                      de: 'Erstelle mindestens zwei aktive Konten für Überträge.',
                      ja: '口座間で資金を移動するには、有効な口座を2つ以上作成してください。',
                      zh: '创建至少两个活跃账户以在账户间转账，不影响总资产。',
                      it: 'Crea almeno due conti attivi per trasferire denaro tra di essi.',
                    ),
                    actionLabel: tr.addAccount,
                    onAction: () => context.push(AppRoutes.addAccount),
                  );
                }
                if (transfers.isEmpty) {
                  return EmptyState(
                    illustration: EmptyIllustration.transactions,
                    icon: HugeIcons.strokeRoundedCoinsSwap,
                    title: tr.t(
                      'No transfers yet',
                      ne: 'अहिलेसम्म कुनै ट्रान्सफर छैन',
                      hi: 'अभी तक कोई ट्रांसफर नहीं',
                      es: 'Aún no hay transferencias',
                      fr: 'Aucun transfert pour l\'instant',
                      de: 'Noch keine Überträge',
                      ja: 'まだ振替履歴はありません',
                      zh: '暂无转账记录',
                      it: 'Nessun trasferimento ancora',
                    ),
                    message: tr.t(
                      'Move money between your own accounts without changing your total wealth.',
                      ne: 'तपाईंको कुल सम्पत्ति नबदली आफ्ना खाताहरू बीच रकम सार्नुहोस्।',
                      hi: 'अपनी कुल संपत्ति बदले बिना अपने खातों के बीच पैसे ट्रांसफर करें।',
                      es: 'Mueve dinero entre tus propias cuentas sin cambiar tu patrimonio total.',
                      fr: 'Déplacez de l\'argent entre vos comptes sans modifier votre patrimoine.',
                      de: 'Bewege Geld zwischen deinen Konten, ohne dein Gesamtvermögen zu verändern.',
                      ja: '総資産を変えずに自分の口座間で資金を移動できます。',
                      zh: '在您自己的账户之间划转资金，不会改变总资产。',
                      it: 'Sposta denaro tra i tuoi conti senza cambiare il patrimonio totale.',
                    ),
                    actionLabel: tr.transfer,
                    onAction: () => _showTransferForm(context, activeAccounts, transferRepository),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.xxxl),
                  itemCount: transfers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpace.sm),
                  itemBuilder: (context, index) {
                    final transfer = transfers[index];
                    final source = accountById[transfer.sourceAccountId];
                    final destination = accountById[transfer.destinationAccountId];
                    return AppCard(
                      padding: const EdgeInsets.all(AppSpace.md),
                      child: Row(
                        children: [
                          const IconTile(HugeIcons.strokeRoundedCoinsSwap, size: 42),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${source?.name ?? 'Account'} → ${destination?.name ?? 'Account'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
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
                          const SizedBox(width: AppSpace.sm),
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
                                final confirmed = await showConfirmDialog(
                                  context,
                                  title: tr.t(
                                    'Delete transfer?',
                                    ne: 'ट्रान्सफर मेटाउने?',
                                    hi: 'ट्रांसफर हटाएं?',
                                    es: '¿Eliminar transferencia?',
                                    fr: 'Supprimer le transfert ?',
                                    de: 'Übertrag löschen?',
                                    ja: '振替を削除しますか？',
                                    zh: '删除这笔转账？',
                                    it: 'Eliminare il trasferimento?',
                                  ),
                                  message: tr.t(
                                    'Account balances will be recalculated without this transfer.',
                                    ne: 'यो ट्रान्सफर बिना खाताको मौज्दात पुनः गणना गरिनेछ।',
                                    hi: 'इस ट्रांसफर के बिना खाते का शेष फिर से गणना किया जाएगा।',
                                    es: 'Los saldos de las cuentas se recalcularán sin esta transferencia.',
                                    fr: 'Les soldes des comptes seront recalculés sans ce transfert.',
                                    de: 'Die Kontostände werden ohne diesen Übertrag neu berechnet.',
                                    ja: 'この振替を除いて口座残高が再計算されます。',
                                    zh: '删除后将重新计算相关账户余额。',
                                    it: 'I saldi dei conti verranno ricalcolati senza questo trasferimento.',
                                  ),
                                  confirmLabel: tr.delete,
                                  cancelLabel: tr.cancel,
                                  destructive: true,
                                );
                                if (confirmed && context.mounted) {
                                  await transferRepository.deleteTransfer(transfer.id);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(tr.delete),
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
      ),
    );
  }

  Future<void> _showTransferForm(
    BuildContext context,
    List<Account> accounts,
    TransferRepository repository,
  ) =>
      showTransferFormModal(context, accounts: accounts, repository: repository);

  static String _formatMoney(int minorUnits, String currencyCode) {
    final amount = minorUnits.abs();
    final major = amount ~/ 100;
    final minor = (amount % 100).toString().padLeft(2, '0');
    return '$currencyCode $major.$minor';
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Future<void> showTransferFormModal(
  BuildContext context, {
  List<Account>? accounts,
  TransferRepository? repository,
}) async {
  final accRepo = getIt<AccountRepository>();
  final txRepo = repository ?? getIt<TransferRepository>();
  final activeAccounts = (accounts != null && accounts.isNotEmpty)
      ? accounts.where((account) => !account.isArchived).toList()
      : (await accRepo.getAll())
          .where((account) => !account.isArchived)
          .toList();

  if (!_hasCompatibleAccountPair(activeAccounts)) {
    if (context.mounted) {
      showToast(context, 'You need at least two accounts to transfer money.');
    }
    return;
  }

  if (context.mounted) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => TransferForm(accounts: activeAccounts, repository: txRepo),
    );
  }
}

class TransferForm extends StatefulWidget {
  const TransferForm({super.key, required this.accounts, required this.repository});

  final List<Account> accounts;
  final TransferRepository repository;

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late int _sourceId;
  late int _destinationId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final sources = _sourceOptions;
    if (sources.isNotEmpty) {
      _sourceId = sources.first.id;
      final destinations = _destinationsFor(_sourceId);
      _destinationId = destinations.isNotEmpty ? destinations.first.id : 0;
    } else {
      _sourceId = widget.accounts.isNotEmpty ? widget.accounts.first.id : 0;
      _destinationId = 0;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<Account> get _sourceOptions =>
      widget.accounts.where((account) => !account.isArchived).toList();

  List<Account> _destinationsFor(int sourceId) {
    return widget.accounts
        .where((account) => !account.isArchived && account.id != sourceId)
        .toList();
  }

  List<Account> get _destinations => _destinationsFor(_sourceId);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceId == 0 || _destinationId == 0 || _sourceId == _destinationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two different accounts.')),
      );
      return;
    }
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
      if (mounted) {
        showToast(context, 'Transfer completed');
        Navigator.of(context).pop();
      }
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
    if (destinations.isNotEmpty && !destinations.any((account) => account.id == _destinationId)) {
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
              Text(
                'From account',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sourceOptions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final acc = _sourceOptions[index];
                    final isSelected = acc.id == _sourceId;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _sourceId = acc.id;
                            final destinations = _destinations;
                            if (destinations.isNotEmpty &&
                                !destinations.any((account) => account.id == _destinationId)) {
                              _destinationId = destinations.first.id;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.name,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    acc.currencyCode,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'To account',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: destinations.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final acc = destinations[index];
                    final isSelected = acc.id == _destinationId;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _destinationId = acc.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.move_to_inbox_outlined,
                                size: 18,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.name,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    acc.currencyCode,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
              AppButton(
                'Save transfer',
                loading: _saving,
                onPressed: _saving || destinations.isEmpty ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


bool _hasCompatibleAccountPair(List<Account> accounts) {
  final activeAccounts = accounts.where((account) => !account.isArchived).toList();
  return activeAccounts.length >= 2;
}
