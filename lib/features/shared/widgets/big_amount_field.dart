import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';

/// Large number entry: currency prefix + display-size input on an underline
/// with support for required indicator and error highlights.
class BigAmountField extends StatelessWidget {
  const BigAmountField({
    super.key,
    required this.controller,
    required this.currencySymbol,
    this.label,
    this.subtitle,
    this.onChanged,
    this.onCurrencyTap,
    this.autofocus = true,
    this.isRequired = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String currencySymbol;
  final String? label;
  final String? subtitle;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCurrencyTap;
  final bool autofocus;
  final bool isRequired;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label!, style: text.bodySmall),
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: text.bodySmall?.copyWith(
                      color: colors.expense,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (onCurrencyTap != null)
              InkWell(
                onTap: onCurrencyTap,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: hasError ? colors.expense : scheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencySymbol,
                        style: text.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.unfold_more, size: 16, color: scheme.primary),
                    ],
                  ),
                ),
              )
            else
              Text(currencySymbol, style: text.titleLarge?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                style: text.displayMedium?.copyWith(
                  color: hasError ? colors.expense : null,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  enabledBorder: hasError
                      ? UnderlineInputBorder(borderSide: BorderSide(color: colors.expense, width: 1.5))
                      : null,
                  focusedBorder: hasError
                      ? UnderlineInputBorder(borderSide: BorderSide(color: colors.expense, width: 2.0))
                      : null,
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              AppIcon(HugeIcons.strokeRoundedAlertCircle, size: 13, color: colors.expense),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: TextStyle(color: colors.expense, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: text.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
