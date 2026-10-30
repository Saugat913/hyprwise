import 'package:flutter/material.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';

/// Boxed input (job name, account name, search) with the design's underline,
/// required asterisk indicator, and error highlighting.
class UnderlineField extends StatelessWidget {
  const UnderlineField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.onChanged,
    this.obscure = false,
    this.autofocus = false,
    this.style,
    this.keyboardType,
    this.isRequired = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final bool autofocus;
  final TextStyle? style;
  final TextInputType? keyboardType;
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
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscure,
          autofocus: autofocus,
          keyboardType: keyboardType,
          style: style ?? text.titleLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            errorStyle: TextStyle(color: colors.expense, fontSize: 12, fontWeight: FontWeight.w500),
            border: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? colors.expense : scheme.outlineVariant,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? colors.expense : scheme.onSurface,
                width: hasError ? 2.0 : 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
