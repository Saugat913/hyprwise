import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/goals/data/model/goals.dart';
import 'package:finance_tracker/features/goals/viewmodels/goal_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AddGoalWizard extends StatefulWidget {
  const AddGoalWizard({super.key});

  @override
  State<AddGoalWizard> createState() => _AddGoalWizardState();
}

class _AddGoalWizardState extends State<AddGoalWizard> {
  int _step = 0;
  String _category = 'Emergency fund';
  final _customNameController = TextEditingController();
  final _targetController = TextEditingController(text: '5000.00');
  final _alreadySavedController = TextEditingController(text: '0.00');

  int _months = 6;
  DateTime? _customDate;
  bool _remindMonthly = true;
  bool _createSavingsAccount = true;
  final GoalPriority _priority = GoalPriority.high;

  String? _customNameError;
  String? _targetError;

  @override
  void dispose() {
    _customNameController.dispose();
    _targetController.dispose();
    _alreadySavedController.dispose();
    super.dispose();
  }

  String _goalName(BuildContext context) {
    final tr = context.strings;
    return switch (_category) {
      'Emergency fund' => tr.emergencyFund,
      'Something to buy' => tr.somethingToBuy,
      'A trip' => tr.aTrip,
      _ => _customNameController.text.trim().isEmpty
          ? tr.myGoal
          : _customNameController.text.trim(),
    };
  }

  void _onNext() {
    final tr = context.strings;
    if (_step == 0) {
      if (_category == 'Something else' && _customNameController.text.trim().isEmpty) {
        final msg = tr.t('Please enter a goal name', ne: 'कृपया लक्ष्यको नाम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un nombre de meta', fr: 'Veuillez saisir un nom d\'objectif', de: 'Bitte Zielnamen eingeben', ja: '目標名を入力してください', zh: '请输入目标名称', it: 'Inserisci un nome per l\'obiettivo');
        setState(() => _customNameError = msg);
        showErrorToast(context, msg);
        return;
      }
      setState(() {
        _customNameError = null;
        _step = 1;
      });
    } else if (_step == 1) {
      final target = double.tryParse(_targetController.text.trim()) ?? 0;
      if (target <= 0) {
        final msg = tr.t('Please enter a valid target amount', ne: 'कृपया मान्य लक्ष्य रकम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un importe objetivo válido', fr: 'Veuillez saisir un montant cible valide', de: 'Bitte gültigen Zielbetrag eingeben', ja: '有効な目標金額を入力してください', zh: '请输入有效的目标金额', it: 'Inserisci un importo obiettivo valido');
        setState(() => _targetError = msg);
        showErrorToast(context, msg);
        return;
      }
      setState(() {
        _targetError = null;
        _step = 2;
      });
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final tr = context.strings;
    final viewModel = getIt<PlanViewModel>();
    final target = (double.tryParse(_targetController.text.trim()) ?? 1000.0) * 100;
    final saved = (double.tryParse(_alreadySavedController.text.trim()) ?? 0.0) * 100;

    final targetDate = _customDate ?? DateTime.now().add(Duration(days: _months * 30));

    await viewModel.addGoal(
      name: _goalName(context),
      targetAmountMinor: target.round(),
      initialSavedMinor: saved.round(),
      targetDate: targetDate,
      category: _category,
      priority: _priority,
      createSavingsAccount: _createSavingsAccount,
    );

    if (mounted) {
      showToast(context, tr.t('Goal created', ne: 'लक्ष्य सिर्जना गरियो', es: 'Meta creada', fr: 'Objectif créé', de: 'Ziel erstellt', ja: '目標を作成しました', zh: '目标已创建', it: 'Obiettivo creato'), actionLabel: tr.t('View', ne: 'हेर्नुहोस्', es: 'Ver', fr: 'Voir', de: 'Ansehen', ja: '表示', zh: '查看', it: 'Visualizza'));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = getIt<PlanViewModel>().baseCurrency;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    final targetDouble = double.tryParse(_targetController.text) ?? 5000.0;
    final savedDouble = double.tryParse(_alreadySavedController.text) ?? 0.0;
    final remaining = (targetDouble - savedDouble).clamp(0.0, double.infinity);
    final monthlyNeed = (remaining / _months);

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 3,
          title: tr.t('What are you saving for?', ne: 'के को लागि बचत गर्दै हुनुहुन्छ?', es: '¿Para qué estás ahorrando?', fr: 'Pour quoi épargnez-vous ?', de: 'Wofür sparen Sie?', ja: '何のために貯金しますか？', zh: '您为何存钱？', it: 'Per cosa stai risparmiando?'),
          subtitle: tr.t('Pick the closest one.', ne: 'नजिकको विकल्प छान्नुहोस्।', es: 'Elige la opción más cercana.', fr: 'Choisissez la plus proche.', de: 'Wählen Sie die passendste Option.', ja: '最も近い項目を選択してください。', zh: '请选择最接近的一项。', it: 'Scegli la più vicina.'),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.next,
          onPrimary: (_category == 'Something else' && _customNameController.text.trim().isEmpty) ? null : _onNext,
          onClose: () => context.pop(),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpace.sm,
                crossAxisSpacing: AppSpace.sm,
                childAspectRatio: 1.25,
                children: [
                  _GoalCategoryCard(
                    title: tr.emergencyFund,
                    subtitle: tr.cushionForSurprises,
                    icon: HugeIcons.strokeRoundedShield02,
                    isSelected: _category == 'Emergency fund',
                    onTap: () => setState(() => _category = 'Emergency fund'),
                  ),
                  _GoalCategoryCard(
                    title: tr.somethingToBuy,
                    subtitle: tr.laptopBikeGift,
                    icon: HugeIcons.strokeRoundedShoppingBag01,
                    isSelected: _category == 'Something to buy',
                    onTap: () => setState(() => _category = 'Something to buy'),
                  ),
                  _GoalCategoryCard(
                    title: tr.aTrip,
                    subtitle: tr.somewhereYouWantToGo,
                    icon: HugeIcons.strokeRoundedAirplane01,
                    isSelected: _category == 'A trip',
                    onTap: () => setState(() => _category = 'A trip'),
                  ),
                  _GoalCategoryCard(
                    title: tr.somethingElse,
                    subtitle: tr.nameItYourself,
                    icon: HugeIcons.strokeRoundedTarget02,
                    isSelected: _category == 'Something else',
                    onTap: () => setState(() => _category = 'Something else'),
                  ),
                ],
              ),
              if (_category == 'Something else') ...[
                const SizedBox(height: AppSpace.md),
                UnderlineField(
                  label: tr.goalName,
                  hint: tr.goalNameHint,
                  controller: _customNameController,
                  autofocus: true,
                  isRequired: true,
                  errorText: _customNameError,
                  onChanged: (_) {
                    if (_customNameError != null) setState(() => _customNameError = null);
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
      1 => WizardScaffold(
          step: 1,
          steps: 3,
          title: tr.howMuchDoYouNeed,
          subtitle: tr.roughNumberIsFine,
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.next,
          onPrimary: _targetController.text.trim().isEmpty ? null : _onNext,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: tr.targetAmount,
                hint: '$currency 5,000',
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                isRequired: true,
                errorText: _targetError,
                onChanged: (_) {
                  if (_targetError != null) setState(() => _targetError = null);
                  setState(() {});
                },
              ),
              const SizedBox(height: AppSpace.xl),
              UnderlineField(
                label: tr.initialDepositSavingsOptional,
                hint: '$currency 0',
                controller: _alreadySavedController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                child: SwitchRow(
                  title: tr.createSavingsAccountTitle,
                  subtitle: _createSavingsAccount
                      ? tr.t(
                          'Creates a dedicated "${_goalName(context)} Savings" account with this initial deposit.',
                          ne: 'यस लक्ष्यको लागि समर्पित बचत खाता तयार हुनेछ।',
                          es: 'Crea una cuenta dedicada "${_goalName(context)} Ahorros" con este depósito.',
                          fr: 'Crée un compte dédié "${_goalName(context)} Épargne" avec ce dépôt.',
                          de: 'Erstellt ein eigenes Sparkonto "${_goalName(context)}" mit dieser Einzahlung.',
                          ja: 'この入金をもとに専用の「${_goalName(context)}貯金」口座を作成します。',
                          zh: '以此初始资金创建专属的“${_goalName(context)} 储蓄账户”。',
                          it: 'Crea un conto dedicato "${_goalName(context)} Risparmio" con questo deposito.',
                        )
                      : tr.trackGoalWithoutAccount,
                  value: _createSavingsAccount,
                  onChanged: (val) => setState(() => _createSavingsAccount = val),
                ),
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 2,
          steps: 3,
          title: tr.byWhen,
          subtitle: tr.workOutMonthlyAmount,
          onBack: () => setState(() => _step = 1),
          onClose: () => context.pop(),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.saveGoal,
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final m in [3, 6, 12])
                    ChoicePill(
                      tr.monthsCountShort(m),
                      selected: _months == m && _customDate == null,
                      onTap: () {
                        setState(() {
                          _months = m;
                          _customDate = null;
                        });
                      },
                    ),
                  ChoicePill(
                    _customDate != null ? AppDate.short(_customDate!) : tr.selectDatePrompt,
                    selected: _customDate != null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() {
                          _customDate = picked;
                          _months = (picked.difference(DateTime.now()).inDays / 30).clamp(1, 120).round();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xxl),
              Text(
                tr.neededPerMonth,
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '${MoneyFormatter.format((monthlyNeed * 100).round(), currency)} ${tr.perMonthSuffix}',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.xl),
              AppCard(
                child: SwitchRow(
                  title: tr.monthlyReminder,
                  subtitle: tr.getNudgedMonthly,
                  value: _remindMonthly,
                  onChanged: (val) => setState(() => _remindMonthly = val),
                ),
              ),
            ],
          ),
        ),
    };
  }
}

class _GoalCategoryCard extends StatelessWidget {
  const _GoalCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color:
            isSelected ? scheme.primary.withValues(alpha: 0.08) : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color:
                    isSelected
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.6),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? scheme.primary.withValues(alpha: 0.15)
                                : scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        icon,
                        size: 16,
                        color:
                            isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? scheme.primary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

