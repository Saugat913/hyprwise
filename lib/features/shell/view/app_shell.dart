import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/shell/view/add_menu_sheet.dart';

/// Bottom navigation: Home, Calendar, Analytics, Work, Plan.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    ('Home', HugeIcons.strokeRoundedHome01),
    ('Calendar', HugeIcons.strokeRoundedCalendar03),
    ('Work', HugeIcons.strokeRoundedBriefcase01),
    ('Goal', HugeIcons.strokeRoundedTarget02),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shell.currentIndex == 1 && oldWidget.shell.currentIndex != 1) {
      if (getIt.isRegistered<CalendarViewModel>()) {
        getIt<CalendarViewModel>().triggerScrollToNextShift();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: widget.shell,
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
                  icon: AppShell._tabs[0].$2,
                  selected: widget.shell.currentIndex == 0,
                  onTap:
                      () => widget.shell.goBranch(
                        0,
                        initialLocation: widget.shell.currentIndex == 0,
                      ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: context.strings.calendar,
                  icon: AppShell._tabs[1].$2,
                  selected: widget.shell.currentIndex == 1,
                  onTap: () {
                    final isCurrent = widget.shell.currentIndex == 1;
                    widget.shell.goBranch(
                      1,
                      initialLocation: isCurrent,
                    );
                    if (getIt.isRegistered<CalendarViewModel>()) {
                      getIt<CalendarViewModel>().triggerScrollToNextShift();
                    }
                  },
                ),
              ),

              // Center gap giving space to the centered docked button
              const SizedBox(width: 54),

              // Right side (Work, Plan)
              Expanded(
                child: _NavItem(
                  label: context.strings.work,
                  icon: AppShell._tabs[2].$2,
                  selected: widget.shell.currentIndex == 2,
                  onTap:
                      () => widget.shell.goBranch(
                        2,
                        initialLocation: widget.shell.currentIndex == 2,
                      ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: context.strings.goal,
                  icon: AppShell._tabs[3].$2,
                  selected: widget.shell.currentIndex == 3,
                  onTap:
                      () => widget.shell.goBranch(
                        3,
                        initialLocation: widget.shell.currentIndex == 3,
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
              borderRadius: BorderRadius.circular(AppRadius.md),
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
