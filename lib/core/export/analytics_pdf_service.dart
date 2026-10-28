import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:finance_tracker/core/export/export_service.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

abstract final class AnalyticsPdfService {
  /// Generates the branded PDF document for the active analytics state
  static Future<File> generatePdf(AnalyticsViewModel vm) async {
    final pdf = pw.Document();

    final (start, end) = vm.dateRange;
    final isExpense = vm.activeType == TransactionType.expense;
    final typeName = isExpense ? 'Spending' : 'Income';
    final currency = vm.baseCurrency;
    final totalMinor = vm.activeTotalMinor;
    final totalFormatted = '$currency ${(totalMinor / 100).toStringAsFixed(2)}';
    final startDateStr = DateFormatter.numeric(start);
    final endDateStr = DateFormatter.numeric(end);
    final nowFormatted = DateFormat('MMM d, yyyy · h:mm a').format(DateTime.now());

    // Load brand icon if available
    pw.ImageProvider? brandLogo;
    try {
      final logoBytes = await rootBundle.load('assets/brand/app-icon/hyprwise-app-icon-1024.png');
      brandLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Colors matching Hyprwise branding
    final primaryColor = PdfColor.fromHex('#FF6500'); // Hyprwise Brand Orange
    final darkColor = PdfColor.fromHex('#1F2726'); // Hyprwise Ink
    final secondaryTextColor = PdfColor.fromHex('#64748B');
    final surfaceColor = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#E2E8F0');
    final accentGreen = PdfColor.fromHex('#16A34A');
    final accentOrange = PdfColor.fromHex('#EA580C');
    final accentColor = isExpense ? accentOrange : accentGreen;

    final categories = vm.categoryBreakdown;
    final topMerchants = vm.topMerchants;
    final transactions = vm.filteredTransactions;
    final baseTotal = totalMinor > 0 ? totalMinor : 1;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    if (brandLogo != null) ...[
                      pw.Container(
                        width: 24,
                        height: 24,
                        margin: const pw.EdgeInsets.only(right: 8),
                        child: pw.Image(brandLogo),
                      ),
                    ],
                    pw.Text(
                      'HYPRWISE',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.Text(
                      ' · Analytics Report',
                      style: pw.TextStyle(
                        color: secondaryTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  nowFormatted,
                  style: pw.TextStyle(color: secondaryTextColor, fontSize: 9),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated with Hyprwise · Offline & Private Financial Tracking',
                  style: pw.TextStyle(color: secondaryTextColor, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(color: secondaryTextColor, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          pw.SizedBox(height: 12),

          // Title & Period Banner
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$typeName Analytics',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Period: $startDateStr to $endDateStr (${vm.dateFilter.label})',
                    style: pw.TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: isExpense ? PdfColor.fromHex('#FFF7ED') : PdfColor.fromHex('#F0FDF4'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: isExpense ? PdfColor.fromHex('#FDBA74') : PdfColor.fromHex('#86EFAC'),
                    width: 0.8,
                  ),
                ),
                child: pw.Text(
                  isExpense ? 'EXPENSE REPORT' : 'INCOME REPORT',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Overview Metric Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricCard(
                  title: 'Total $typeName',
                  value: totalFormatted,
                  valueColor: accentColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textColor: darkColor,
                  secondaryColor: secondaryTextColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard(
                  title: 'Transactions',
                  value: '${transactions.length}',
                  valueColor: darkColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textColor: darkColor,
                  secondaryColor: secondaryTextColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard(
                  title: 'Categories',
                  value: '${categories.length}',
                  valueColor: darkColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textColor: darkColor,
                  secondaryColor: secondaryTextColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard(
                  title: 'Top Category',
                  value: categories.isNotEmpty ? categories.first.label : 'None',
                  subtitle: categories.isNotEmpty
                      ? '${((categories.first.amountMinor / baseTotal) * 100).toStringAsFixed(1)}%'
                      : null,
                  valueColor: darkColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textColor: darkColor,
                  secondaryColor: secondaryTextColor,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // Visual Chart: Category Share Breakdown
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderColor, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CATEGORY BREAKDOWN & SHARE',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Text(
                      'Share of total $typeName',
                      style: pw.TextStyle(fontSize: 9, color: secondaryTextColor),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                if (categories.isEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Text(
                      'No category transactions in this period.',
                      style: pw.TextStyle(color: secondaryTextColor, fontSize: 10),
                    ),
                  )
                else
                  for (final cat in categories) ...[
                    _buildCategoryChartBar(
                      label: cat.label,
                      amountMinor: cat.amountMinor,
                      totalMinor: baseTotal,
                      currency: currency,
                      barColor: primaryColor,
                      textColor: darkColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    pw.SizedBox(height: 8),
                  ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Top Merchants Table (if any)
          if (topMerchants.isNotEmpty) ...[
            pw.Text(
              'TOP MERCHANTS / PAYEES',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              headers: ['Rank', 'Merchant / Payee', 'Category', 'Count', 'Amount'],
              data: [
                for (var i = 0; i < topMerchants.take(8).length; i++)
                  [
                    '#${i + 1}',
                    topMerchants[i].name,
                    topMerchants[i].category,
                    '${topMerchants[i].count} txns',
                    '$currency ${(topMerchants[i].amountMinor / 100).toStringAsFixed(2)}',
                  ],
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Transactions Register
          pw.Text(
            'TRANSACTION REGISTER (${transactions.length} records)',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Text(
              'No transactions recorded in this period.',
              style: pw.TextStyle(color: secondaryTextColor, fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: darkColor,
              ),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              headers: ['Date', 'Category', 'Description / Note', 'Amount'],
              data: [
                for (final t in transactions.take(100))
                  [
                    DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(t.occurredAt)),
                    t.category,
                    t.note != null && t.note!.isNotEmpty ? t.note! : '—',
                    '$currency ${(t.amountMinor / 100).toStringAsFixed(2)}',
                  ],
              ],
            ),
        ],
      ),
    );

    // Save PDF to Public Downloads directory
    final targetDir = await ExportService.getPublicDownloadsDirectory();
    final dateStr = DateFormatter.numeric(DateTime.now(), locale: 'en').replaceAll('/', '-');
    final fileName = 'hyprwise_${typeName.toLowerCase()}_report_$dateStr.pdf';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save(), flush: true);

    return file;
  }

  static pw.Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required PdfColor valueColor,
    required PdfColor surfaceColor,
    required PdfColor borderColor,
    required PdfColor textColor,
    required PdfColor secondaryColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: surfaceColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 8, color: secondaryColor, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 1),
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 7.5, color: secondaryColor),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryChartBar({
    required String label,
    required int amountMinor,
    required int totalMinor,
    required String currency,
    required PdfColor barColor,
    required PdfColor textColor,
    required PdfColor secondaryTextColor,
  }) {
    final fraction = totalMinor > 0 ? (amountMinor / totalMinor).clamp(0.0, 1.0) : 0.0;
    final percentStr = (fraction * 100).toStringAsFixed(1);
    final amountStr = '$currency ${(amountMinor / 100).toStringAsFixed(2)}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textColor),
            ),
            pw.Text(
              '$amountStr  ($percentStr%)',
              style: pw.TextStyle(fontSize: 8.5, color: secondaryTextColor, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Stack(
          children: [
            pw.Container(
              height: 7,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F1F5F9'),
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.Container(
              height: 7,
              width: 500 * fraction,
              decoration: pw.BoxDecoration(
                color: barColor,
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Interactive export sheet focused strictly on high-quality PDF export
  static Future<void> showPdfExportSheet(BuildContext context, AnalyticsViewModel viewModel) async {
    final isExpense = viewModel.activeType == TransactionType.expense;
    final currency = viewModel.baseCurrency;
    final total = MoneyFormatter.format(viewModel.activeTotalMinor, currency);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        final scheme = Theme.of(ctx).colorScheme;
        final tr = ctx.strings;
        final typeLabel = isExpense ? tr.spending : tr.income;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F7A45).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Color(0xFF1F7A45),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.t('Export Analytics PDF', ne: 'विश्लेषण PDF निर्यात गर्नुहोस्', es: 'Exportar PDF de analíticas', fr: 'Exporter le PDF d\'analyse', de: 'Analyse-PDF exportieren', ja: '分析PDFを出力', zh: '导出分析 PDF', it: 'Esporta PDF analitico'),
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr.t('Branded PDF report with charts & tables', ne: 'चार्ट र तालिकाहरू सहितको PDF रिपोर्ट', es: 'Informe PDF con gráficos y tablas', fr: 'Rapport PDF avec graphiques et tableaux', de: 'PDF-Bericht mit Diagrammen und Tabellen', ja: 'グラフと表を含むPDFレポート', zh: '包含图表与表格的 PDF 报告', it: 'Report PDF con grafici e tabelle'),
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),

                // Report Preview Summary Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.t('Report Type', ne: 'रिपोर्टको प्रकार', es: 'Tipo de informe', fr: 'Type de rapport', de: 'Berichtstyp', ja: 'レポート種類', zh: '报告类型', it: 'Tipo di report'), style: text.bodySmall),
                          Text(
                            '$typeLabel · ${tr.analytics}',
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.periodLabel, style: text.bodySmall),
                          Text(
                            viewModel.dateFilter.label,
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${tr.total} ($typeLabel)', style: text.bodySmall),
                          Text(
                            total,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F7A45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr.t('Format', ne: 'ढाँचा', es: 'Formato', fr: 'Format', de: 'Format', ja: '形式', zh: '格式', it: 'Formato'), style: text.bodySmall),
                          StatusChip(tr.t('PDF DOCUMENT', ne: 'PDF कागजात', es: 'DOCUMENTO PDF', fr: 'DOCUMENT PDF', de: 'PDF-DOKUMENT', ja: 'PDFドキュメント', zh: 'PDF 文档', it: 'DOCUMENTO PDF'), tone: ChipTone.success),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Action Buttons
                FilledButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(tr.saveToDownloadsTitle),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _executePdfExport(context, viewModel, shareAfter: false);
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(tr.shareToAppsTitle),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _executePdfExport(context, viewModel, shareAfter: true);
                  },
                ),
                const SizedBox(height: AppSpace.xs),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _executePdfExport(
    BuildContext context,
    AnalyticsViewModel viewModel, {
    required bool shareAfter,
  }) async {
    try {
      final tr = context.strings;
      showToast(context, tr.t('Generating branded PDF report...', ne: 'PDF रिपोर्ट तयार हुँदैछ...', es: 'Generando informe PDF...', fr: 'Génération du rapport PDF...', de: 'PDF-Bericht wird erstellt...', ja: 'PDFレポートを作成中...', zh: '正在生成 PDF 报告...', it: 'Generazione report PDF...'));
      final file = await generatePdf(viewModel);

      if (!context.mounted) return;

      if (shareAfter) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Hyprwise Analytics Report (${viewModel.dateFilter.label})',
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (ctx) {
            final text = Theme.of(ctx).textTheme;
            final scheme = Theme.of(ctx).colorScheme;
            final trCtx = ctx.strings;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
                  const SizedBox(width: AppSpace.sm),
                  Text(trCtx.exportCompleteTitle, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trCtx.t('Your analytics report was saved as a PDF.', ne: 'तपाईंको विश्लेषण रिपोर्ट PDF को रूपमा सुरक्षित गरियो।', es: 'Tu informe de analíticas se guardó como PDF.', fr: 'Votre rapport d\'analyse a été enregistré en PDF.', de: 'Ihr Analysebericht wurde als PDF gespeichert.', ja: '分析レポートがPDFとして保存されました。', zh: '您的分析报告已保存为 PDF。', it: 'Il tuo report analitico è stato salvato come PDF.')),
                  const SizedBox(height: AppSpace.md),
                  Text(trCtx.fileLocationLabel, style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
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
                      file.path,
                      style: text.bodySmall?.copyWith(fontFamily: 'RedditMono'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(trCtx.done),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(trCtx.shareFileButton),
                  onPressed: () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'PDF Export failed: $e');
      }
    }
  }
}
