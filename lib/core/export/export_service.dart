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
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
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
                          for (final fmt in ExportFormat.values) ...[
                            OptionTile(
                              title: fmt.label,
                              subtitle: fmt.description,
                              selected: selectedFormat == fmt,
                              trailing: (fmt == ExportFormat.report || fmt == ExportFormat.analyticsReport)
                                  ? const ProCrownBadge(isCompact: true)
                                  : null,
                              onTap: () => setState(() => selectedFormat = fmt),
                            ),
                            const SizedBox(height: AppSpace.sm),
                          ],
                          const SizedBox(height: AppSpace.md),

                          // Destination Selection
                          Text(tr.deliveryMethodLabel, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpace.sm),
                          for (final dest in ExportDestination.values) ...[
                            OptionTile(
                              title: dest.label,
                              subtitle: dest.description,
                              selected: selectedDestination == dest,
                              onTap: () => setState(() => selectedDestination = dest),
                            ),
                            const SizedBox(height: AppSpace.sm),
                          ],
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

  /// Generates CSV format for active analytics period
  static String generateAnalyticsCsv(AnalyticsViewModel vm) {
    final (start, end) = vm.dateRange;
    final isExpense = vm.activeType == TransactionType.expense;
    final typeName = isExpense ? 'Spending' : 'Income';
    final currency = vm.baseCurrency;
    final total = (vm.activeTotalMinor / 100).toStringAsFixed(2);
    final startDateStr = DateFormatter.numeric(start);
    final endDateStr = DateFormatter.numeric(end);

    final rows = <List<dynamic>>[];
    rows.add(['HYPRWISE ANALYTICS REPORT - $typeName']);
    rows.add(['Period', '$startDateStr to $endDateStr']);
    rows.add(['Date Filter', vm.dateFilter.label]);
    rows.add(['Total $typeName ($currency)', total]);
    if (vm.selectedCategory != null) {
      rows.add(['Category Filter', vm.selectedCategory!]);
    }
    if (vm.selectedAccountId != null) {
      final acc = vm.accounts.firstWhere((a) => a.id == vm.selectedAccountId, orElse: () => vm.accounts.first);
      rows.add(['Account Filter', acc.name]);
    }
    rows.add([]);

    // Category Breakdown
    rows.add(['CATEGORY BREAKDOWN']);
    rows.add(['Category', 'Amount ($currency)', 'Share (%)']);
    final cats = vm.categoryBreakdown;
    final totalMinor = vm.activeTotalMinor > 0 ? vm.activeTotalMinor : 1;
    for (final c in cats) {
      final share = ((c.amountMinor / totalMinor) * 100).toStringAsFixed(1);
      final amt = (c.amountMinor / 100).toStringAsFixed(2);
      rows.add([c.label, amt, '$share%']);
    }
    rows.add([]);

    // Top Merchants
    rows.add(['TOP MERCHANTS / PAYEES']);
    rows.add(['Merchant', 'Category', 'Transactions Count', 'Total Amount ($currency)']);
    for (final m in vm.topMerchants) {
      final amt = (m.amountMinor / 100).toStringAsFixed(2);
      rows.add([m.name, m.category, m.count, amt]);
    }
    rows.add([]);

    // Transactions detail
    rows.add(['TRANSACTIONS']);
    rows.add(['Date', 'Type', 'Category', 'Merchant / Note', 'Amount ($currency)']);
    for (final t in vm.filteredTransactions) {
      final d = DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(t.occurredAt));
      final amt = (t.amountMinor / 100).toStringAsFixed(2);
      rows.add([d, t.type, t.category, t.note ?? '', amt]);
    }

    return csv.encode(rows);
  }

  /// Generates a human-readable text report for active analytics period
  static String generateAnalyticsReport(AnalyticsViewModel vm) {
    final (start, end) = vm.dateRange;
    final isExpense = vm.activeType == TransactionType.expense;
    final typeName = isExpense ? 'Spending' : 'Income';
    final currency = vm.baseCurrency;
    final total = (vm.activeTotalMinor / 100).toStringAsFixed(2);
    final startDateStr = DateFormatter.numeric(start);
    final endDateStr = DateFormatter.numeric(end);

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('HYPRWISE ANALYTICS REPORT - $typeName');
    buffer.writeln('Period: $startDateStr to $endDateStr (${vm.dateFilter.label})');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total $typeName: $currency $total');
    if (vm.selectedCategory != null) buffer.writeln('Category Filter: ${vm.selectedCategory}');
    buffer.writeln('========================================\n');

    buffer.writeln('CATEGORY BREAKDOWN');
    final cats = vm.categoryBreakdown;
    final totalMinor = vm.activeTotalMinor > 0 ? vm.activeTotalMinor : 1;
    for (final c in cats) {
      final share = ((c.amountMinor / totalMinor) * 100).toStringAsFixed(1);
      final amt = (c.amountMinor / 100).toStringAsFixed(2);
      buffer.writeln('- ${c.label}: $currency $amt ($share%)');
    }
    buffer.writeln('');

    buffer.writeln('TOP MERCHANTS / PAYEES');
    for (final m in vm.topMerchants) {
      final amt = (m.amountMinor / 100).toStringAsFixed(2);
      buffer.writeln('- ${m.name} (${m.category}): $currency $amt (${m.count} txns)');
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
