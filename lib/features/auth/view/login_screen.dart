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

        if (authService.isCloudSyncing) {
          return const _AccountSetupSyncScreen();
        }

        void onAuthSuccess() {
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
                          ? 'assets/brand/logo/hyprwise-mark-white.svg'
                          : 'assets/brand/logo/hyprwise-mark.svg',
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

class _AccountSetupSyncScreen extends StatelessWidget {
  const _AccountSetupSyncScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 4),
              Icon(
                Icons.cloud_download_outlined,
                size: 48,
                color: scheme.primary,
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                tr.t(
                  'Setting up your account',
                  ne: 'तपाईंको खाता तयार हुँदैछ',
                  hi: 'आपका खाता तैयार हो रहा है',
                  es: 'Estamos configurando tu cuenta',
                  fr: 'Configuration de votre compte',
                  de: 'Ihr Konto wird eingerichtet',
                  ja: 'アカウントを設定しています',
                  zh: '正在设置您的账户',
                  it: 'Stiamo configurando il tuo account',
                ),
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                tr.t(
                  'Downloading your preferences and latest financial data securely.',
                  ne:
                      'तपाईंका प्राथमिकता र पछिल्लो वित्तीय डाटा सुरक्षित रूपमा डाउनलोड हुँदैछ।',
                  hi:
                      'आपकी प्राथमिकताएँ और नवीनतम वित्तीय डेटा सुरक्षित रूप से डाउनलोड हो रहा है।',
                  es:
                      'Descargando de forma segura tus preferencias y los datos financieros más recientes.',
                  fr:
                      'Téléchargement sécurisé de vos préférences et de vos dernières données financières.',
                  de:
                      'Ihre Einstellungen und neuesten Finanzdaten werden sicher heruntergeladen.',
                  ja: '設定と最新の家計データを安全にダウンロードしています。',
                  zh: '正在安全下载您的偏好设置和最新财务数据。',
                  it:
                      'Stiamo scaricando in sicurezza le tue preferenze e gli ultimi dati finanziari.',
                ),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              const LinearProgressIndicator(),
              const Spacer(flex: 5),
            ],
          ),
        ),
      ),
    );
  }
}
