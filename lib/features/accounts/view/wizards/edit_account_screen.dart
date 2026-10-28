import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key, required this.accountId});

  final int accountId;

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late final TextEditingController _nameController;
  late AccountType _type;

  @override
  void initState() {
    super.initState();
    final viewModel = getIt<AccountsViewModel>();
    final account = viewModel.accounts.firstWhere(
      (a) => a.id == widget.accountId,
      orElse: () => viewModel.accounts.first,
    );
    _nameController = TextEditingController(text: account.name);
    _type = AccountType.fromValue(account.type);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AccountsViewModel>();
    final account = viewModel.accounts.firstWhere(
      (a) => a.id == widget.accountId,
      orElse: () => viewModel.accounts.first,
    );
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final balanceMinor = viewModel.balanceOf(account.id);

    return Scaffold(
      appBar: AppTopBar(
        title: account.name,
        subtitle: tr.editAccountDetails,
        actions: [
          TopBarAction(
            HugeIcons.strokeRoundedDelete02,
            tooltip: tr.deleteAccount,
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: tr.t('Delete ${account.name}?', ne: '${account.name} मेटाउने?', es: '¿Eliminar ${account.name}?', fr: 'Supprimer ${account.name} ?', de: '${account.name} löschen?', ja: '${account.name}を削除しますか？', zh: '确定删除 ${account.name}？', it: 'Eliminare ${account.name}?'),
                message: tr.t(
                  'Its transactions stay in your history but are no longer linked to an account.',
                  ne: 'यसका कारोबारहरू इतिहासमा रहनेछन् तर कुनै खातासँग जोडिने छैनन्।',
                  es: 'Sus transacciones permanecerán en el historial pero ya no estarán vinculadas a una cuenta.',
                  fr: 'Ses transactions restent dans votre historique mais ne sont plus liées à un compte.',
                  de: 'Die Transaktionen bleiben im Verlauf, sind aber nicht mehr verknüpft.',
                  ja: '過去の取引履歴は残りますが、口座との紐付けは解除されます。',
                  zh: '其交易记录将保留在明细中，但不再关联此账户。',
                  it: 'Le transazioni rimarranno nella cronologia ma non saranno più collegate a un conto.',
                ),
                confirmLabel: tr.deleteAccount,
                cancelLabel: tr.cancel,
              );
              if (confirmed && context.mounted) {
                await viewModel.deleteAccount(widget.accountId);
                if (context.mounted) {
                  showToast(context, tr.accountDeleted);
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.page),
          children: [
            UnderlineField(
              label: tr.accountName,
              controller: _nameController,
            ),
            const SizedBox(height: AppSpace.xl),

            Text(tr.type, style: text.bodySmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                for (final t in AccountType.values)
                  ChoicePill(
                    t.localizedLabel(tr),
                    selected: _type == t,
                    onTap: () => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.balance, style: text.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    MoneyFormatter.format(balanceMinor, account.currencyCode),
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    tr.t(
                      'Changing the balance adds an adjustment to your history.',
                      ne: 'मौज्दात परिवर्तन गर्दा इतिहासमा समायोजन थपिनेछ।',
                      es: 'Cambiar el saldo añade un ajuste a tu historial.',
                      fr: 'Modifier le solde ajoute un ajustement à votre historique.',
                      de: 'Eine Änderung des Saldos fügt eine Korrekturbuchung hinzu.',
                      ja: '残高を変更すると履歴に残高調整が記録されます。',
                      zh: '调整余额将在历史明细中记录一笔平账微调。',
                      it: 'Modificare il saldo aggiunge una rettifica alla cronologia.',
                    ),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),

            AppCard(
              child: Row(
                children: [
                  Text(tr.currency, style: text.bodyMedium),
                  const Spacer(),
                  Text(account.currencyCode, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                tr.saveChanges,
                onPressed: () async {
                  await viewModel.updateAccount(
                    widget.accountId,
                    name: _nameController.text.trim(),
                    type: _type,
                  );
                  if (context.mounted) {
                    showToast(context, tr.accountUpdated);
                    context.pop();
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                tr.deleteAccount,
                kind: AppButtonKind.danger,
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: tr.t('Delete ${account.name}?', ne: '${account.name} मेटाउने?', es: '¿Eliminar ${account.name}?', fr: 'Supprimer ${account.name} ?', de: '${account.name} löschen?', ja: '${account.name}を削除しますか？', zh: '确定删除 ${account.name}？', it: 'Eliminare ${account.name}?'),
                    message: tr.t(
                      'Its transactions stay in your history but are no longer linked to an account.',
                      ne: 'यसका कारोबारहरू इतिहासमा रहनेछन् तर कुनै खातासँग जोडिने छैनन्।',
                      es: 'Sus transacciones permanecerán en el historial pero ya no estarán vinculadas a una cuenta.',
                      fr: 'Ses transactions restent dans votre historique mais ne sont plus liées à un compte.',
                      de: 'Die Transaktionen bleiben im Verlauf, sind aber nicht mehr verknüpft.',
                      ja: '過去の取引履歴は残りますが、口座との紐付けは解除されます。',
                      zh: '其交易记录将保留在明细中，但不再关联此账户。',
                      it: 'Le transazioni rimarranno nella cronologia ma non saranno più collegate a un conto.',
                    ),
                    confirmLabel: tr.deleteAccount,
                    cancelLabel: tr.cancel,
                  );
                  if (confirmed && context.mounted) {
                    await viewModel.deleteAccount(widget.accountId);
                    if (context.mounted) {
                      showToast(context, tr.accountDeleted);
                      context.pop();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
