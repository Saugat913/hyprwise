import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/network/api_client.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/paywalls.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/subscription/view/subscription_auth_guard_sheet.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<SettingsViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final tr = context.strings;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.settings,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.xxxl),
              children: [
                // Top Zone: User Profile & Upgrade/Pro
                const _AccountAuthCard(),
                const SizedBox(height: AppSpace.sm),
                const _SubscriptionBanner(),
                const SizedBox(height: AppSpace.xl),

                // Appearance & Language Selection Cards
                Text(tr.appearance, style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                _ThemeSelector(
                  currentMode: viewModel.themeMode,
                  onChanged: viewModel.setThemeMode,
                ),
                const SizedBox(height: AppSpace.md),
                Text(tr.language, style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                _LanguageSelector(
                  currentLocale: viewModel.localeCode,
                  onChanged: viewModel.setLocaleCode,
                ),
                const SizedBox(height: AppSpace.xl),

                // Money section
                Text(tr.money, style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListRow(
                        title: tr.accounts,
                        leading: const IconTile(HugeIcons.strokeRoundedWallet01),
                        trailing: _Value(tr.formatNumber(viewModel.accountsCount)),
                        onTap: () => context.push(AppRoutes.accounts),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: tr.currency,
                        leading: const IconTile(HugeIcons.strokeRoundedWallet01),
                        trailing: _Value(viewModel.baseCurrency),
                        onTap: () => context.push(AppRoutes.currencySettings),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: tr.jobs,
                        leading: const IconTile(HugeIcons.strokeRoundedBriefcase01),
                        trailing: _Value(tr.formatNumber(viewModel.jobsCount)),
                        onTap: () => context.push(AppRoutes.manageJobs),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: tr.debts,
                        leading: const IconTile(HugeIcons.strokeRoundedMoney01),
                        trailing: const Chevron(),
                        onTap: () => context.push(AppRoutes.debts),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: tr.categoriesAndMerchants,
                        leading: const IconTile(HugeIcons.strokeRoundedGridView),
                        trailing: const Chevron(),
                        onTap: () => context.push(AppRoutes.categories),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Alerts section
                Text(tr.alerts, style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListRow(
                    title: tr.alerts,
                    leading: const IconTile(HugeIcons.strokeRoundedNotification01),
                    trailing: _Value(viewModel.settings.shiftReminders ? tr.onState : tr.offState),
                    onTap: () => context.push(AppRoutes.alerts),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // AI Assistant section
                Text(tr.aiAssistant, style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListRow(
                        title: tr.askAiAssistant,
                        subtitle: tr.financialInsightsAdvice,
                        leading: const IconTile(HugeIcons.strokeRoundedChatBot),
                        trailing: const Chevron(),
                        onTap: () => context.push(AppRoutes.assistant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Data section
                Text(tr.dataAndBackup, style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListRow(
                    title: tr.backupExportRestore,
                    subtitle: tr.backupSyncDesc,
                    leading: const IconTile(HugeIcons.strokeRoundedCloud),
                    trailing: const Chevron(),
                    onTap: () => context.push(AppRoutes.backup),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Bottom Zone: Support & Legal section
                Text(tr.supportHyprwise, style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                const _SupporterBanner(),
                const SizedBox(height: AppSpace.md),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListRow(
                        title: tr.restorePurchases,
                        subtitle: tr.t(
                          'Restore Pro or supporter purchases on this device',
                          ne: 'यो उपकरणमा Pro वा समर्थक खरिदहरू पुनर्स्थापना गर्नुहोस्',
                          es: 'Restaurar compras Pro o de apoyo en este dispositivo',
                          fr: 'Restaurer les achats Pro ou de soutien sur cet appareil',
                          de: 'Pro- oder Unterstützer-Käufe auf diesem Gerät wiederherstellen',
                          ja: 'この端末でProまたはサポーターの購入を復元',
                          zh: '在此设备上恢复 Pro 或支持者购买',
                          it: 'Ripristina gli acquisti Pro o supporter su questo dispositivo',
                        ),
                        leading: const IconTile(HugeIcons.strokeRoundedRefresh),
                        trailing: const Chevron(),
                        onTap: () async {
                          final access = await getIt<SubscriptionService>().restorePurchases();
                          if (context.mounted) {
                            showToast(
                              context,
                              access.isPro ? tr.purchasesRestored : tr.noPurchasesFound,
                            );
                          }
                        },
                      ),
                      const RowDivider(),
                      ListRow(
                        title: tr.privacyPolicy,
                        subtitle: tr.localFirstDataProtection,
                        leading: const IconTile(HugeIcons.strokeRoundedShield02),
                        trailing: const Chevron(),
                        onTap: () => showAppPrivacyPolicyDialog(context),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: tr.termsOfService,
                        subtitle: tr.userAgreementSubscriptionRules,
                        leading: const IconTile(HugeIcons.strokeRoundedNote01),
                        trailing: const Chevron(),
                        onTap: () => showAppTermsDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Danger zone
                Text(tr.dangerZone, style: text.bodySmall?.copyWith(color: scheme.error)),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListRow(
                        title: tr.eraseAllData,
                        leading: IconTile(HugeIcons.strokeRoundedDelete02, color: scheme.error, background: scheme.error.withValues(alpha: 0.1)),
                        trailing: const Chevron(),
                        onTap: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: tr.eraseAllDataQuestion,
                            message: tr.t(
                              'This removes accounts, jobs, shifts and goals from this phone. It cannot be undone.',
                              ne: 'यसले खाता, काम, सिफ्ट र लक्ष्यहरू पूर्ण रूपमा मेटाउँछ। यसलाई पूर्ववत गर्न सकिँदैन।',
                              es: 'Esto elimina cuentas, empleos, turnos y metas de este móvil. No se puede deshacer.',
                              fr: 'Supprime comptes, emplois, quarts et objectifs de cet appareil. Irréversible.',
                              de: 'Löscht Konten, Jobs, Schichten und Ziele von diesem Gerät. Kann nicht rückgängig gemacht werden.',
                              ja: 'この端末から口座、仕事、シフト、目標が完全に消去されます。元に戻すことはできません。',
                              zh: '这将从本机彻底清除账户、工作岗位、排班与目标数据，操作不可撤回。',
                              it: 'Rimuove conti, lavori, turni e obiettivi da questo telefono. Operazione irreversibile.',
                            ),
                            confirmLabel: tr.eraseEverything,
                            cancelLabel: tr.cancel,
                          );
                          if (confirmed && context.mounted) {
                            await viewModel.eraseAllData();
                            if (context.mounted) {
                              showToast(context, tr.eraseAllData);
                              context.go(AppRoutes.home);
                            }
                          }
                        },
                      ),
                      if (getIt<AuthService>().isAuthenticated) ...[
                        const RowDivider(),
                        ListRow(
                          title: tr.deleteAccountAndCloudBackups,
                          subtitle: tr.deleteAccountSubtitle,
                          leading: IconTile(HugeIcons.strokeRoundedDelete02, color: scheme.error, background: scheme.error.withValues(alpha: 0.1)),
                          trailing: const Chevron(),
                          onTap: () async {
                            final authService = getIt<AuthService>();
                            final confirmed = await showConfirmDialog(
                              context,
                              title: tr.deleteAccountPermanentlyQuestion,
                              message: tr.t(
                                'This permanently erases your cloud backups, registered user profile, and local data.',
                                ne: 'यसले तपाईंको क्लाउड ब्याकअप, प्रोफाइल र सम्पूर्ण डाटा पूर्ण रूपमा मेटाउनेछ।',
                                es: 'Esto borrará permanentemente tus copias en la nube, perfil de usuario y datos locales.',
                                fr: 'Efface définitivement vos sauvegardes cloud, votre profil et vos données locales.',
                                de: 'Löscht Ihre Cloud-Backups, Ihr Profil und Ihre lokalen Daten dauerhaft.',
                                ja: 'クラウドバックアップ、登録プロフィール、ローカルデータがすべて永久に削除されます。',
                                zh: '这将永久注销您的用户档案、彻底删除云端备份及本地全部数据。',
                                it: 'Cancella definitivamente i tuoi backup cloud, profilo e dati locali.',
                              ),
                              confirmLabel: tr.deleteAccount,
                              cancelLabel: tr.cancel,
                            );
                            if (confirmed && context.mounted) {
                              final userId = authService.currentUser?.id;
                              final email = authService.currentUser?.email;
                              await ApiClient.instance.deleteAccount(userId: userId, email: email, reason: 'in_app_request');
                              await viewModel.eraseAllData();
                              await authService.signOut();
                              if (context.mounted) {
                                showToast(context, tr.accountAndDataDeleted);
                                context.go(AppRoutes.home);
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                Center(
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/brand/logo/hyprwise-logo.svg',
                        height: 22,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        tr.appVersionTagline,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
              ],
            ),
          ),
        );
      },
    );
  }


}

/// Muted value + chevron shown at the end of a settings row.
class _Value extends StatelessWidget {
  const _Value(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppSpace.xs),
          const Chevron(),
        ],
      );
}

class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner();

  @override
  Widget build(BuildContext context) {
    final subService = getIt<SubscriptionService>();
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    return ListenableBuilder(
      listenable: subService,
      builder: (context, _) {
        final isProOrSupporter = subService.isPro || subService.isSupporter || subService.everSupported;
        // When pro or supporter, hide the upgrade/active pro banner altogether
        if (isProOrSupporter) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm),
          child: InkWell(
            onTap: () async {
              if (getIt<AuthService>().isGuest) {
                final ok = await promptLoginToUpgrade(context);
                if (!ok) return;
              }
              if (subService.isConfigured) {
                try {
                  final result = await subService.presentPaywall();
                  if (result == PaywallResult.error && context.mounted) {
                    context.push(AppRoutes.paywall);
                  }
                } catch (_) {
                  if (context.mounted) context.push(AppRoutes.paywall);
                }
              } else {
                if (context.mounted) context.push(AppRoutes.paywall);
              }
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D2808), Color(0xFF221705)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const AppIcon(
                      HugeIcons.strokeRoundedCrown,
                      size: 22,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.upgradeToPro,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr.proUpgradeSubtitle,
                          style: text.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SupporterBanner extends StatelessWidget {
  const _SupporterBanner();

  @override
  Widget build(BuildContext context) {
    final subService = getIt<SubscriptionService>();
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final tr = context.strings;

    return ListenableBuilder(
      listenable: subService,
      builder: (context, _) {
        final everSupported = subService.everSupported;
        return InkWell(
          onTap: () => Paywalls.showTipJar(),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: everSupported
                    ? const Color(0xFFE11D48).withValues(alpha: 0.4)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const AppIcon(
                    HugeIcons.strokeRoundedFavourite,
                    size: 20,
                    color: Color(0xFFE11D48),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tr.supportHyprwise,
                              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (everSupported) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AppIcon(
                                    HugeIcons.strokeRoundedFavourite,
                                    size: 11,
                                    color: Color(0xFFE11D48),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    tr.supporterBadge,
                                    style: text.labelSmall?.copyWith(
                                      color: const Color(0xFFE11D48),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr.supportHyprwiseSubtitle,
                        style: text.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountAuthCard extends StatelessWidget {
  const _AccountAuthCard();

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();
    final subService = getIt<SubscriptionService>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    return ListenableBuilder(
      listenable: Listenable.merge([authService, subService]),
      builder: (context, _) {
        final user = authService.currentUser;
        if (user != null) {
          final initial = user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U';
          return AppCard(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subService.isPro || subService.everSupported) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (subService.isPro)
                              InkWell(
                                onTap: () => subService.presentCustomerCenter(),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: const ProCrownBadge(isCompact: true),
                              ),
                            if (subService.everSupported)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const AppIcon(
                                      HugeIcons.strokeRoundedFavourite,
                                      size: 11,
                                      color: Color(0xFFE11D48),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      tr.supporterBadge,
                                      style: text.labelSmall?.copyWith(
                                        color: const Color(0xFFE11D48),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => authService.signOut(),
                  child: Text(tr.signOut),
                ),
              ],
            ),
          );
        }

        return AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: AppIcon(
                      HugeIcons.strokeRoundedUser,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: Text(
                      tr.cloudAccount,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr.signInToSyncSubtitle,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (subService.isPro || subService.everSupported) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (subService.isPro)
                      InkWell(
                        onTap: () => subService.presentCustomerCenter(),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: const ProCrownBadge(isCompact: true),
                      ),
                    if (subService.everSupported)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(
                              HugeIcons.strokeRoundedFavourite,
                              size: 11,
                              color: Color(0xFFE11D48),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              tr.supporterBadge,
                              style: text.labelSmall?.copyWith(
                                color: const Color(0xFFE11D48),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.g_mobiledata, size: 22),
                      label: const Text('Google', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await authService.signInWithGoogle();
                        if (context.mounted) showToast(context, tr.signedInWithGoogle);
                      },
                    ),
                  ),
                  if (Theme.of(context).platform == TargetPlatform.iOS ||
                      Theme.of(context).platform == TargetPlatform.macOS) ...[
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.apple, size: 18),
                        label: const Text('Apple', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await authService.signInWithApple();
                          if (context.mounted) showToast(context, tr.signedInWithApple);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.currentMode, required this.onChanged});

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    return Row(
      children: [
        _themeCard(
          context: context,
          mode: ThemeMode.system,
          label: tr.systemTheme,
          icon: HugeIcons.strokeRoundedLaptop,
          isSelected: currentMode == ThemeMode.system,
        ),
        const SizedBox(width: AppSpace.xs),
        _themeCard(
          context: context,
          mode: ThemeMode.light,
          label: tr.lightTheme,
          icon: HugeIcons.strokeRoundedSun03,
          isSelected: currentMode == ThemeMode.light,
        ),
        const SizedBox(width: AppSpace.xs),
        _themeCard(
          context: context,
          mode: ThemeMode.dark,
          label: tr.darkTheme,
          icon: HugeIcons.strokeRoundedMoon02,
          isSelected: currentMode == ThemeMode.dark,
        ),
      ],
    );
  }

  Widget _themeCard({
    required BuildContext context,
    required ThemeMode mode,
    required String label,
    required IconGlyph icon,
    required bool isSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(mode),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpace.xs),
          decoration: BoxDecoration(
            color: isSelected ? scheme.surfaceContainerHighest : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.6),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon,
                size: 18,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.currentLocale, required this.onChanged});

  final String currentLocale;
  final ValueChanged<String> onChanged;

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        final scheme = Theme.of(ctx).colorScheme;
        final tr = ctx.strings;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr.selectLanguage,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.sm),
                    itemCount: AppLanguage.supported.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final lang = AppLanguage.supported[index];
                      final isSelected = currentLocale == lang.code;
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: isSelected
                              ? Border.all(color: scheme.primary.withValues(alpha: 0.35))
                              : null,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.primary.withValues(alpha: 0.18)
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lang.badge,
                              style: text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? scheme.primary : scheme.onSurface,
                              ),
                            ),
                          ),
                          title: Text(
                            lang.nativeName,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: lang.nativeName != lang.name
                              ? Text(
                                  lang.name,
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: scheme.primary, size: 22)
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            onChanged(lang.code);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final lang = AppLanguage.fromCode(currentLocale);

    return InkWell(
      onTap: () => _showLanguageBottomSheet(context),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            AppIcon(HugeIcons.strokeRoundedGlobe02, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                '${lang.nativeName} (${lang.name})',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                lang.badge,
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Icon(Icons.keyboard_arrow_down_rounded, color: scheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

