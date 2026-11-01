import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

const String _googleSvgRaw =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.67v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.16z"/>
  <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.24v3.15C3.26 21.36 7.33 24 12 24z"/>
  <path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.24C.45 8.16 0 9.97 0 12c0 2.03.45 3.84 1.24 5.42l4.04-3.15z"/>
  <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.24 6.58l4.04 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/>
</svg>''';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = getIt<SettingsRepository>();

    return ListenableBuilder(
      listenable: Listenable.merge([settingsRepo, getIt<AuthService>()]),
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final authService = getIt<AuthService>();
        final tr = context.strings;

        if (authService.isAuthenticated ||
            authService.isLoading ||
            authService.isCloudSyncing) {
          return const _AccountSetupSyncScreen();
        }

        void onAuthSuccess() {
          if (!context.mounted) return;
          if (!settingsRepo.settings.onboarded) {
            context.go(AppRoutes.currency);
          } else {
            context.go(AppRoutes.home);
          }
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.page,
                vertical: AppSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),

                  // Single Centered Hyprwise Mark
                  Center(
                    child: SvgPicture.asset(
                      isDark
                          ? 'assets/brandings/hyprwise_logo_white.svg'
                          : 'assets/brandings/hyprwise_logo.svg',
                      width: 72,
                      height: 72,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  Text(
                    'hyprwise',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    tr.loginPitch,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Action Buttons
                  ListenableBuilder(
                    listenable: authService,
                    builder: (context, _) {
                      final loading = authService.isLoading;
                      final targetPlatform = Theme.of(context).platform;
                      final showAppleSignIn =
                          targetPlatform == TargetPlatform.iOS ||
                          targetPlatform == TargetPlatform.macOS;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Google Sign In Button
                          SizedBox(
                            height: AppSize.button,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    isDark
                                        ? const Color(0xFF18181B)
                                        : Colors.white,
                                foregroundColor: scheme.onSurface,
                                side: BorderSide(
                                  color: scheme.outlineVariant,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              onPressed:
                                  loading
                                      ? null
                                      : () async {
                                        await authService.signInWithGoogle();
                                        onAuthSuccess();
                                      },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.string(
                                    _googleSvgRaw,
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: AppSpace.md),
                                  Text(
                                    tr.continueWithGoogle,
                                    style: text.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF1F1F1F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (showAppleSignIn) ...[
                            const SizedBox(height: AppSpace.md),

                            // Apple Sign In Button (iOS / macOS only)
                            SizedBox(
                              height: AppSize.button,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      isDark ? Colors.white : Colors.black,
                                  foregroundColor:
                                      isDark ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed:
                                    loading
                                        ? null
                                        : () async {
                                          await authService.signInWithApple();
                                          onAuthSuccess();
                                        },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.apple,
                                      size: 22,
                                      color:
                                          isDark ? Colors.black : Colors.white,
                                    ),
                                    const SizedBox(width: AppSpace.xs),
                                    Text(
                                      tr.continueWithApple,
                                      style: text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? Colors.black
                                                : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpace.lg),

                          // Divider "or"
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.md,
                                ),
                                child: Text(
                                  tr.orDivider,
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.md),

                          // Continue as Guest (Offline) Button
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: colors.fill.withValues(
                                  alpha: 0.4,
                                ),
                                side: BorderSide(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                              onPressed:
                                  loading
                                      ? null
                                      : () async {
                                        await authService.signInAsGuest();
                                        onAuthSuccess();
                                      },
                              icon: Icon(
                                Icons.offline_bolt_outlined,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                              label: Text(
                                tr.continueAsGuest,
                                style: text.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpace.xl),

                  // Legal Compliance & Security Notice
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          tr.agreeToTermsPrefix,
                          style: text.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showAppTermsDialog(context),
                          child: Text(
                            tr.termsOfService,
                            style: text.bodySmall?.copyWith(
                              fontSize: 11,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          tr.andWord,
                          style: text.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showAppPrivacyPolicyDialog(context),
                          child: Text(
                            tr.privacyPolicy,
                            style: text.bodySmall?.copyWith(
                              fontSize: 11,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          tr.agreeToTermsSuffix,
                          style: text.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Center(
                    child: Text(
                      tr.offlineSecurityBadge,
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountSetupSyncScreen extends StatefulWidget {
  const _AccountSetupSyncScreen();

  @override
  State<_AccountSetupSyncScreen> createState() => _AccountSetupSyncScreenState();
}

class _AccountSetupSyncScreenState extends State<_AccountSetupSyncScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.94,
    end: 1.06,
  ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

  Timer? _navTimer;

  @override
  void dispose() {
    _pulseController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  void _checkAndNavigate() {
    final authService = getIt<AuthService>();
    final settingsRepo = getIt<SettingsRepository>();
    if (authService.isAuthenticated &&
        !authService.isLoading &&
        !authService.isCloudSyncing) {
      if (_navTimer != null) return;
      _navTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (!settingsRepo.settings.onboarded) {
          context.go(AppRoutes.currency);
        } else {
          context.go(AppRoutes.home);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndNavigate());
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final tr = context.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = getIt<AuthService>();

    _checkAndNavigate();

    final isAuthDone = authService.isAuthenticated;
    final isSyncing = authService.isCloudSyncing;
    final isAllDone = isAuthDone && !authService.isLoading && !isSyncing;

    final double targetProgress;
    final String statusLabel;

    if (isAllDone) {
      targetProgress = 1.0;
      statusLabel = tr.t(
        'Workspace ready! Opening...',
        ne: 'कार्यक्षेत्र तयार भयो! खुल्दैछ...',
        hi: 'कार्यक्षेत्र तैयार है! खोला जा रहा है...',
        es: '¡Espacio listo! Abriendo...',
        fr: 'Espace prêt ! Ouverture...',
        de: 'Arbeitsbereich bereit! Wird geöffnet...',
        ja: '準備完了！開いています...',
        zh: '准备就绪！正在打开...',
        it: 'Pronto! Apertura...',
      );
    } else if (isSyncing || isAuthDone) {
      targetProgress = 0.65;
      statusLabel = tr.t(
        'Scanning cloud backup & ledger...',
        ne: 'क्लाउड ब्याकअप र लेजर जाँच हुँदैछ...',
        hi: 'क्लाउड बैकअप और बहीखाता स्कैन किया जा रहा है...',
        es: 'Comprobando copia de seguridad en la nube...',
        fr: 'Vérification de la sauvegarde cloud...',
        de: 'Cloud-Backup und Hauptbuch werden gescannt...',
        ja: 'クラウドバックアップを確認しています...',
        zh: '正在扫描云备份和账本...',
        it: 'Scansione del backup cloud in corso...',
      );
    } else {
      targetProgress = 0.30;
      statusLabel = tr.t(
        'Verifying secure credentials...',
        ne: 'सुरक्षित प्रमाणिकरण जाँच हुँदैछ...',
        hi: 'सुरक्षित क्रेडेंशियल सत्यापित किए जा रहे हैं...',
        es: 'Verificando credenciales seguras...',
        fr: 'Vérification des identifiants...',
        de: 'Anmeldedaten werden überprüft...',
        ja: '認証情報を確認しています...',
        zh: '正在验证安全凭据...',
        it: 'Verifica delle credenziali in corso...',
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.page,
              vertical: AppSpace.lg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branded Emblem with ambient glow
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(alpha: 0.08),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            ),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: SvgPicture.asset(
                        isDark
                            ? 'assets/brandings/hyprwise_logo_white.svg'
                            : 'assets/brandings/hyprwise_logo.svg',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Headline
                Text(
                  tr.t(
                    'Checking account & setting up',
                    ne: 'खाता जाँच र सेटअप हुँदैछ',
                    hi: 'खाता जाँच और सेटअप हो रहा है',
                    es: 'Verificando cuenta y configurando',
                    fr: 'Vérification du compte et configuration',
                    de: 'Konto wird überprüft und eingerichtet',
                    ja: 'アカウントを確認・設定しています',
                    zh: '正在检查账户并进行设置',
                    it: 'Verifica dell\'account e configurazione',
                  ),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  tr.t(
                    'Preparing your offline-first financial dashboard & cloud backup securely.',
                    ne:
                        'तपाईंको अफलाइन-पहिलो वित्तीय ड्यासबोर्ड र क्लाउड ब्याकअप सुरक्षित रूपमा तयार गर्दै।',
                    hi:
                        'आपके ऑफ़लाइन-प्रथम वित्तीय डैशबोर्ड और क्लाउड बैकअप को सुरक्षित रूप से तैयार किया जा रहा है।',
                    es:
                        'Preparando de forma segura tu panel financiero y copia en la nube.',
                    fr:
                        'Préparation sécurisée de votre tableau de bord et sauvegarde cloud.',
                    de:
                        'Ihr Offline-First-Dashboard und Cloud-Backup werden sicher vorbereitet.',
                    ja: 'オフライン優先の財務ダッシュボードとクラウドバックアップを安全に準備しています。',
                    zh: '正在安全准备您的离线优先财务仪表板和云备份。',
                    it:
                        'Preparazione sicura della dashboard finanziaria offline e del backup cloud.',
                  ),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Multi-step Progress Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Smooth Progress Bar
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.15, end: targetProgress),
                        builder: (context, value, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isAllDone ? colors.income : scheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    statusLabel,
                                    style: text.labelSmall?.copyWith(
                                      color:
                                          isAllDone
                                              ? colors.income
                                              : scheme.onSurfaceVariant,
                                      fontWeight:
                                          isAllDone
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${(value * 100).toInt()}%',
                                    style: text.labelSmall?.copyWith(
                                      color:
                                          isAllDone
                                              ? colors.income
                                              : scheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'RedditMono',
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpace.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpace.sm),

                      // Step 1: Authentication
                      _buildStepTile(
                        context: context,
                        title: tr.t(
                          'Verifying credentials & identity',
                          ne: 'प्रमाणिकरण र पहिचान जाँच',
                          hi: 'क्रेडेंशियल और पहचान का सत्यापन',
                          es: 'Verificando credenciales e identidad',
                          fr: 'Vérification des identifiants et de l\'identité',
                          de: 'Anmeldedaten und Identität werden überprüft',
                          ja: '認証情報とIDを確認しています',
                          zh: '正在验证凭据和身份',
                          it: 'Verifica credenziali e identità',
                        ),
                        isDone: isAuthDone,
                        isActive: !isAuthDone,
                      ),

                      // Step 2: Cloud Backup & Ledger
                      _buildStepTile(
                        context: context,
                        title: tr.t(
                          'Checking cloud backups & ledger',
                          ne: 'क्लाउड ब्याकअप र लेजर जाँच',
                          hi: 'क्लाउड बैकअप और बहीखाता जाँच',
                          es: 'Comprobando copias de seguridad en la nube',
                          fr: 'Vérification des sauvegardes et du grand livre',
                          de: 'Cloud-Backups und Hauptbuch werden geprüft',
                          ja: 'クラウドバックアップと元帳を確認しています',
                          zh: '正在检查云备份和账本',
                          it: 'Verifica backup cloud e registro',
                        ),
                        isDone: isAllDone || (!isSyncing && isAuthDone),
                        isActive: isSyncing,
                      ),

                      // Step 3: Local Workspace Vault
                      _buildStepTile(
                        context: context,
                        title: tr.t(
                          'Securing offline-first database vault',
                          ne: 'अफलाइन-पहिलो डेटाबेस सुरक्षित गरिँदै',
                          hi: 'ऑफ़लाइन डेटाबेस वॉल्ट को सुरक्षित किया जा रहा है',
                          es: 'Asegurando bóveda local offline-first',
                          fr: 'Sécurisation de la base de données hors ligne',
                          de: 'Lokaler Datenbank-Tresor wird eingerichtet',
                          ja: 'ローカルデータベースを安全に構築しています',
                          zh: '正在安全配置本地数据库',
                          it: 'Protezione del database locale offline-first',
                        ),
                        isDone: isAllDone,
                        isActive: isAuthDone && !isSyncing && !isAllDone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Offline-First Privacy Reassurance Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tr.offlineSecurityBadge,
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTile({
    required BuildContext context,
    required String title,
    required bool isDone,
    required bool isActive,
  }) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          if (isDone)
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: colors.income,
            )
          else if (isActive)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            )
          else
            Icon(
              Icons.radio_button_unchecked,
              size: 18,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              title,
              style: text.bodySmall?.copyWith(
                color:
                    isDone
                        ? scheme.onSurface
                        : (isActive ? scheme.primary : scheme.onSurfaceVariant),
                fontWeight:
                    isDone || isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
