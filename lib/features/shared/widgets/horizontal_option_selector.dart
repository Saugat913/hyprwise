import 'package:flutter/material.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Item descriptor for [HorizontalOptionSelector].
class HorizontalOptionItem<T> {
  const HorizontalOptionItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconData,
    this.avatar,
    this.trailing,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconGlyph? icon;
  final IconData? iconData;
  final Widget? avatar;
  final Widget? trailing;
}

/// A horizontal option selector styled after the expense suggester UI.
///
/// Features 12px border radius (AppRadius.md), 1.5px brand outline and
/// 0.08-0.12 alpha tinted background when selected, leading icon/avatar,
/// bold label, and checkmark indicator.
class HorizontalOptionSelector<T> extends StatelessWidget {
  HorizontalOptionSelector({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.height = 54.0,
    this.padding,
    this.shrinkWrap = false,
  }) : assert(
          selectedValue == null ||
              items.isEmpty ||
              items.where((i) => i.value == selectedValue).length == 1,
          "There should be exactly one item with [DropdownButton]'s value: $selectedValue",
        );

  final List<HorizontalOptionItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T>? onChanged;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        shrinkWrap: shrinkWrap,
        padding: padding,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.value == selectedValue;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onChanged != null ? () => onChanged!(item.value) : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary.withValues(alpha: 0.08)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.avatar != null) ...[
                      item.avatar!,
                      const SizedBox(width: AppSpace.sm),
                    ] else if (item.icon != null) ...[
                      AppIcon(
                        item.icon!,
                        size: 18,
                        color: isSelected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpace.xs + 2),
                    ] else if (item.iconData != null) ...[
                      Icon(
                        item.iconData!,
                        size: 18,
                        color: isSelected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpace.xs + 2),
                    ],
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.label,
                          style: text.labelMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color:
                                isSelected ? scheme.primary : scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle!,
                            style: text.bodySmall?.copyWith(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    if (item.trailing != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      item.trailing!,
                    ],
                    if (isSelected) ...[
                      const SizedBox(width: AppSpace.xs + 2),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
