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

/// First screen on a fresh install: pitch card with concentric rings design and "Get started".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = getIt<SettingsRepository>();
    final authService = getIt.isRegistered<AuthService>() ? getIt<AuthService>() : null;

    if (settingsRepo.settings.onboarded && (authService?.isAuthenticated ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.home);
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return ListenableBuilder(
      listenable: settingsRepo,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.lg,
                AppSpace.page,
                AppSpace.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/brandings/hyprwise_wordmark_white.svg'
                        : 'assets/brandings/hyprwise_wordmark.svg',
                    height: 26,
                  ),
                  const SizedBox(height: AppSpace.md),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.hero,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ConcentricRingsPainter(
                                  ringColor: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpace.xxl),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  tr.welcomePitch,
                                  style: text.headlineMedium?.copyWith(
                                    color: colors.onHero,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Center(
                    child: Text(
                      tr.offlinePitch,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppButton(
                    tr.getStarted,
                    onPressed: () => context.go(AppRoutes.login),
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

class _ConcentricRingsPainter extends CustomPainter {
  const _ConcentricRingsPainter({required this.ringColor});

  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    // Concentric circles center slightly off the top right edge of the card
    final center = Offset(size.width * 1.05, size.height * 0.16);
    final radii = [
      size.width * 0.28,
      size.width * 0.48,
      size.width * 0.68,
    ];

    for (final r in radii) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor;
}
