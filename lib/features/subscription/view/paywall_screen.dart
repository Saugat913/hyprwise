import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

/// Unified RevenueCat Paywall screen powered by RevenueCat's official UI SDK.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subService = getIt<SubscriptionService>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (subService.isConfigured) {
      return Scaffold(
        body: PaywallView(
          displayCloseButton: true,
          onDismiss: () {
            if (context.mounted) context.pop();
          },
          onPurchaseCompleted: (customerInfo, storeTransaction) async {
            await subService.checkEntitlement();
            if (context.mounted) {
              showToast(context, 'Welcome to Hyprwise Pro!');
              context.pop();
            }
          },
          onRestoreCompleted: (customerInfo) async {
            await subService.checkEntitlement();
            if (context.mounted) {
              showToast(context, 'Purchases restored successfully');
              context.pop();
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyprwise Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  HugeIcons.strokeRoundedCrown,
                  size: 36,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'RevenueCat Paywall',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Please select and publish a Paywall template in your RevenueCat Dashboard under "Paywalls" for project "tilvane".',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpace.xl),
              AppButton(
                'Launch RevenueCat Paywall',
                onPressed: () async {
                  final result = await subService.presentPaywall();
                  if (result == PaywallResult.purchased || result == PaywallResult.restored) {
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
