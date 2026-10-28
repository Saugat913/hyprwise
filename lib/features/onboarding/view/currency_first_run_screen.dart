import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/onboarding/viewmodels/onboarding_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CurrencyFirstRunScreen extends StatefulWidget {
  const CurrencyFirstRunScreen({super.key});

  @override
  State<CurrencyFirstRunScreen> createState() => _CurrencyFirstRunScreenState();
}

class _CurrencyFirstRunScreenState extends State<CurrencyFirstRunScreen> {
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      settingsRepo: getIt<SettingsRepository>(),
      accountRepo: getIt<AccountRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, getIt<SettingsRepository>()]),
      builder: (context, _) {
        final tr = context.strings;
        final isLanguageStep = _viewModel.step == 0;

        return WizardScaffold(
          step: _viewModel.step,
          steps: 2,
          title: isLanguageStep ? tr.chooseLanguage : tr.whichCurrencyQuestion,
          subtitle: isLanguageStep ? tr.chooseLanguageSubtitle : tr.addSecondLater,
          primaryLabel: isLanguageStep ? tr.continueAction : tr.finishSetup,
          onBack: isLanguageStep ? () => context.go(AppRoutes.welcome) : _viewModel.previousStep,
          onClose: () => context.go(AppRoutes.welcome),
          onPrimary: () async {
            if (isLanguageStep) {
              _viewModel.nextStep();
            } else {
              await _viewModel.finishSetup();
              if (context.mounted) {
                context.go(AppRoutes.home);
              }
            }
          },
          child: isLanguageStep ? _buildLanguageSelection() : _buildCurrencySelection(),
        );
      },
    );
  }

  Widget _buildLanguageSelection() {
    return Column(
      children: [
        for (final lang in AppLanguage.supported) ...[
          OptionTile(
            title: lang.nativeName,
            subtitle: lang.nativeName != lang.name ? lang.name : null,
            icon: HugeIcons.strokeRoundedGlobe02,
            trailing: _LanguageBadge(lang.badge),
            selected: _viewModel.selectedLocale == lang.code,
            onTap: () => _viewModel.selectLocale(lang.code),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }

  Widget _buildCurrencySelection() {
    return Column(
      children: [
        for (final cur in Currency.supported) ...[
          OptionTile(
            title: '${cur.symbolForLocale(_viewModel.selectedLocale)} · ${cur.name}',
            subtitle: cur.code,
            icon: HugeIcons.strokeRoundedWallet01,
            selected: _viewModel.selectedCurrency == cur.code,
            onTap: () => _viewModel.selectCurrency(cur.code),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
