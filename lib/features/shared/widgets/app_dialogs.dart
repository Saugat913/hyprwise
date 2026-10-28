import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Confirm dialog (Discard / Delete / Erase / End shift). Returns true on confirm.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: AppSpace.sm),
            Text(message, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              confirmLabel,
              kind: destructive ? AppButtonKind.danger : AppButtonKind.primary,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: AppSpace.xs),
            AppButton(cancelLabel, kind: AppButtonKind.text, onPressed: () => Navigator.pop(ctx, false)),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Toast notification with auto-detected or explicit success/error state and optional action.
void showToast(
  BuildContext context,
  String message, {
  bool? isError,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = context.colors;
  final messenger = ScaffoldMessenger.of(context);
  final lower = message.toLowerCase();
  final hasError = isError ??
      (lower.contains('error') ||
          lower.contains('failed') ||
          lower.contains('could not') ||
          lower.contains('please enter') ||
          lower.contains('invalid') ||
          lower.contains('त्रुटि') ||
          lower.contains('सकिएन') ||
          lower.contains('प्रविष्ट गर्नुहोस्'));

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        margin: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: hasError ? BorderSide(color: colors.expense.withValues(alpha: 0.5), width: 1.2) : BorderSide.none,
        ),
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasError ? colors.expense : colors.income,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(
                  hasError ? HugeIcons.strokeRoundedAlertCircle : HugeIcons.strokeRoundedTick02,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: hasError ? const Color(0xFFFCA5A5) : null,
                  fontWeight: hasError ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                child: Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onHero,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
}

void showErrorToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showToast(
    context,
    message,
    isError: true,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
