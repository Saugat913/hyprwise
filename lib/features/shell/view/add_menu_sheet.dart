import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

abstract final class AddMenuSheet {
  static Future<void> show(BuildContext context) => showAddMenu(context);
}

/// 2-Column Grid "What would you like to add?" sheet.
Future<void> showAddMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) {
      void go(String route) {
        Navigator.of(ctx).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.push(route);
          }
        });
      }

      final colors = ctx.colors;
      final scheme = Theme.of(ctx).colorScheme;
      final tr = ctx.strings;

      final items = [
        _AddItem(
          title: tr.expense,
          subtitle: tr.logMoneySpent,
          icon: HugeIcons.strokeRoundedMoneySend02,
          iconColor: colors.expense,
          iconBg: colors.expense.withValues(alpha: 0.12),
          onTap: () => go('${AppRoutes.addTransaction}?type=expense'),
        ),
        _AddItem(
          title: tr.income,
          subtitle: tr.salaryAndPay,
          icon: HugeIcons.strokeRoundedMoneyReceive02,
          iconColor: colors.income,
          iconBg: colors.income.withValues(alpha: 0.12),
          onTap: () => go('${AppRoutes.addTransaction}?type=income'),
        ),
        _AddItem(
          title: tr.depositSavings,
          subtitle: tr.fundAGoal,
          icon: HugeIcons.strokeRoundedPiggyBank,
          iconColor: const Color(0xFF1F7A45),
          iconBg: const Color(0xFF1F7A45).withValues(alpha: 0.12),
          onTap: () => go(AppRoutes.plan),
        ),
        _AddItem(
          title: tr.scheduleShift,
          subtitle: tr.scheduleHours,
          icon: HugeIcons.strokeRoundedClock01,
          iconColor: scheme.primary,
          iconBg: scheme.primary.withValues(alpha: 0.12),
          onTap: () => go(AppRoutes.scheduleShift),
        ),
        _AddItem(
          title: tr.startShift,
          subtitle: tr.liveTimeTracking,
          icon: HugeIcons.strokeRoundedPlay,
          iconColor: colors.income,
          iconBg: colors.income.withValues(alpha: 0.12),
          onTap: () => go(AppRoutes.startShift),
        ),
        _AddItem(
          title: tr.lendBorrow,
          subtitle: tr.debtsAndIous,
          icon: HugeIcons.strokeRoundedUserGroup,
          iconColor: colors.warning,
          iconBg: colors.warning.withValues(alpha: 0.12),
          onTap: () => go(AppRoutes.debts),
        ),
        _AddItem(
          title: tr.savingsGoal,
          subtitle: tr.setTargetSavings,
          icon: HugeIcons.strokeRoundedTarget02,
          iconColor: scheme.primary,
          iconBg: scheme.primary.withValues(alpha: 0.12),
          onTap: () => go(AppRoutes.addGoal),
        ),
        _AddItem(
          title: tr.workplaceJob,
          subtitle: tr.hourlyRateAndDays,
          icon: HugeIcons.strokeRoundedBriefcase01,
          iconColor: scheme.primary,
          iconBg: scheme.primary.withValues(alpha: 0.12),
          onTap: () => go(AppRoutes.addJob),
        ),
        _AddItem(
          title: tr.categories,
          subtitle: tr.customTagsAndStores,
          icon: HugeIcons.strokeRoundedGridView,
          iconColor: scheme.primary,
          iconBg: scheme.primary.withValues(alpha: 0.12),
          onTap: () => go(AppRoutes.categories),
        ),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.whatWouldYouLikeToAdd,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                tr.chooseActionToRecordOrPlan,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpace.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpace.sm,
                  mainAxisSpacing: AppSpace.sm,
                  childAspectRatio: 1.6,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _GridCard(item: item);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AddItem {
  const _AddItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconGlyph icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.item});

  final _AddItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                alignment: Alignment.center,
                child: AppIcon(item.icon, size: 18, color: item.iconColor),
              ),
              const SizedBox(height: AppSpace.xs + 2),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
