import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/category_repository.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  TransactionType _selectedType = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final categoryRepo = getIt<CategoryRepository>();
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final tr = context.strings;

    return ListenableBuilder(
      listenable: categoryRepo,
      builder: (context, _) {
        final categories = TransactionCategories.forType(_selectedType);

        return Scaffold(
          appBar: AppTopBar(
            title: tr.categoriesAndMerchants,
            actions: [
              TopBarAction(
                HugeIcons.strokeRoundedPlusSign,
                tooltip: tr.addCategory,
                onPressed: () => _showAddCategoryDialog(context, categoryRepo),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xxl),
              children: [
                // Type selector
                SegmentedTabs<TransactionType>(
                  options: {
                    TransactionType.expense: tr.expenseCategories,
                    TransactionType.income: tr.incomeCategories,
                  },
                  value: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(height: AppSpace.lg),

                // Explanation
                Text(
                  tr.isNepali
                      ? 'कुनै पनि वर्गमा ट्याप गरी नयाँ व्यापारी थप्न वा वर्ग सम्पादन गर्न सक्नुहुन्छ।'
                      : 'Tap on any category to add custom merchant shortcuts or manage custom categories.',
                  style: text.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                for (final cat in categories) ...[
                  _CategoryCard(
                    category: cat,
                    merchants: TransactionCategories.merchantsFor(cat.value),
                    onAddMerchant: () => _showAddMerchantDialog(context, categoryRepo, cat),
                    onDeleteMerchant: (m) => categoryRepo.removeMerchant(categoryKey: cat.value, merchant: m),
                    onDeleteCategory: cat.isCustom
                        ? () => _confirmDeleteCategory(context, categoryRepo, cat)
                        : null,
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],

              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, CategoryRepository repo) {
    final nameCtrl = TextEditingController();
    var type = _selectedType;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final insets = MediaQuery.of(ctx).viewInsets;

          final tr = context.strings;
          return Padding(
            padding: EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, insets.bottom + AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr.createCustomCategory, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpace.md),
                SegmentedTabs<TransactionType>(
                  options: {
                    TransactionType.expense: tr.expense,
                    TransactionType.income: tr.income,
                  },
                  value: type,
                  onChanged: (val) => setSheetState(() => type = val),
                ),
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: tr.categoryName,
                    hintText: tr.categoryNameHint,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppIcon(HugeIcons.strokeRoundedGridView, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  tr.saveCategory,
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      showToast(context, tr.pleaseEnterCategoryName);
                      return;
                    }
                    Navigator.of(sheetCtx).pop();
                    await repo.addCategory(label: name, type: type);
                    if (context.mounted) {
                      showToast(context, '${tr.categoryName}: "$name"');
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMerchantDialog(BuildContext context, CategoryRepository repo, TransactionCategory category) {
    final ctrl = TextEditingController();
    final tr = context.strings;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        final insets = MediaQuery.of(sheetCtx).viewInsets;

        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, insets.bottom + AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${tr.addMerchant}: ${category.label}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                tr.t(
                  'This store or payee will appear in quick suggestions when logging ${category.label.toLowerCase()}.',
                  ne: 'यो स्टोर वा भुक्तानीकर्ता नयाँ कारोबार दर्ता गर्दा सुझावमा देखिनेछ।',
                  es: 'Este comercio aparecerá en las sugerencias rápidas al registrar ${category.label.toLowerCase()}.',
                  fr: 'Ce commerce apparaîtra dans les suggestions pour ${category.label.toLowerCase()}.',
                  de: 'Dieser Händler wird in den Vorschlägen für ${category.label.toLowerCase()} angezeigt.',
                  ja: '${category.label} の記録時にクイック提案として表示されます。',
                  zh: '记录 ${category.label} 时将出现在快捷推荐中。',
                  it: 'Questo esercente apparirà nei suggerimenti rapidi per ${category.label.toLowerCase()}.',
                ),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: tr.merchantOrPayee,
                  hintText: category.type == TransactionType.expense
                      ? 'McDonald\'s, 7-Eleven'
                      : 'Upwork, Client X',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: AppIcon(HugeIcons.strokeRoundedStore01, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                tr.addMerchant,
                onPressed: () async {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) {
                    showToast(context, tr.pleaseEnterName);
                    return;
                  }
                  Navigator.of(sheetCtx).pop();
                  await repo.addMerchant(categoryKey: category.value, merchant: text);
                  if (context.mounted) {
                    showToast(context, '"$text" → ${category.label}');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryRepository repo, TransactionCategory category) async {
    final tr = context.strings;
    final confirmed = await showConfirmDialog(
      context,
      title: '${tr.delete} "${category.label}"?',
      message: tr.t(
        'Existing transactions will keep their history, but this category won\'t be suggested for new transactions.',
        ne: 'पुराना कारोबारहरू सुरक्षित रहनेछन्, तर यो वर्ग नयाँ कारोबारका लागि सुझावमा आउने छैन।',
        es: 'Las transacciones existentes conservarán su historial, pero no se sugerirá para nuevas.',
        fr: 'Les transactions existantes conserveront leur historique, mais cette catégorie ne sera plus suggérée.',
        de: 'Bestehende Transaktionen bleiben erhalten, aber diese Kategorie wird nicht mehr vorgeschlagen.',
        ja: '既存の取引履歴は保持されますが、新規取引時の提案には表示されなくなります。',
        zh: '已有交易记录将保留，但新交易将不再推荐此分类。',
        it: 'Le transazioni esistenti manterranno la cronologia, ma questa categoria non sarà più suggerita.',
      ),
      confirmLabel: tr.delete,
      cancelLabel: tr.cancel,
    );
    if (confirmed && context.mounted) {
      await repo.deleteCategory(category.value);
      if (context.mounted) {
        showToast(context, tr.categoryRemoved);
      }
    }
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.merchants,
    required this.onAddMerchant,
    required this.onDeleteMerchant,
    this.onDeleteCategory,
  });

  final TransactionCategory category;
  final List<String> merchants;
  final VoidCallback onAddMerchant;
  final void Function(String merchant) onDeleteMerchant;
  final VoidCallback? onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = context.colors;
    final tr = context.strings;

    final isBuiltIn = !category.isCustom;
    final defaultList = TransactionCategories.defaultMerchants[category.value] ?? const [];

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: category.type == TransactionType.income
                      ? colors.income.withValues(alpha: 0.12)
                      : colors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: AppIcon(
                  category.type == TransactionType.income
                      ? HugeIcons.strokeRoundedMoneyReceive02
                      : HugeIcons.strokeRoundedGridView,
                  size: 16,
                  color: category.type == TransactionType.income ? colors.income : colors.expense,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      isBuiltIn ? tr.systemDefault : tr.customCategory,
                      style: text.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (category.isCustom && onDeleteCategory != null)
                IconButton(
                  tooltip: tr.deleteCategory,
                  icon: AppIcon(
                    HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: colors.expense,
                  ),
                  onPressed: onDeleteCategory,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final m in merchants)
                InputChip(
                  label: Text(m, style: text.labelSmall),
                  onDeleted: !defaultList.contains(m)
                      ? () => onDeleteMerchant(m)
                      : null,
                  deleteIconColor: theme.colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ActionChip(
                avatar: const AppIcon(HugeIcons.strokeRoundedPlusSign, size: 14),
                label: Text(tr.addStore, style: text.labelSmall),
                onPressed: onAddMerchant,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
