import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/shell/view/add_menu_sheet.dart';

/// Bottom navigation: Home, Calendar, Analytics, Work, Plan.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    ('Home', HugeIcons.strokeRoundedHome01),
    ('Calendar', HugeIcons.strokeRoundedCalendar03),
    ('Work', HugeIcons.strokeRoundedBriefcase01),
    ('Plan', HugeIcons.strokeRoundedTarget02),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: shell,
      floatingActionButton: _DockedAddButton(
        onTap: () {
          HapticFeedback.lightImpact();
          AddMenuSheet.show(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: scheme.surface,
        elevation: isDark ? 2 : 4,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
        height: 68,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Left side (Home, Calendar)
              Expanded(
                child: _NavItem(
                  label: context.strings.home,
                  icon: _tabs[0].$2,
                  selected: shell.currentIndex == 0,
                  onTap:
                      () => shell.goBranch(
                        0,
                        initialLocation: shell.currentIndex == 0,
                      ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: context.strings.calendar,
                  icon: _tabs[1].$2,
                  selected: shell.currentIndex == 1,
                  onTap:
                      () => shell.goBranch(
                        1,
                        initialLocation: shell.currentIndex == 1,
                      ),
                ),
              ),

              // Center gap giving space to the centered docked button
              const SizedBox(width: 54),

              // Right side (Work, Plan)
              Expanded(
                child: _NavItem(
                  label: context.strings.work,
                  icon: _tabs[2].$2,
                  selected: shell.currentIndex == 2,
                  onTap:
                      () => shell.goBranch(
                        2,
                        initialLocation: shell.currentIndex == 2,
                      ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: context.strings.plan,
                  icon: _tabs[3].$2,
                  selected: shell.currentIndex == 3,
                  onTap:
                      () => shell.goBranch(
                        3,
                        initialLocation: shell.currentIndex == 3,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockedAddButton extends StatelessWidget {
  const _DockedAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : scheme.primary).withValues(
              alpha: 0.32,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: AppIcon(
              HugeIcons.strokeRoundedPlusSign,
              size: 24,
              color: scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconGlyph icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).textTheme;
    final color =
        selected
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.colors.fill : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: AppIcon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: scheme.labelSmall?.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
