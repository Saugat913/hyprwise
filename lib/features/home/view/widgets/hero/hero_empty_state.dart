import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

/// Beautifully crafted empty state for new users with no accounts.
class HeroEmptyState extends StatelessWidget {
  const HeroEmptyState({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroEmptyCard(viewModel: viewModel),
        const SizedBox(height: AppSpace.md),
        _OnboardingChecklist(viewModel: viewModel),
      ],
    );
  }
}

class _HeroEmptyCard extends StatelessWidget {
  const _HeroEmptyCard({required this.viewModel});
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            tr.netPosition,
            style: text.bodySmall?.copyWith(
              color: colors.onHeroSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpace.xs + 2),

          // Big zero value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              MoneyFormatter.format(0, viewModel.baseCurrency),
              style: text.displaySmall?.copyWith(
                color: colors.onHero.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
                fontFamily: 'RedditMono',
                fontSize: 34,
                letterSpacing: -0.02 * 34,
                height: 1.1,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: AppSpace.xs),

          // Subtitle
          Text(
            tr.addAccountFillsIn,
            style: text.bodySmall?.copyWith(
              color: colors.onHeroSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Empty stack bar placeholder
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: colors.onHero.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Spendable/Reserved placeholders
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.liquid.withValues(alpha: 0.3), width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr.spendable,
                        style: text.bodySmall?.copyWith(
                          color: colors.onHeroSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '—',
                        style: text.labelLarge?.copyWith(
                          color: colors.onHeroSecondary.withValues(alpha: 0.4),
                          fontFamily: 'RedditMono',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.reserved.withValues(alpha: 0.3), width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr.reserved,
                        style: text.bodySmall?.copyWith(
                          color: colors.onHeroSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '—',
                        style: text.labelLarge?.copyWith(
                          color: colors.onHeroSecondary.withValues(alpha: 0.4),
                          fontFamily: 'RedditMono',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Three-step onboarding checklist shown below the hero when no accounts exist.
class _OnboardingChecklist extends StatelessWidget {
  const _OnboardingChecklist({required this.viewModel});
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    final steps = [
      (
        icon: HugeIcons.strokeRoundedWallet01,
        title: tr.addAccount,
        subtitle: tr.t(
          'Connect your everyday & savings accounts.',
          ne: 'दैनिक र बचत खाताहरू जडान गर्नुहोस्।',
          hi: 'अपने दैनिक और बचत खाते जोड़ें।',
          es: 'Conecta tus cuentas de uso diario y ahorros.',
          fr: 'Connectez vos comptes courants et épargne.',
          de: 'Verbinden Sie Ihre Alltags- und Sparkonten.',
          ja: '日常口座と貯蓄口座を追加してください。',
          zh: '添加您的日常账户和储蓄账户。',
          it: 'Collega i tuoi conti quotidiani e risparmi.',
        ),
        onTap: () => context.push(AppRoutes.addAccount),
        isDone: viewModel.hasAccounts,
      ),
      (
        icon: HugeIcons.strokeRoundedClock01,
        title: tr.t('Add a job', ne: 'काम थप्नुहोस्', hi: 'नौकरी जोड़ें', es: 'Añadir trabajo', fr: 'Ajouter un emploi', de: 'Job hinzufügen', ja: '仕事を追加', zh: '添加工作', it: 'Aggiungi lavoro'),
        subtitle: tr.t(
          'Track your shifts and hourly earnings.',
          ne: 'सिफ्ट र प्रति घण्टा आम्दानी ट्र्याक गर्नुहोस्।',
          hi: 'अपनी शिफ्ट और प्रति घंटा आय ट्रैक करें।',
          es: 'Registra tus turnos e ingresos por hora.',
          fr: 'Suivez vos quarts de travail et revenus horaires.',
          de: 'Erfassen Sie Ihre Schichten und Stundenlöhne.',
          ja: 'シフトと時給を記録しましょう。',
          zh: '追踪您的班次和小时收入。',
          it: 'Tieni traccia dei turni e dei guadagni orari.',
        ),
        onTap: () => context.push(AppRoutes.addJob),
        isDone: viewModel.hasJobs,
      ),
      (
        icon: HugeIcons.strokeRoundedTarget01,
        title: tr.t('Set a goal', ne: 'लक्ष्य राख्नुहोस्', hi: 'लक्ष्य निर्धारित करें', es: 'Establecer meta', fr: 'Fixer un objectif', de: 'Ziel setzen', ja: '目標を設定', zh: '设定目标', it: 'Imposta un obiettivo'),
        subtitle: tr.t(
          'Give your money a purpose.',
          ne: 'आफ्नो पैसालाई उद्देश्य दिनुहोस्।',
          hi: 'अपने पैसे को एक उद्देश्य दें।',
          es: 'Dale un propósito a tu dinero.',
          fr: 'Donnez un but à votre argent.',
          de: 'Geben Sie Ihrem Geld einen Zweck.',
          ja: 'お金に目的を持たせましょう。',
          zh: '让你的钱有意义。',
          it: 'Dai uno scopo ai tuoi soldi.',
        ),
        onTap: () => context.push(AppRoutes.addGoal),
        isDone: viewModel.hasGoals,
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.sm),
            child: Text(
              tr.t(
                'Get started',
                ne: 'सुरु गर्नुहोस्',
                hi: 'शुरू करें',
                es: 'Comenzar',
                fr: 'Commencer',
                de: 'Loslegen',
                ja: 'はじめましょう',
                zh: '开始使用',
                it: 'Inizia',
              ),
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1),
            _OnboardingStep(
              icon: steps[i].icon,
              title: steps[i].title,
              subtitle: steps[i].subtitle,
              isDone: steps[i].isDone,
              stepNumber: i + 1,
              onTap: steps[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.stepNumber,
    required this.onTap,
  });

  final IconGlyph icon;
  final String title;
  final String subtitle;
  final bool isDone;
  final int stepNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return InkWell(
      onTap: isDone ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm + 4,
        ),
        child: Row(
          children: [
            // Step indicator or check circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone
                    ? colors.income.withValues(alpha: 0.12)
                    : colors.fill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? Icon(Icons.check_rounded, size: 18, color: colors.income)
                  : AppIcon(icon, size: 18, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDone ? scheme.onSurfaceVariant : scheme.onSurface,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            if (isDone)
              StatusChip(context.strings.done, tone: ChipTone.success)
            else
              const Chevron(),
          ],
        ),
      ),
    );
  }
}
