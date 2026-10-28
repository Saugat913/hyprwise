import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_dialogs.dart';

/// One question per screen: back arrow, segmented progress, close, big CTA.
/// Every creation flow (transaction, account, job, goal, shift...) uses this.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.step,
    required this.steps,
    required this.title,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.onBack,
    this.onClose,
    this.confirmClose = false,
    this.discardTitle,
    this.primaryKind = AppButtonKind.primary,
    this.secondaryLabel,
    this.onSecondary,
  });

  /// 0-based current step; [steps] is the total (progress segments).
  final int step;
  final int steps;
  final String title;
  final String? subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  /// Ask "Discard this?" before closing (flows that hold typed input).
  final bool confirmClose;
  final String? discardTitle;
  final AppButtonKind primaryKind;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  Future<void> _close(BuildContext context) async {
    if (confirmClose) {
      final discard = await showConfirmDialog(
        context,
        title: discardTitle ?? 'Discard this?',
        message: 'What you entered will be lost.',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep editing',
      );
      if (!discard || !context.mounted) return;
    }
    if (onClose != null) {
      onClose!();
    } else if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Back goes to the previous step; on the first step it leaves the flow.
  void _back(BuildContext context) {
    if (step > 0 && onBack != null) {
      onBack!();
    } else {
      _close(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.page,
              AppSpace.md,
              AppSpace.page,
              AppSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      HugeIcons.strokeRoundedArrowLeft01,
                      onPressed: () => _back(context),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < steps; i++) ...[
                            Expanded(
                              child: Container(
                                height: AppSize.progressStep,
                                decoration: BoxDecoration(
                                  color:
                                      i <= step
                                          ? scheme.onSurface
                                          : scheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                            ),
                            if (i < steps - 1)
                              const SizedBox(width: AppSpace.sm),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    RoundIconButton(
                      HugeIcons.strokeRoundedCancel01,
                      onPressed: () => _close(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xxxl),
                Text(title, style: text.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(subtitle!, style: text.bodySmall),
                ],
                const SizedBox(height: AppSpace.xxl),
                Expanded(child: SingleChildScrollView(child: child)),
                const SizedBox(height: AppSpace.md),
                AppButton(
                  primaryLabel,
                  onPressed: onPrimary,
                  kind: primaryKind,
                ),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  AppButton(
                    secondaryLabel!,
                    onPressed: onSecondary,
                    kind: AppButtonKind.text,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
