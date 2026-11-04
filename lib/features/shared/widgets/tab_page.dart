import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';

/// Scrolling body of a bottom-tab screen: small overline, big title, actions.
/// "Wednesday, 14 Oct / Overview  [bell] [filters]".
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.children,
    this.overline,
    this.actions = const [],
    this.floating,
    this.empty,
    this.showBackButton = false,
  });

  final String title;
  final String? overline;
  final List<Widget> actions;
  final List<Widget> children;
  final bool showBackButton;

  /// Floating widget bottom-right (the Assistant pill).
  final Widget? floating;

  /// When set, replaces [children] below the header (empty states).
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: floating,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xxxl),
          children: [
            if (showBackButton && context.canPop()) ...[
              Row(
                children: [
                  RoundIconButton(
                    HugeIcons.strokeRoundedArrowLeft01,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!showBackButton && !Navigator.of(context).canPop()) ...[
                  SvgPicture.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/brandings/hyprwise_logo_white.svg'
                        : 'assets/brandings/hyprwise_logo.svg',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overline != null)
                        Text(
                          overline!,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        title,
                        style: text.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                for (final action in actions) ...[const SizedBox(width: AppSpace.xs), action],
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            if (empty != null)
              SizedBox(height: 420, child: empty)
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

/// Floating dark "Assistant" pill (Work, Plan).
class AssistantPill extends StatelessWidget {
  const AssistantPill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: AppButton(context.strings.hyprAi, onPressed: onPressed, icon: HugeIcons.strokeRoundedChatBot, compact: true),
      );
}
