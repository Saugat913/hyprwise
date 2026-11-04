import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
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
        final authService = getIt<AuthService>();
        final tr = context.strings;

        final showSyncScreen =
            authService.isAuthenticated ||
            authService.isLoading ||
            authService.isCloudSyncing;

        void onAuthSuccess() {
          if (!context.mounted) return;
          if (!authService.isReturningUser ||
              !settingsRepo.settings.onboarded) {
            context.go(AppRoutes.currency);
          } else {
            context.go(AppRoutes.home);
          }
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: showSyncScreen
              ? const _AccountSetupSyncScreen(key: ValueKey('sync'))
              : Scaffold(
                  key: const ValueKey('login'),
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
                          const Center(
                            child: BrandEmblem(size: 72),
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
                          _SocialButtons(onAuthSuccess: onAuthSuccess),

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
                ),
        );
      },
    );
  }
}

/// Sign-in buttons with immediate tap feedback (spinner while the account
/// picker / provider flow is in progress).
class _SocialButtons extends StatefulWidget {
  const _SocialButtons({required this.onAuthSuccess});

  final VoidCallback onAuthSuccess;

  @override
  State<_SocialButtons> createState() => _SocialButtonsState();
}

class _SocialButtonsState extends State<_SocialButtons> {
  String? _busy; // 'google' | 'apple'

  Future<void> _run(String provider, Future<dynamic> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = provider);
    try {
      final user = await action();
      if (user != null) widget.onAuthSuccess();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = context.strings;
    final authService = getIt<AuthService>();
    final targetPlatform = Theme.of(context).platform;
    final showAppleSignIn =
        targetPlatform == TargetPlatform.iOS ||
        targetPlatform == TargetPlatform.macOS;
    final disabled = _busy != null;

    Widget spinner(Color c) => SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: c),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSize.button,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outlineVariant, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 0,
            ),
            onPressed:
                disabled
                    ? null
                    : () => _run('google', authService.signInWithGoogle),
            child:
                _busy == 'google'
                    ? spinner(scheme.primary)
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(_googleSvgRaw, width: 20, height: 20),
                        const SizedBox(width: AppSpace.md),
                        Text(
                          tr.continueWithGoogle,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1F1F1F),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
        if (showAppleSignIn) ...[
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: AppSize.button,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              onPressed:
                  disabled
                      ? null
                      : () => _run('apple', authService.signInWithApple),
              child:
                  _busy == 'apple'
                      ? spinner(isDark ? Colors.black : Colors.white)
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.apple,
                            size: 22,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            tr.continueWithApple,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountSetupSyncScreen extends StatefulWidget {
  const _AccountSetupSyncScreen({super.key});

  @override
  State<_AccountSetupSyncScreen> createState() =>
      _AccountSetupSyncScreenState();
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
        if (!authService.isReturningUser || !settingsRepo.settings.onboarded) {
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
    final tr = context.strings;
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

    return SetupLayout(
      animation: _scaleAnimation,
      title:
          authService.hasRestoredCloudData ||
                  isSyncing ||
                  authService.isReturningUser
              ? tr.t(
                'We are loading your previous data',
                ne: 'तपाईंको अघिल्लो डेटा लोड गरिँदैछ',
                hi: 'आपका पिछला डेटा लोड किया जा रहा है',
                es: 'Cargando tus datos anteriores',
                fr: 'Chargement de vos données précédentes',
                de: 'Wir laden Ihre bisherigen Daten',
                ja: '以前のデータを読み込んでいます',
                zh: '正在加载您之前的数据',
                it: 'Stiamo caricando i tuoi dati precedenti',
              )
              : tr.t(
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
      subtitle:
          authService.hasRestoredCloudData ||
                  isSyncing ||
                  authService.isReturningUser
              ? tr.t(
                'Please wait a minute while we restore your accounts, shifts, and preferences.',
                ne:
                    'तपाईंका खाताहरू, सिफ्टहरू र प्राथमिकताहरू लोड हुँदैछन्, कृपया एकछिन पर्खनुहोस्।',
                hi:
                    'कृपया कुछ समय प्रतीक्षा करें जब तक हम आपके खाते, शिफ्ट और प्राथमिकताएं पुनर्स्थापित कर रहे हैं।',
                es:
                    'Espera un minuto mientras restauramos tus cuentas, turnos y preferencias.',
                fr:
                    'Veuillez patienter pendant que nous restaurons vos comptes et préférences.',
                de:
                    'Bitte warten Sie einen Moment, während wir Ihre Konten und Einstellungen wiederherstellen.',
                ja: 'アカウント、シフト、設定を復元しています。少々お待ちください。',
                zh: '请稍候，我们正在恢复您的账户、班次和偏好设置。',
                it:
                    'Attendi un momento mentre ripristiniamo i tuoi account, turni e preferenze.',
              )
              : tr.t(
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
      progress: targetProgress,
      statusLabel: statusLabel,
      done: isAllDone,
      steps: [
        SetupStepTile(
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
        SetupStepTile(
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
        SetupStepTile(
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
    );
  }
}
