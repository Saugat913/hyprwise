import 'package:flutter/material.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';

/// Shows a scrollable, overflow-safe bottom sheet to pick from all supported languages.
Future<void> showAppLanguageSheet(BuildContext context) async {
  final settingsRepo = getIt<SettingsRepository>();
  final currentLocale = settingsRepo.localeCode;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final scheme = Theme.of(ctx).colorScheme;
      final tr = ctx.strings;

      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpace.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.selectLanguage,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.sm),
                  itemCount: AppLanguage.supported.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final lang = AppLanguage.supported[index];
                    final isSelected = currentLocale == lang.code;
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: isSelected
                            ? Border.all(color: scheme.primary.withValues(alpha: 0.35))
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.primary.withValues(alpha: 0.18)
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lang.badge,
                              style: text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? scheme.primary : scheme.onSurface,
                              ),
                            ),
                          ),
                          title: Text(
                            lang.nativeName,
                            style: text.titleSmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            lang.name,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: scheme.primary, size: 20)
                              : null,
                          onTap: () async {
                            await settingsRepo.setLocaleCode(lang.code);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
