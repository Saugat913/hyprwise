import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Header for pushed screens: round back button on the left,
/// inline title in the app bar title slot, and round action buttons on the right.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.showBackButton,
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool? showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shouldShowBack = showBackButton ?? true;

    void handleBack() {
      if (onBack != null) {
        onBack!();
      } else if (context.canPop()) {
        context.pop();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.xs),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              if (shouldShowBack) ...[
                RoundIconButton(
                  HugeIcons.strokeRoundedArrowLeft01,
                  onPressed: handleBack,
                ),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: titleWidget ??
                    (title != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title!,
                                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  subtitle!,
                                  style: text.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink()),
              ),
              for (final a in actions) ...[
                const SizedBox(width: AppSpace.xs),
                a,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Round 40px action for [AppTopBar.actions].
class TopBarAction extends StatelessWidget {
  const TopBarAction(this.glyph, {super.key, required this.onPressed, this.tooltip});

  final IconGlyph glyph;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = RoundIconButton(glyph, onPressed: onPressed);
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
