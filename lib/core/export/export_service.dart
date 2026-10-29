import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/export/analytics_pdf_service.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/analytics/data/analytics_tab_data.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

enum ExportFormat {
  csv('csv'),
  json('json'),
  report('txt'),
  analytics('csv'),
  analyticsReport('txt');

  const ExportFormat(this.extension);
  final String extension;

  String get label {
    final tr = AppStrings.current();
    return switch (this) {
      ExportFormat.csv => tr.csvFormatTitle,
      ExportFormat.json => tr.jsonFormatTitle,
      ExportFormat.report => tr.t('Financial Summary Report (.txt)', ne: 'वित्तीय सारांश रिपोर्ट (.txt)', es: 'Informe de resumen financiero (.txt)', fr: 'Rapport financier (.txt)', de: 'Finanzzusammenfassung (.txt)', ja: '財務サマリーレポート (.txt)', zh: '财务摘要报告 (.txt)', it: 'Riepilogo finanziario (.txt)'),
      ExportFormat.analytics => tr.t('Analytics Report (.csv)', ne: 'विश्लेषण रिपोर्ट (.csv)', es: 'Informe de analíticas (.csv)', fr: 'Rapport d\'analyse (.csv)', de: 'Analysereport (.csv)', ja: '分析レポート (.csv)', zh: '分析报告 (.csv)', it: 'Report analitico (.csv)'),
      ExportFormat.analyticsReport => tr.t('Analytics Summary Report (.txt)', ne: 'विश्लेषण सारांश रिपोर्ट (.txt)', es: 'Resumen de analíticas (.txt)', fr: 'Résumé d\'analyse (.txt)', de: 'Analysezusammenfassung (.txt)', ja: '分析サマリー (.txt)', zh: '分析摘要 (.txt)', it: 'Riepilogo analitico (.txt)'),
    };
  }

  String get description {
    final tr = AppStrings.current();
    return switch (this) {
      ExportFormat.csv => tr.csvFormatDesc,
      ExportFormat.json => tr.jsonFormatDesc,
      ExportFormat.report => tr.t('Formatted human-readable financial summary report of balances, income, and goals.', ne: 'मौज्दात, आम्दानी र लक्ष्यहरूको पठनीय वित्तीय सारांश रिपोर्ट।', es: 'Informe legible de saldos, ingresos y metas.', fr: 'Rapport financier lisible des soldes, revenus et objectifs.', de: 'Lesbarer Finanzbericht über Salden, Einnahmen und Ziele.', ja: '残高・収支・目標の読みやすい財務サマリー。', zh: '易读的余额、收支与储蓄目标汇总报告。', it: 'Report leggibile di saldi, entrate e obiettivi.'),
      ExportFormat.analytics => tr.t('Period category breakdowns, top merchants, and spending/income trends.', ne: 'श्रेणीगत विवरण, मुख्य पसलहरू र खर्च/आम्दानी प्रवृति।', es: 'Desglose por categorías, comercios principales y tendencias.', fr: 'Répartition par catégorie, principaux commerçants et tendances.', de: 'Kategorienaufschlüsselung, Top-Händler und Trends.', ja: '期間別のカテゴリ内訳、主な取引先、収支トレンド。', zh: '周期分类明细、主要商户与收支趋势。', it: 'Dettaglio categorie, esercenti principali e trend.'),
      ExportFormat.analyticsReport => tr.t('Human-readable summary of spending/income trends and category statistics.', ne: 'खर्च/आम्दानी प्रवृति र श्रेणी तथ्याङ्कको सारांश रिपोर्ट।', es: 'Resumen legible de tendencias de gastos/ingresos y estadísticas.', fr: 'Résumé lisible des tendances et statistiques par catégorie.', de: 'Lesbare Zusammenfassung von Trends und Kategoriestatistiken.', ja: '収支トレンドとカテゴリ統計のサマリーレポート。', zh: '收支趋势与分类统计的文本摘要报告。', it: 'Riepilogo leggibile dei trend e statistiche per categoria.'),
    };
  }
}

enum ExportDestination {
  downloads,
  share;

  String get label {
    final tr = AppStrings.current();
    return switch (this) {
      ExportDestination.downloads => tr.saveToDownloadsTitle,
      ExportDestination.share => tr.shareToAppsTitle,
    };
  }

  String get description {
    final tr = AppStrings.current();
    return switch (this) {
      ExportDestination.downloads => tr.saveToDownloadsDesc,
      ExportDestination.share => tr.shareToAppsDesc,
    };
  }
}

class ExportResult {
  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
  });

  final String filePath;
  final String fileName;
  final int fileSizeBytes;
}

abstract final class ExportService {
  /// Resolves the public downloads directory across platforms
  static Future<Directory> getPublicDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        return publicDownload;
      }
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir;
      }
    } catch (_) {}

    return await getApplicationDocumentsDirectory();
  }

  /// Generates the exported file content and writes it to disk or shares it
  static Future<ExportResult> exportData({
    required ExportFormat format,
    required ExportDestination destination,
  }) async {
    final dataRepo = getIt<DataRepository>();
    final store = getIt<FinanceStore>();
    final dateStr = DateFormatter.numeric(DateTime.now(), locale: 'en').replaceAll('/', '-');
    final fileName = 'hyprwise_export_$dateStr.${format.extension}';

    String content;
    switch (format) {
      case ExportFormat.json:
        content = await dataRepo.exportJson();
        break;
      case ExportFormat.csv:
        content = await dataRepo.exportCsv();
        break;
      case ExportFormat.report:
        content = await dataRepo.exportSummaryReport(store.baseCurrency);
        break;
      case ExportFormat.analytics:
        final analyticsVm = getIt<AnalyticsViewModel>();
        content = generateAnalyticsCsv(analyticsVm);
        break;
      case ExportFormat.analyticsReport:
        final analyticsVm = getIt<AnalyticsViewModel>();
        content = generateAnalyticsReport(analyticsVm);
        break;
    }

    final targetDir = await getPublicDownloadsDirectory();
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsString(content, flush: true);

    if (destination == ExportDestination.share) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Hyprwise financial export (${format.label})',
        ),
      );
    }

    return ExportResult(
      filePath: file.path,
      fileName: fileName,
      fileSizeBytes: await file.length(),
    );
  }

  /// Interactive Modal Dialog asking for format and destination
  static Future<void> showExportDialog(BuildContext context) async {
    ExportFormat selectedFormat = ExportFormat.csv;
    ExportDestination selectedDestination = ExportDestination.downloads;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final text = Theme.of(ctx).textTheme;
            final scheme = Theme.of(ctx).colorScheme;
            final tr = ctx.strings;

            final isPro = getIt<SubscriptionService>().isPro;

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, AppSpace.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr.exportFinancialData, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            tr.chooseExportFormatSub,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
                        children: [
                          // Format Selection
                          Text(tr.chooseFormatLabel, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpace.sm),
                          HorizontalOptionSelector<ExportFormat>(
                            height: 64,
                            selectedValue: selectedFormat,
                            onChanged: (fmt) => setState(() => selectedFormat = fmt),
                            items: [
                              for (final fmt in ExportFormat.values)
                                HorizontalOptionItem<ExportFormat>(
                                  value: fmt,
                                  label: fmt.label,
                                  subtitle: fmt.description,
                                  trailing: (!isPro && (fmt == ExportFormat.report || fmt == ExportFormat.analyticsReport))
                                      ? const ProCrownBadge(isCompact: true)
                                      : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.lg),

                          // Destination Selection
                          Text(tr.deliveryMethodLabel, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpace.sm),
                          HorizontalOptionSelector<ExportDestination>(
                            height: 64,
                            selectedValue: selectedDestination,
                            onChanged: (dest) => setState(() => selectedDestination = dest),
                            items: [
                              for (final dest in ExportDestination.values)
                                HorizontalOptionItem<ExportDestination>(
                                  value: dest,
                                  label: dest.label,
                                  subtitle: dest.description,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.page),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(tr.cancel),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                _handleExportExecution(context, selectedFormat, selectedDestination);
                              },
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(tr.exportNowButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _handleExportExecution(
    BuildContext context,
    ExportFormat format,
    ExportDestination destination,
  ) async {
    final subService = getIt<SubscriptionService>();
    final isProFormat = format == ExportFormat.report || format == ExportFormat.analyticsReport;
    if (isProFormat && !subService.isPro) {
      if (context.mounted) {
        showProUpgradeSheet(
          context,
          title: 'Reports Require Hyprwise Pro',
          message: 'Summary reports and executive insights are a Hyprwise Pro feature. Standard CSV spreadsheets remain completely free.',
          featureHighlight: 'export',
        );
      }
      return;
    }

    try {
      final result = await exportData(format: format, destination: destination);

      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) {
            final text = Theme.of(ctx).textTheme;
            final scheme = Theme.of(ctx).colorScheme;
            final tr = ctx.strings;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: AppSpace.sm),
                  Text(tr.exportCompleteTitle, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.exportCompleteMsg(tr.localizeDigits((result.fileSizeBytes / 1024).toStringAsFixed(1))),
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(tr.fileLocationLabel, style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpace.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: SelectableText(
                      result.filePath,
                      style: text.bodySmall?.copyWith(fontFamily: 'RedditMono'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(tr.copyPathButton),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.filePath));
                    showToast(context, tr.pathCopiedToast);
                  },
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(tr.shareFileButton),
                  onPressed: () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(ShareParams(files: [XFile(result.filePath)]));
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Export error: $e');
      }
    }
  }

  /// Generates CSV format for comprehensive analytics covering overview and all tab views
  static String generateAnalyticsCsv(AnalyticsViewModel vm) {
    final (start, end) = vm.dateRange;
    final currency = vm.baseCurrency;
    final startDateStr = DateFormatter.numeric(start);
    final endDateStr = DateFormatter.numeric(end);

    final incomeData = vm.txTabData(TransactionType.income);
    final expenseData = vm.txTabData(TransactionType.expense);
    final lendData = vm.debtTabData(DebtType.lent);
    final borrowData = vm.debtTabData(DebtType.borrowed);
    final workData = vm.workTabData();

    final incomeTotal = incomeData.totalMinor;
    final expenseTotal = expenseData.totalMinor;
    final netSavingsMinor = incomeTotal - expenseTotal;
    final savingsRate = incomeTotal > 0
        ? (((incomeTotal - expenseTotal) / incomeTotal) * 100).clamp(0.0, 100.0)
        : 0.0;
    final netDebtMinor = lendData.totalMinor - borrowData.totalMinor;

    final rows = <List<dynamic>>[];

    // Report Header
    rows.add(['[HYPRWISE COMPREHENSIVE ANALYTICS REPORT]']);
    rows.add(['Period', '$startDateStr to $endDateStr']);
    rows.add(['Date Filter', vm.dateFilter.label]);
    rows.add(['Base Currency', currency]);
    if (vm.selectedCategory != null) {
      rows.add(['Category Filter', vm.selectedCategory!]);
    }
    if (vm.selectedAccountId != null) {
      final acc = vm.accounts.firstWhere((a) => a.id == vm.selectedAccountId, orElse: () => vm.accounts.first);
      rows.add(['Account Filter', acc.name]);
    }
    rows.add([]);

    // 1. Overview Metrics
    rows.add(['[OVERVIEW METRICS]']);
    rows.add(['Metric', 'Value ($currency)']);
    rows.add(['Total Income', (incomeTotal / 100).toStringAsFixed(2)]);
    rows.add(['Total Expenses', (expenseTotal / 100).toStringAsFixed(2)]);
    rows.add(['Net Savings', (netSavingsMinor / 100).toStringAsFixed(2)]);
    rows.add(['Savings Rate', '${savingsRate.toStringAsFixed(1)}%']);
    rows.add(['Total Lent', (lendData.totalMinor / 100).toStringAsFixed(2)]);
    rows.add(['Total Borrowed', (borrowData.totalMinor / 100).toStringAsFixed(2)]);
    rows.add(['Net Debt Position (Lent - Borrowed)', (netDebtMinor / 100).toStringAsFixed(2)]);
    rows.add(['Work Earnings', (workData.earningsMinor / 100).toStringAsFixed(2)]);
    rows.add(['Work Shifts Count', workData.shiftCount]);
    rows.add(['Work Hours Worked', (workData.totalMinutes / 60.0).toStringAsFixed(2)]);
    rows.add([]);

    // 2. Income Breakdown
    rows.add(['[INCOME BREAKDOWN]']);
    rows.add(['Total Income ($currency)', (incomeTotal / 100).toStringAsFixed(2)]);
    rows.add(['Transactions Count', incomeData.count]);
    rows.add(['Average Income ($currency)', (incomeData.averageMinor / 100).toStringAsFixed(2)]);
    rows.add(['CATEGORY BREAKDOWN']);
    rows.add(['Category', 'Amount ($currency)', 'Share (%)']);
    final incTotalMinor = incomeTotal > 0 ? incomeTotal : 1;
    for (final c in incomeData.categories) {
      final share = ((c.amountMinor / incTotalMinor) * 100).toStringAsFixed(1);
      final amt = (c.amountMinor / 100).toStringAsFixed(2);
      rows.add([c.label, amt, '$share%']);
    }
    rows.add(['TOP MERCHANTS / PAYEES']);
    rows.add(['Source / Payer', 'Category', 'Count', 'Total Amount ($currency)']);
    for (final m in incomeData.top) {
      final amt = (m.amountMinor / 100).toStringAsFixed(2);
      rows.add([m.name, m.category, m.count, amt]);
    }
    rows.add([]);

    // 3. Expense Breakdown
    rows.add(['[EXPENSE BREAKDOWN]']);
    rows.add(['Total Expenses ($currency)', (expenseTotal / 100).toStringAsFixed(2)]);
    rows.add(['Transactions Count', expenseData.count]);
    rows.add(['Average Expense ($currency)', (expenseData.averageMinor / 100).toStringAsFixed(2)]);
    rows.add(['CATEGORY BREAKDOWN']);
    rows.add(['Category', 'Amount ($currency)', 'Share (%)']);
    final expTotalMinor = expenseTotal > 0 ? expenseTotal : 1;
    for (final c in expenseData.categories) {
      final share = ((c.amountMinor / expTotalMinor) * 100).toStringAsFixed(1);
      final amt = (c.amountMinor / 100).toStringAsFixed(2);
      rows.add([c.label, amt, '$share%']);
    }
    rows.add(['TOP MERCHANTS / PAYEES']);
    rows.add(['Merchant', 'Category', 'Count', 'Total Amount ($currency)']);
    for (final m in expenseData.top) {
      final amt = (m.amountMinor / 100).toStringAsFixed(2);
      rows.add([m.name, m.category, m.count, amt]);
    }
    rows.add([]);

    // 4. Lending Breakdown
    rows.add(['[LENDING BREAKDOWN]']);
    rows.add(['Total Lent ($currency)', (lendData.totalMinor / 100).toStringAsFixed(2)]);
    rows.add(['Outstanding ($currency)', (lendData.outstandingMinor / 100).toStringAsFixed(2)]);
    rows.add(['Settled ($currency)', (lendData.settledMinor / 100).toStringAsFixed(2)]);
    rows.add(['Records Count', lendData.count]);
    rows.add(['PARTIES BREAKDOWN']);
    rows.add(['Borrower / Party', 'Amount ($currency)', 'Debts Count']);
    for (final p in lendData.parties) {
      rows.add([p.name, (p.amountMinor / 100).toStringAsFixed(2), p.count]);
    }
    rows.add([]);

    // 5. Borrowing Breakdown
    rows.add(['[BORROWING BREAKDOWN]']);
    rows.add(['Total Borrowed ($currency)', (borrowData.totalMinor / 100).toStringAsFixed(2)]);
    rows.add(['Outstanding ($currency)', (borrowData.outstandingMinor / 100).toStringAsFixed(2)]);
    rows.add(['Settled ($currency)', (borrowData.settledMinor / 100).toStringAsFixed(2)]);
    rows.add(['Records Count', borrowData.count]);
    rows.add(['PARTIES BREAKDOWN']);
    rows.add(['Lender / Party', 'Amount ($currency)', 'Debts Count']);
    for (final p in borrowData.parties) {
      rows.add([p.name, (p.amountMinor / 100).toStringAsFixed(2), p.count]);
    }
    rows.add([]);

    // 6. Shifts & Work Breakdown
    rows.add(['[SHIFTS & WORK BREAKDOWN]']);
    rows.add(['Completed Shifts Count', workData.shiftCount]);
    rows.add(['Total Hours Worked', (workData.totalMinutes / 60.0).toStringAsFixed(2)]);
    rows.add(['Total Work Earnings ($currency)', (workData.earningsMinor / 100).toStringAsFixed(2)]);
    rows.add(['Overtime Minutes', workData.overtimeMinutes]);
    rows.add(['Break Minutes', workData.breakMinutes]);
    rows.add(['Average Shift Minutes', workData.averageShiftMinutes]);
    rows.add(['JOBS BREAKDOWN']);
    rows.add(['Job Name', 'Hours', 'Shifts', 'Earnings ($currency)']);
    for (final j in workData.jobs) {
      rows.add([j.job.name, (j.minutes / 60.0).toStringAsFixed(2), j.shifts, (j.earningsMinor / 100).toStringAsFixed(2)]);
    }
    rows.add([]);

    // 7. Transactions Register
    rows.add(['[TRANSACTIONS REGISTER]']);
    rows.add(['TRANSACTIONS']);
    rows.add(['Date', 'Type', 'Category', 'Merchant / Note', 'Amount ($currency)']);
    for (final t in vm.filteredTransactions) {
      final d = DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(t.occurredAt));
      final cat = TransactionCategories.fromValue(t.category, t.type == 'income' ? TransactionType.income : TransactionType.expense).label;
      final amt = (t.amountMinor / 100).toStringAsFixed(2);
      rows.add([d, t.type, cat, t.note ?? '', amt]);
    }

    return csv.encode(rows);
  }

  /// Generates a human-readable text report for comprehensive analytics covering all tabs
  static String generateAnalyticsReport(AnalyticsViewModel vm) {
    final (start, end) = vm.dateRange;
    final currency = vm.baseCurrency;
    final startDateStr = DateFormatter.numeric(start);
    final endDateStr = DateFormatter.numeric(end);

    final incomeData = vm.txTabData(TransactionType.income);
    final expenseData = vm.txTabData(TransactionType.expense);
    final lendData = vm.debtTabData(DebtType.lent);
    final borrowData = vm.debtTabData(DebtType.borrowed);
    final workData = vm.workTabData();

    final incomeTotal = incomeData.totalMinor;
    final expenseTotal = expenseData.totalMinor;
    final netSavingsMinor = incomeTotal - expenseTotal;
    final savingsRate = incomeTotal > 0
        ? (((incomeTotal - expenseTotal) / incomeTotal) * 100).clamp(0.0, 100.0)
        : 0.0;
    final netDebtMinor = lendData.totalMinor - borrowData.totalMinor;
    final incTotalMinor = incomeTotal > 0 ? incomeTotal : 1;
    final expTotalMinor = expenseTotal > 0 ? expenseTotal : 1;

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('HYPRWISE ANALYTICS REPORT - COMPREHENSIVE');
    buffer.writeln('Period: $startDateStr to $endDateStr (${vm.dateFilter.label})');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Base Currency: $currency');
    if (vm.selectedCategory != null) buffer.writeln('Category Filter: ${vm.selectedCategory}');
    if (vm.selectedAccountId != null) {
      final acc = vm.accounts.firstWhere((a) => a.id == vm.selectedAccountId, orElse: () => vm.accounts.first);
      buffer.writeln('Account Filter: ${acc.name}');
    }
    buffer.writeln('========================================\n');

    // Section 1: Overview Metrics
    buffer.writeln('OVERVIEW METRICS');
    buffer.writeln('- Total Income: $currency ${(incomeTotal / 100).toStringAsFixed(2)}');
    buffer.writeln('- Total Expenses: $currency ${(expenseTotal / 100).toStringAsFixed(2)}');
    buffer.writeln('- Net Savings: $currency ${(netSavingsMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Savings Rate: ${savingsRate.toStringAsFixed(1)}%');
    buffer.writeln('- Total Lent: $currency ${(lendData.totalMinor / 100).toStringAsFixed(2)} (Outstanding: $currency ${(lendData.outstandingMinor / 100).toStringAsFixed(2)})');
    buffer.writeln('- Total Borrowed: $currency ${(borrowData.totalMinor / 100).toStringAsFixed(2)} (Outstanding: $currency ${(borrowData.outstandingMinor / 100).toStringAsFixed(2)})');
    buffer.writeln('- Net Debt: $currency ${(netDebtMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Work Earnings: $currency ${(workData.earningsMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Work Shifts: ${workData.shiftCount} (${(workData.totalMinutes / 60.0).toStringAsFixed(1)} hrs)');
    buffer.writeln('');

    // Section 2: Income Breakdown
    buffer.writeln('INCOME BREAKDOWN');
    buffer.writeln('Total Income: $currency ${(incomeTotal / 100).toStringAsFixed(2)} (${incomeData.count} transactions, avg: $currency ${(incomeData.averageMinor / 100).toStringAsFixed(2)})');
    buffer.writeln('CATEGORY BREAKDOWN');
    for (final c in incomeData.categories) {
      final share = ((c.amountMinor / incTotalMinor) * 100).toStringAsFixed(1);
      final amt = (c.amountMinor / 100).toStringAsFixed(2);
      buffer.writeln('- ${c.label}: $currency $amt ($share%)');
    }
    buffer.writeln('TOP MERCHANTS / PAYEES');
    for (final m in incomeData.top) {
      final amt = (m.amountMinor / 100).toStringAsFixed(2);
      buffer.writeln('- ${m.name} (${m.category}): $currency $amt (${m.count} txns)');
    }
    buffer.writeln('');

    // Section 3: Expense Breakdown
    buffer.writeln('EXPENSE BREAKDOWN');
    buffer.writeln('Total Expenses: $currency ${(expenseTotal / 100).toStringAsFixed(2)} (${expenseData.count} transactions, avg: $currency ${(expenseData.averageMinor / 100).toStringAsFixed(2)})');
    buffer.writeln('CATEGORY BREAKDOWN');
    for (final c in expenseData.categories) {
      final share = ((c.amountMinor / expTotalMinor) * 100).toStringAsFixed(1);
      final amt = (c.amountMinor / 100).toStringAsFixed(2);
      buffer.writeln('- ${c.label}: $currency $amt ($share%)');
    }
    buffer.writeln('TOP MERCHANTS / PAYEES');
    for (final m in expenseData.top) {
      final amt = (m.amountMinor / 100).toStringAsFixed(2);
      buffer.writeln('- ${m.name} (${m.category}): $currency $amt (${m.count} txns)');
    }
    buffer.writeln('');

    // Section 4: Lending Breakdown
    buffer.writeln('LENDING BREAKDOWN');
    buffer.writeln('- Total Lent: $currency ${(lendData.totalMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Outstanding: $currency ${(lendData.outstandingMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Settled: $currency ${(lendData.settledMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('PARTIES BREAKDOWN: ${lendData.parties.length} parties');
    for (final p in lendData.parties) {
      buffer.writeln('- ${p.name}: $currency ${(p.amountMinor / 100).toStringAsFixed(2)} (${p.count} debts)');
    }
    buffer.writeln('');

    // Section 5: Borrowing Breakdown
    buffer.writeln('BORROWING BREAKDOWN');
    buffer.writeln('- Total Borrowed: $currency ${(borrowData.totalMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Outstanding: $currency ${(borrowData.outstandingMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Settled: $currency ${(borrowData.settledMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('PARTIES BREAKDOWN: ${borrowData.parties.length} parties');
    for (final p in borrowData.parties) {
      buffer.writeln('- ${p.name}: $currency ${(p.amountMinor / 100).toStringAsFixed(2)} (${p.count} debts)');
    }
    buffer.writeln('');

    // Section 6: Shifts & Work Breakdown
    buffer.writeln('SHIFTS & WORK BREAKDOWN');
    buffer.writeln('- Total Completed Shifts: ${workData.shiftCount}');
    buffer.writeln('- Total Hours: ${(workData.totalMinutes / 60.0).toStringAsFixed(1)} hrs');
    buffer.writeln('- Total Earnings: $currency ${(workData.earningsMinor / 100).toStringAsFixed(2)}');
    buffer.writeln('- Overtime: ${workData.overtimeMinutes} mins');
    buffer.writeln('- Breaks: ${workData.breakMinutes} mins');
    buffer.writeln('JOBS BREAKDOWN');
    for (final j in workData.jobs) {
      buffer.writeln('- ${j.job.name}: ${(j.minutes / 60.0).toStringAsFixed(1)} hrs, ${j.shifts} shifts, $currency ${(j.earningsMinor / 100).toStringAsFixed(2)}');
    }
    buffer.writeln('');

    buffer.writeln('TRANSACTIONS IN PERIOD: ${vm.filteredTransactions.length} records');
    return buffer.toString();
  }

  /// Interactive dialog specifically tailored for exporting analytics
  static Future<void> showAnalyticsExportDialog(BuildContext context, AnalyticsViewModel viewModel) {
    return AnalyticsPdfService.showPdfExportSheet(context, viewModel);
  }
}
