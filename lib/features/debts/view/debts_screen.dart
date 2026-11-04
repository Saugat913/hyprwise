import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/viewmodels/debts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

enum _DebtViewMode { byParty, allTransactions }
enum _DebtFilter { active, lent, borrowed, settled }

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final DebtsViewModel _viewModel = getIt<DebtsViewModel>();
  _DebtViewMode _viewMode = _DebtViewMode.byParty;
  _DebtFilter _filter = _DebtFilter.active;
  String? _selectedParty;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<Debt> get _filteredDebts {
    List<Debt> baseList;
    switch (_filter) {
      case _DebtFilter.active:
        baseList = _viewModel.activeDebts;
        break;
      case _DebtFilter.lent:
        baseList = _viewModel.activeDebts
            .where((d) => d.type == DebtType.lent.value)
            .toList();
        break;
      case _DebtFilter.borrowed:
        baseList = _viewModel.activeDebts
            .where((d) => d.type == DebtType.borrowed.value)
            .toList();
        break;
      case _DebtFilter.settled:
        baseList = _viewModel.settledDebts;
        break;
    }

    if (_selectedParty != null) {
      baseList = baseList
          .where((d) => d.personName.trim().toLowerCase() == _selectedParty!.trim().toLowerCase())
          .toList();
    }
    return baseList;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final isFiltered = _filter != _DebtFilter.active || _selectedParty != null;

    return Scaffold(
      appBar: AppTopBar(
        title: tr.debts,
        actions: [
          if (_viewMode == _DebtViewMode.allTransactions && isFiltered)
            TopBarAction(
              HugeIcons.strokeRoundedFilterRemove,
              tooltip: tr.resetFilters,
              onPressed: () => setState(() {
                _filter = _DebtFilter.active;
                _selectedParty = null;
              }),
            ),
          TopBarAction(
            HugeIcons.strokeRoundedPlusSign,
            tooltip: tr.addRecord,
            onPressed: () => context.push(AppRoutes.addDebt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          // Net Debt Overview Card
          _buildOverviewCard(colors, scheme, text, tr),
          const SizedBox(height: AppSpace.lg),

          // View Switcher (By Person / All History)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ViewSegmentButton(
                    label: tr.t(
                      'By Person',
                      ne: 'व्यक्ति अनुसार',
                      es: 'Por persona',
                      fr: 'Par personne',
                      de: 'Nach Person',
                      ja: '相手別',
                      zh: '按联系人',
                      it: 'Per persona',
                    ),
                    icon: HugeIcons.strokeRoundedUserGroup,
                    isSelected: _viewMode == _DebtViewMode.byParty,
                    onTap: () => setState(() => _viewMode = _DebtViewMode.byParty),
                  ),
                ),
                Expanded(
                  child: _ViewSegmentButton(
                    label: tr.t(
                      'All Transactions',
                      ne: 'सबै कारोबार',
                      es: 'Todas transacciones',
                      fr: 'Toutes transactions',
                      de: 'Alle Transaktionen',
                      ja: '全取引履歴',
                      zh: '全部借贷明细',
                      it: 'Tutte transazioni',
                    ),
                    icon: HugeIcons.strokeRoundedClock01,
                    isSelected: _viewMode == _DebtViewMode.allTransactions,
                    onTap: () => setState(() => _viewMode = _DebtViewMode.allTransactions),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Primary Content: By Person OR All Transactions
          if (_viewMode == _DebtViewMode.byParty) ...[
            if (_viewModel.partiesSummary.isEmpty)
              EmptyState(
                icon: HugeIcons.strokeRoundedMoney01,
                title: tr.noDebtRecordsFound,
                message: tr.t(
                  'Track money lent to friends or borrowed with due dates and repayments.',
                  ne: 'साथीभाइलाई दिएको वा लिएको सापटी, फिर्ता मिति र किस्ता ट्र्याक गर्नुहोस्।',
                  es: 'Controla el dinero prestado o tomado con vencimientos y pagos.',
                  fr: 'Suivez l\'argent prêté ou emprunté avec dates d\'échéance et remboursements.',
                  de: 'Verfolgen Sie geliehenes Geld mit Fälligkeitsdaten und Raten.',
                  ja: '貸し借りや返済期日、一部返済を管理できます。',
                  zh: '轻松追踪借给他人或向人借入的款项、到期日与分期还款进度。',
                  it: 'Tieni traccia di prestiti e debiti con scadenze e rimborsi.',
                ),
                actionLabel: tr.addLoanOrDebt,
                onAction: () => context.push(AppRoutes.addDebt),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _viewModel.partiesSummary.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      _buildPartyRow(
                        _viewModel.partiesSummary[i],
                        colors,
                        scheme,
                        text,
                        tr,
                      ),
                    ],
                  ],
                ),
              ),
          ] else ...[
            // Two-button Filter Bar (Status Popup + Counterparty Bottom Sheet)
            Row(
              children: [
                Expanded(
                  child: _DebtStatusFilterButton(
                    currentFilter: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _DebtPartyFilterButton(
                    selectedParty: _selectedParty,
                    existingParties: _viewModel.existingParties,
                    baseCurrency: _viewModel.baseCurrency,
                    netForParty: _viewModel.netForParty,
                    onChanged: (p) => setState(() => _selectedParty = p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),

            // Debts List
            if (_filteredDebts.isEmpty)
              EmptyState(
                icon: HugeIcons.strokeRoundedMoney01,
                title: isFiltered ? tr.noMatchingRecords : tr.noDebtRecordsFound,
                message: isFiltered
                    ? tr.t('No records match the current filter criteria.', ne: 'तपाईंले छान्नुभएको फिल्टर अनुसार कुनै रेकर्ड छैन।', es: 'No hay registros que coincidan con el filtro actual.', fr: 'Aucun enregistrement ne correspond aux critères actuels.', de: 'Keine Einträge für diese Filterkriterien gefunden.', ja: '選択した条件に一致する記録はありません。', zh: '暂无符合所选筛选条件的记录。', it: 'Nessun record corrisponde ai criteri attuali.')
                    : tr.t('Track money lent to friends or borrowed with due dates and repayments.', ne: 'साथीभाइलाई दिएको वा लिएको सापटी, फिर्ता मिति र किस्ता ट्र्याक गर्नुहोस्।', es: 'Controla el dinero prestado o tomado con vencimientos y pagos.', fr: 'Suivez l\'argent prêté ou emprunté avec dates d\'échéance et remboursements.', de: 'Verfolgen Sie geliehenes Geld mit Fälligkeitsdaten und Raten.', ja: '貸し借りや返済期日、一部返済を管理できます。', zh: '轻松追踪借给他人或向人借入的款项、到期日与分期还款进度।', it: 'Tieni traccia di prestiti e debiti con scadenze e rimborsi.'),
                actionLabel: isFiltered ? tr.resetFilters : tr.addLoanOrDebt,
                onAction: isFiltered
                    ? () => setState(() {
                        _filter = _DebtFilter.active;
                        _selectedParty = null;
                      })
                    : () => context.push(AppRoutes.addDebt),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _filteredDebts.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      _buildDebtRow(_filteredDebts[i], colors, scheme, text, tr),
                    ],
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpace.xxl),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    AppColors colors,
    ColorScheme scheme,
    TextTheme text,
    AppStrings tr,
  ) {
    final net = _viewModel.netBalanceMinor;
    final isPositive = net >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.netDebtBalance,
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
              StatusChip(
                isPositive ? tr.netReceivable : tr.netPayable,
                tone: isPositive ? ChipTone.success : ChipTone.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${isPositive ? '+' : '−'}${MoneyFormatter.format(net.abs(), _viewModel.baseCurrency)}',
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isPositive ? colors.income : colors.expense,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const RowDivider(),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(HugeIcons.strokeRoundedArrowUpRight01, size: 14, color: colors.income),
                        const SizedBox(width: 4),
                        Text(
                          tr.lentToOthers,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyFormatter.format(_viewModel.totalLentMinor, _viewModel.baseCurrency),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.income,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: scheme.outlineVariant),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(HugeIcons.strokeRoundedArrowDownLeft01, size: 14, color: colors.expense),
                        const SizedBox(width: 4),
                        Text(
                          tr.borrowedFromOthers,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyFormatter.format(_viewModel.totalBorrowedMinor, _viewModel.baseCurrency),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyRow(
    DebtPartySummary party,
    AppColors colors,
    ColorScheme scheme,
    TextTheme text,
    AppStrings tr,
  ) {
    final net = party.netBalanceMinor;
    final isReceivable = party.isNetReceivable;
    final isPayable = party.isNetPayable;
    final isSettled = party.isSettled;

    final Color statusColor = isReceivable
        ? colors.income
        : (isPayable ? colors.expense : scheme.onSurfaceVariant);

    final subtitleParts = <String>[];
    if (party.activeCount > 0) {
      subtitleParts.add(
        '${party.activeCount} active ${party.activeCount == 1 ? (tr.isNepali ? "रेकर्ड" : "loan") : (tr.isNepali ? "रेकर्डहरू" : "loans")}',
      );
    } else {
      subtitleParts.add(tr.settled);
    }
    if (party.totalLentMinor > 0 && party.totalBorrowedMinor > 0) {
      subtitleParts.add(
        'Lent: ${MoneyFormatter.format(party.totalLentMinor, party.currencyCode)} · Borrowed: ${MoneyFormatter.format(party.totalBorrowedMinor, party.currencyCode)}',
      );
    }

    return ListRow(
      leading: LetterAvatar(party.personName, size: 40),
      title: party.personName,
      subtitle: subtitleParts.join(' · '),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isReceivable) ...[
                  AppIcon(HugeIcons.strokeRoundedArrowUpRight01, size: 12, color: statusColor),
                  const SizedBox(width: 3),
                ] else if (isPayable) ...[
                  AppIcon(HugeIcons.strokeRoundedArrowDownLeft01, size: 12, color: statusColor),
                  const SizedBox(width: 3),
                ],
                Text(
                  isSettled
                      ? tr.settled
                      : (isReceivable
                          ? '+${MoneyFormatter.format(net.abs(), party.currencyCode)}'
                          : '−${MoneyFormatter.format(net.abs(), party.currencyCode)}'),
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          const Chevron(),
        ],
      ),
      onTap: () => _showPartyDetailsSheet(context, party),
    );
  }

  void _showPartyDetailsSheet(BuildContext context, DebtPartySummary party) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    final net = party.netBalanceMinor;
    final isReceivable = party.isNetReceivable;
    final isPayable = party.isNetPayable;
    final isSettled = party.isSettled;

    final Color statusColor = isReceivable
        ? colors.income
        : (isPayable ? colors.expense : scheme.onSurfaceVariant);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpace.xl,
            right: AppSpace.xl,
            top: AppSpace.xl,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpace.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    LetterAvatar(party.personName, size: 48),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            party.personName,
                            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isReceivable
                                ? '${party.personName} owes you ${MoneyFormatter.format(net.abs(), party.currencyCode)}'
                                : (isPayable
                                    ? 'You owe ${party.personName} ${MoneyFormatter.format(net.abs(), party.currencyCode)}'
                                    : tr.settled),
                            style: text.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),

                // Party Financial Summary Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr.t('Net Party Position', ne: 'व्यक्तिगत कुल मौज्दात', es: 'Posición neta', fr: 'Position nette', de: 'Nettoposition', ja: '相手別純残高', zh: '联系人净结余', it: 'Posizione netta'),
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          StatusChip(
                            isSettled
                                ? tr.settled
                                : (isReceivable ? tr.theyOweYou : tr.youOweThem),
                            tone: isSettled
                                ? ChipTone.neutral
                                : (isReceivable ? ChipTone.success : ChipTone.danger),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isReceivable ? '+' : (isPayable ? '−' : '')}${MoneyFormatter.format(net.abs(), party.currencyCode)}',
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      const RowDivider(),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr.lentToOthers, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                MoneyFormatter.format(party.totalLentMinor, party.currencyCode),
                                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.income),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(tr.borrowedFromOthers, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                MoneyFormatter.format(party.totalBorrowedMinor, party.currencyCode),
                                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.expense),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),

                // Action Buttons (Full width vertically stacked per AGENTS.md)
                AppButton(
                  tr.t(
                    'Add Loan / Debt with ${party.personName}',
                    ne: '${party.personName} सँग नयाँ सापटी थप्नुहोस्',
                    es: 'Añadir registro con ${party.personName}',
                    fr: 'Ajouter un enregistrement avec ${party.personName}',
                    de: 'Eintrag mit ${party.personName} hinzufügen',
                    ja: '${party.personName}との記録を追加',
                    zh: '添加与 ${party.personName} 的借贷记录',
                    it: 'Aggiungi record con ${party.personName}',
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      AppRoutes.addDebt,
                      extra: <String, dynamic>{
                        'type': isPayable ? DebtType.borrowed : DebtType.lent,
                        'personName': party.personName,
                      },
                    );
                  },
                ),
                if (party.activeDebts.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  AppButton(
                    tr.t(
                      'Settle All with ${party.personName}',
                      ne: '${party.personName} को सबै सापटी चुक्ता गर्नुहोस्',
                      es: 'Liquidar todo con ${party.personName}',
                      fr: 'Tout régler avec ${party.personName}',
                      de: 'Alles mit ${party.personName} begleichen',
                      ja: '${party.personName}の記録を一括清算',
                      zh: '结清与 ${party.personName} 的所有借贷',
                      it: 'Salda tutto con ${party.personName}',
                    ),
                    kind: AppButtonKind.secondary,
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: tr.quickSettle,
                        message: tr.t(
                          'Mark all active debt records with ${party.personName} as settled?',
                          ne: 'के तपाईं ${party.personName} सँगका सबै सक्रिय सापटी चुक्ता भएको रूपमा चिन्ह लगाउन चाहनुहुन्छ?',
                          es: '¿Marcar todos los registros con ${party.personName} como saldados?',
                          fr: 'Marquer tous les enregistrements avec ${party.personName} comme réglés ?',
                          de: 'Alle aktiven Schulden mit ${party.personName} als beglichen markieren?',
                          ja: '${party.personName}とのすべてのアクティブな記録を清算済みにしますか？',
                          zh: '确定将与 ${party.personName} 的所有活跃借贷标记为已结清吗？',
                          it: 'Segnare tutti i debiti con ${party.personName} come saldati?',
                        ),
                        confirmLabel: tr.quickSettle,
                        cancelLabel: tr.cancel,
                      );
                      if (confirmed && context.mounted) {
                        Navigator.of(sheetContext).pop();
                        await _viewModel.settleParty(party.personName);
                        if (context.mounted) {
                          showToast(context, tr.markedAsSettled);
                        }
                      }
                    },
                  ),
                ],
                const SizedBox(height: AppSpace.lg),

                // Transaction Records Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.t(
                        'Transaction History',
                        ne: 'कारोबार विवरण',
                        es: 'Historial de transacciones',
                        fr: 'Historique des transactions',
                        de: 'Transaktionsverlauf',
                        ja: '取引履歴',
                        zh: '借贷明细记录',
                        it: 'Cronologia transazioni',
                      ),
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${party.debts.length} ${party.debts.length == 1 ? "record" : "records"}',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),

                // Individual Debt Cards for this Party
                for (final debt in party.debts) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: debt.type == DebtType.lent.value
                                    ? colors.income.withValues(alpha: 0.12)
                                    : colors.expense.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppIcon(
                                    debt.type == DebtType.lent.value
                                        ? HugeIcons.strokeRoundedArrowUpRight01
                                        : HugeIcons.strokeRoundedArrowDownLeft01,
                                    size: 12,
                                    color: debt.type == DebtType.lent.value
                                        ? colors.income
                                        : colors.expense,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    debt.type == DebtType.lent.value
                                        ? tr.theyOweYou
                                        : tr.youOweThem,
                                    style: text.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: debt.type == DebtType.lent.value
                                          ? colors.income
                                          : colors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              debt.isSettled ? tr.settled : tr.active,
                              tone: debt.isSettled ? ChipTone.neutral : ChipTone.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.sm),

                        // Amount Breakdown Row (Total, Paid, Remaining)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr.t('Original', ne: 'सुरुको', es: 'Original', fr: 'Original', de: 'Ursprünglich', ja: '元金', zh: '初始本金', it: 'Originale'), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Text(
                                  MoneyFormatter.format(debt.originalAmountMinor, debt.currencyCode),
                                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(tr.t('Paid', ne: 'तिरेको', es: 'Pagado', fr: 'Payé', de: 'Bezahlt', ja: '返済済', zh: '已还金额', it: 'Pagato'), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Text(
                                  MoneyFormatter.format(debt.paidAmountMinor, debt.currencyCode),
                                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.income),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(tr.remainingLabel, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                                const SizedBox(height: 2),
                                Text(
                                  MoneyFormatter.format(debt.remainingAmountMinor, debt.currencyCode),
                                  style: text.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: debt.isSettled
                                        ? scheme.onSurfaceVariant
                                        : (debt.type == DebtType.lent.value ? colors.income : colors.expense),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Repayment Progress Bar
                        if (debt.paidAmountMinor > 0 && !debt.isSettled) ...[
                          const SizedBox(height: AppSpace.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: debt.repaymentProgress,
                              minHeight: 5,
                              backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(colors.income),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(debt.repaymentProgress * 100).toInt()}% repaid',
                            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10),
                          ),
                        ],

                        if (debt.dueDate != null) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            '${tr.dueDateLabel} ${AppDate.short(DateTime.fromMillisecondsSinceEpoch(debt.dueDate!))}',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
                          ),
                        ],
                        if (debt.cleanNote.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            debt.cleanNote,
                            style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant),
                          ),
                        ],

                        const SizedBox(height: AppSpace.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!debt.isSettled) ...[
                              TextButton.icon(
                                icon: const Icon(Icons.payment_rounded, size: 16),
                                label: Text(tr.recordRepayment, style: const TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  _showRecordPaymentSheet(context, debt);
                                },
                              ),
                              const SizedBox(width: AppSpace.xs),
                              TextButton(
                                child: Text(tr.quickSettle, style: const TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _viewModel.settleDebt(debt.id);
                                  if (context.mounted) {
                                    showToast(context, tr.markedAsSettled);
                                  }
                                },
                              ),
                            ] else ...[
                              TextButton(
                                child: Text(tr.markAsUnsettled, style: const TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _viewModel.unsettleDebt(debt.id);
                                  if (context.mounted) {
                                    showToast(context, tr.markedAsUnsettled);
                                  }
                                },
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 18),
                              tooltip: 'Details',
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _showDebtDetailsSheet(context, debt);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtRow(
    Debt debt,
    AppColors colors,
    ColorScheme scheme,
    TextTheme text,
    AppStrings tr,
  ) {
    final isLent = debt.type == DebtType.lent.value;
    final isSettled = debt.isSettled;
    final dateStr = debt.dueDate != null
        ? AppDate.short(DateTime.fromMillisecondsSinceEpoch(debt.dueDate!))
        : null;

    final orig = debt.originalAmountMinor;
    final paid = debt.paidAmountMinor;
    final remaining = debt.remainingAmountMinor;

    final subtext = <String>[];
    if (isLent) {
      subtext.add('Lent (They owe you)');
    } else {
      subtext.add('Borrowed (You owe them)');
    }
    if (paid > 0 && !isSettled) {
      subtext.add('Paid ${MoneyFormatter.format(paid, debt.currencyCode)} of ${MoneyFormatter.format(orig, debt.currencyCode)}');
    }
    if (dateStr != null) {
      subtext.add('${tr.duePrefix} $dateStr');
    }
    if (debt.cleanNote.isNotEmpty) {
      subtext.add(debt.cleanNote);
    }

    return ListRow(
      leading: LetterAvatar(debt.personName, size: 40),
      title: debt.personName,
      subtitle: subtext.join(' · '),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isLent ? '+' : '−'}${MoneyFormatter.format(remaining, debt.currencyCode)}',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSettled
                      ? scheme.onSurfaceVariant
                      : (isLent ? colors.income : colors.expense),
                  decoration: isSettled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (isSettled)
                Text(
                  tr.settled,
                  style: text.bodySmall?.copyWith(
                    color: colors.income,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.xs),
          const Chevron(),
        ],
      ),
      onTap: () => _showDebtDetailsSheet(context, debt),
    );
  }

  void _showDebtDetailsSheet(BuildContext context, Debt debt) {
    final isLent = debt.type == DebtType.lent.value;
    final isSettled = debt.isSettled;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpace.xl,
            right: AppSpace.xl,
            top: AppSpace.xl,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  LetterAvatar(debt.personName, size: 44),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLent ? 'Lent (They owe you)' : 'Borrowed (You owe them)',
                          style: text.bodySmall?.copyWith(
                            color: isLent ? colors.income : colors.expense,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    isSettled ? tr.settled : tr.active,
                    tone: isSettled ? ChipTone.success : ChipTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),

              // Breakdown Card: Original, Paid, Remaining
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr.t('Original Amount', ne: 'सुरुको रकम', es: 'Monto original', fr: 'Montant initial', de: 'Ursprungsbetrag', ja: '元金', zh: '初始借贷本金', it: 'Importo originale'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 3),
                            Text(
                              MoneyFormatter.format(debt.originalAmountMinor, debt.currencyCode),
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(tr.t('Paid So Far', ne: 'तिरेको रकम', es: 'Pagado hasta hoy', fr: 'Déjà payé', de: 'Bisher bezahlt', ja: '既返済額', zh: '已付金额', it: 'Pagato finora'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 3),
                            Text(
                              MoneyFormatter.format(debt.paidAmountMinor, debt.currencyCode),
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colors.income),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(tr.remainingLabel, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 3),
                            Text(
                              MoneyFormatter.format(debt.remainingAmountMinor, debt.currencyCode),
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isSettled
                                    ? scheme.onSurfaceVariant
                                    : (isLent ? colors.income : colors.expense),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (debt.paidAmountMinor > 0 && !debt.isSettled) ...[
                      const SizedBox(height: AppSpace.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: debt.repaymentProgress,
                          minHeight: 6,
                          backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(colors.income),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(debt.repaymentProgress * 100).toInt()}% repaid',
                        style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (debt.dueDate != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        '${tr.dueDateLabel} ${AppDate.short(DateTime.fromMillisecondsSinceEpoch(debt.dueDate!))}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (debt.cleanNote.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        debt.cleanNote,
                        style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Action buttons (stacked full-width vertically per AGENTS.md)
              if (!isSettled) ...[
                AppButton(
                  tr.recordRepayment,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showRecordPaymentSheet(context, debt);
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  tr.quickSettle,
                  kind: AppButtonKind.secondary,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _viewModel.settleDebt(debt.id);
                    if (context.mounted) {
                      showToast(context, tr.markedAsSettled);
                    }
                  },
                ),
              ] else ...[
                AppButton(
                  tr.markAsUnsettled,
                  kind: AppButtonKind.secondary,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _viewModel.unsettleDebt(debt.id);
                    if (context.mounted) {
                      showToast(context, tr.markedAsUnsettled);
                    }
                  },
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              AppButton(
                tr.deleteRecordTitle,
                kind: AppButtonKind.danger,
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: tr.deleteRecordQuestion,
                    message: tr.t('Are you sure you want to permanently delete this debt record?', ne: 'के तपाईं निश्चित हुनुहुन्छ? यो रेकर्ड स्थायी रूपमा मेटिनेछ।', es: '¿Estás seguro de que deseas eliminar permanentemente este registro?', fr: 'Êtes-vous sûr de vouloir supprimer définitivement cet enregistrement ?', de: 'Möchten Sie diesen Schuldeneintrag wirklich dauerhaft löschen?', ja: 'この記録を完全に削除してもよろしいですか？', zh: '确定要永久删除此条借贷记录吗？', it: 'Sei sicuro di voler eliminare definitivamente questo record?'),
                    confirmLabel: tr.delete,
                    cancelLabel: tr.cancel,
                  );
                  if (confirmed && context.mounted) {
                    Navigator.of(sheetContext).pop();
                    await _viewModel.deleteDebt(debt.id);
                    if (context.mounted) {
                      showToast(context, tr.recordDeleted);
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordPaymentSheet(BuildContext context, Debt debt) {
    final tr = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final isLent = debt.type == DebtType.lent.value;

    final remainingMajor = (debt.remainingAmountMinor / 100.0).toStringAsFixed(2);
    final amountController = TextEditingController(text: remainingMajor);
    bool linkCashFlow = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (dlgContext) {
        String? paymentError;
        return StatefulBuilder(
          builder: (context, setDlgState) => Padding(
            padding: EdgeInsets.only(
              left: AppSpace.xl,
              right: AppSpace.xl,
              top: AppSpace.xl,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xl,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.recordRepayment,
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${debt.personName} · ${isLent ? "They owe you" : "You owe them"}',
                              style: text.bodySmall?.copyWith(
                                color: isLent ? colors.income : colors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dlgContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Summary Info Box: Original, Paid so far, Remaining
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr.t('Original Debt', ne: 'सुरुको रकम', es: 'Monto original', fr: 'Montant initial', de: 'Ursprungsbetrag', ja: '元金', zh: '初始借贷本金', it: 'Importo originale'), style: text.bodySmall),
                            Text(
                              MoneyFormatter.format(debt.originalAmountMinor, debt.currencyCode),
                              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr.t('Already Repaid', ne: 'तिरेको रकम', es: 'Ya pagado', fr: 'Déjà remboursé', de: 'Bereits bezahlt', ja: '既返済額', zh: '已偿还金额', it: 'Già rimborsato'), style: text.bodySmall),
                            Text(
                              MoneyFormatter.format(debt.paidAmountMinor, debt.currencyCode),
                              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.income),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                        const RowDivider(),
                        const SizedBox(height: AppSpace.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr.remainingLabel,
                              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              MoneyFormatter.format(debt.remainingAmountMinor, debt.currencyCode),
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isLent ? colors.income : colors.expense,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  // Repayment Amount Field
                  UnderlineField(
                    controller: amountController,
                    label: '${tr.paymentAmount} (${debt.currencyCode})',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    isRequired: true,
                    errorText: paymentError,
                    onChanged: (val) {
                      if (paymentError != null) {
                        setDlgState(() => paymentError = null);
                      } else {
                        setDlgState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: AppSpace.xs),

                  // Quick Action Chip: Fill Full Remaining Balance
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: Text(
                        'Set full balance (${MoneyFormatter.format(debt.remainingAmountMinor, debt.currencyCode)})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setDlgState(() {
                          amountController.text = (debt.remainingAmountMinor / 100.0).toStringAsFixed(2);
                          paymentError = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Cash Flow Switch
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.xs,
                    ),
                    child: SwitchRow(
                      title: tr.recordInEverydayAccount,
                      subtitle: isLent ? tr.inflowEverydayBalance : tr.outflowEverydayBalance,
                      value: linkCashFlow,
                      onChanged: (val) => setDlgState(() => linkCashFlow = val),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  AppButton(
                    tr.savePayment,
                    onPressed: amountController.text.trim().isEmpty
                        ? null
                        : () async {
                            final parsed = double.tryParse(amountController.text.trim());
                            if (parsed == null || parsed <= 0) {
                              setDlgState(() => paymentError = tr.enterValidAmount);
                              showErrorToast(context, tr.enterValidAmount);
                              return;
                            }

                            final minor = (parsed * 100).round();
                            // Overpayment validation per user requirement
                            if (minor > debt.remainingAmountMinor) {
                              setDlgState(() {
                                paymentError = 'Payment cannot exceed remaining balance of ${MoneyFormatter.format(debt.remainingAmountMinor, debt.currencyCode)}';
                              });
                              showErrorToast(
                                context,
                                'Maximum payable is ${MoneyFormatter.format(debt.remainingAmountMinor, debt.currencyCode)}',
                              );
                              return;
                            }

                            await _viewModel.recordPayment(
                              debt: debt,
                              paymentMinor: minor,
                              linkCashFlow: linkCashFlow,
                            );
                            if (dlgContext.mounted) {
                              Navigator.of(dlgContext).pop();
                            }
                            if (context.mounted) {
                              showToast(context, tr.paymentRecordedSuccess);
                            }
                          },
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ViewSegmentButton extends StatelessWidget {
  const _ViewSegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              icon,
              size: 16,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtStatusFilterButton extends StatelessWidget {
  const _DebtStatusFilterButton({
    required this.currentFilter,
    required this.onChanged,
  });

  final _DebtFilter currentFilter;
  final ValueChanged<_DebtFilter> onChanged;

  String _getLabel(BuildContext context, _DebtFilter filter) {
    final tr = context.strings;
    switch (filter) {
      case _DebtFilter.active:
        return tr.active;
      case _DebtFilter.lent:
        return tr.lentReceivable;
      case _DebtFilter.borrowed:
        return tr.borrowedPayable;
      case _DebtFilter.settled:
        return tr.settled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = currentFilter != _DebtFilter.active;
    final label = _getLabel(context, currentFilter);

    return PopupMenuButton<_DebtFilter>(
      initialValue: currentFilter,
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        for (final f in _DebtFilter.values)
          PopupMenuItem(
            value: f,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getLabel(ctx, f),
                    style: TextStyle(
                      fontWeight: currentFilter == f ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (currentFilter == f)
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: isCustom ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isCustom ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: isCustom ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCustom ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isCustom ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtPartyFilterButton extends StatelessWidget {
  const _DebtPartyFilterButton({
    required this.selectedParty,
    required this.existingParties,
    required this.baseCurrency,
    required this.netForParty,
    required this.onChanged,
  });

  final String? selectedParty;
  final List<String> existingParties;
  final String baseCurrency;
  final int Function(String party) netForParty;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.strings;
    final hasParty = selectedParty != null;
    final label = hasParty ? selectedParty! : tr.allParties;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => _showPartySheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: hasParty ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasParty ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 16,
              color: hasParty ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasParty ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: hasParty ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showPartySheet(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.strings;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.filterByCounterparty,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (selectedParty != null)
                      TextButton(
                        onPressed: () {
                          onChanged(null);
                          Navigator.pop(ctx);
                        },
                        child: Text(tr.clearAction),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
                child: existingParties.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.md),
                          child: Text(
                            tr.noCounterpartiesYet,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : HorizontalOptionSelector<String?>(
                        height: 56,
                        selectedValue: selectedParty,
                        onChanged: (party) {
                          onChanged(party);
                          Navigator.pop(ctx);
                        },
                        items: [
                          HorizontalOptionItem<String?>(
                            value: null,
                            label: tr.allParties,
                            iconData: Icons.people_alt_rounded,
                          ),
                          for (final party in existingParties)
                            HorizontalOptionItem<String?>(
                              value: party,
                              label: party,
                              subtitle: () {
                                final net = netForParty(party);
                                final isPositive = net >= 0;
                                return isPositive
                                    ? (tr.isNepali
                                        ? 'उनीहरूले: +${MoneyFormatter.format(net.abs(), baseCurrency)}'
                                        : 'Owes: +${MoneyFormatter.format(net.abs(), baseCurrency)}')
                                    : (tr.isNepali
                                        ? 'तपाईंले: −${MoneyFormatter.format(net.abs(), baseCurrency)}'
                                        : 'Owe: −${MoneyFormatter.format(net.abs(), baseCurrency)}');
                              }(),
                              avatar: LetterAvatar(party, size: 28),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
