import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
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
    final settingsRepo = getIt<SettingsRepository>();

    return ListenableBuilder(
      listenable: settingsRepo,
      builder: (context, _) {
        final showFab = settingsRepo.showAssistantFab;

        return Scaffold(
          body: Stack(
            children: [
              shell,
              if (showFab)
                _InteractiveAssistantFab(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final currentLoc = GoRouterState.of(context).uri.path;
                    if (currentLoc != AppRoutes.assistant) {
                      context.push(AppRoutes.assistant);
                    }
                  },
                ),
            ],
          ),
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
                        onTap: () => shell.goBranch(0, initialLocation: shell.currentIndex == 0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: context.strings.calendar,
                        icon: _tabs[1].$2,
                        selected: shell.currentIndex == 1,
                        onTap: () => shell.goBranch(1, initialLocation: shell.currentIndex == 1),
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
                        onTap: () => shell.goBranch(2, initialLocation: shell.currentIndex == 2),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: context.strings.plan,
                        icon: _tabs[3].$2,
                        selected: shell.currentIndex == 3,
                        onTap: () => shell.goBranch(3, initialLocation: shell.currentIndex == 3),
                      ),
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
            color: (isDark ? Colors.black : scheme.primary).withValues(alpha: 0.32),
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
  const _NavItem({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconGlyph icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).textTheme;
    final color = selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant;
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

class _InteractiveAssistantFab extends StatefulWidget {
  const _InteractiveAssistantFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_InteractiveAssistantFab> createState() => _InteractiveAssistantFabState();
}

class _InteractiveAssistantFabState extends State<_InteractiveAssistantFab>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  late final AnimationController _scaleController;
  late final Animation<double> _scale;

  double _bottomOffset = 12.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Ambient breathing pulse for the AI sparkles glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.2, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Spring touch-down animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF5EE6A0);

    return Positioned(
      right: 16,
      bottom: _bottomOffset,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onVerticalDragStart: (_) => setState(() => _isDragging = true),
        onVerticalDragUpdate: (details) {
          setState(() {
            // Dragging up increases bottom offset, dragging down decreases it
            _bottomOffset = (_bottomOffset - details.delta.dy).clamp(12.0, 360.0);
          });
        },
        onVerticalDragEnd: (_) {
          setState(() {
            _isDragging = false;
            // Snap back to standard docked height if near the bottom
            if (_bottomOffset < 36.0) {
              _bottomOffset = 12.0;
            }
          });
          HapticFeedback.selectionClick();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_scale, _pulse]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging ? 1.08 : _scale.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF27272A), Color(0xFF18181B)]
                        : const [Color(0xFF222226), Color(0xFF121214)],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
                      blurRadius: _isDragging ? 16 : 10,
                      offset: Offset(0, _isDragging ? 6 : 3),
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: _isDragging ? 0.55 : _pulse.value),
                      blurRadius: _isDragging ? 14 : 10,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: AppIcon(
                    HugeIcons.strokeRoundedSparkles,
                    size: 22,
                    color: accent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
