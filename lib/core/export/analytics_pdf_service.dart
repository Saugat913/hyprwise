import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/export/export_service.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/analytics/data/analytics_tab_data.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

abstract final class AnalyticsPdfService {
  /// Generates the branded PDF document for the active analytics state
  static Future<File> generatePdf(
    AnalyticsViewModel vm, {
    bool? isProOverride,
    Directory? outputDirectory,
    int activeTabIndex = 0,
  }) async {
    final pdf = pw.Document();

    final (start, end) = vm.dateRange;
    final currency = vm.baseCurrency;
    final startDateStr = DateFormatter.numeric(start);
    final endDateStr = DateFormatter.numeric(end);
    final nowFormatted = DateFormat('MMM d, yyyy · h:mm a').format(DateTime.now());

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
    final transactions = vm.filteredTransactions;

    // Determine Pro status (for watermark removal)
    final subService = getIt.isRegistered<SubscriptionService>() ? getIt<SubscriptionService>() : null;
    final isPro = isProOverride ?? (subService?.isPro ?? false);

    // Load brand icon if available from brandings
    pw.ImageProvider? brandLogo;
    for (final path in [
      'assets/brandings/hyprwise_app_icon_1024.png',
      'assets/brandings/hyprwise_mark.png',
      'assets/brandings/hyprwise_app_icon_light.png',
    ]) {
      try {
        final logoBytes = await rootBundle.load(path);
        brandLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
        break;
      } catch (_) {}
    }

    // Load watermark banner image from asset banner
    pw.ImageProvider? watermarkBannerImage;
    for (final path in [
      'assets/brandings/branding_banner_light.png',
      'assets/brandings/branding_banner_dark.png',
    ]) {
      try {
        final bannerBytes = await rootBundle.load(path);
        watermarkBannerImage = pw.MemoryImage(bannerBytes.buffer.asUint8List());
        break;
      } catch (_) {}
    }

    // Colors: Hyprwise Brand Orange used exclusively for the top header branding.
    // The rest of the document uses a clean black-and-white / monochrome palette.
    final brandPrimary = PdfColor.fromHex('#FF6500'); // Hyprwise Brand Orange
    final darkColor = PdfColor.fromHex('#111827'); // Primary deep black/charcoal
    final secondaryTextColor = PdfColor.fromHex('#4B5563'); // Muted secondary text
    final surfaceColor = PdfColor.fromHex('#F9FAFB'); // Light grey surface background
    final borderColor = PdfColor.fromHex('#E5E7EB'); // Subtle neutral border
    final barFillColor = PdfColor.fromHex('#1F2937'); // Solid dark fill for category bars
    final barTrackColor = PdfColor.fromHex('#E5E7EB'); // Neutral track for category bars
    final watermarkColor = PdfColor.fromHex('#E5E7EB'); // Subtle watermark grey for free tier
    final incomeColor = PdfColor.fromHex('#10B981'); // Emerald green for income
    final expenseColor = PdfColor.fromHex('#EF4444'); // Coral red for expense

    // Load custom TTF font for complete Unicode / glyph coverage across all languages
    pw.Font? customFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/GoogleSans.ttf');
      customFont = pw.Font.ttf(fontData);
    } catch (_) {}

    final pdfTheme = customFont != null
        ? pw.ThemeData.withFont(
            base: customFont,
            bold: customFont,
            italic: customFont,
            boldItalic: customFont,
          )
        : pw.ThemeData.base();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pdfTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          buildBackground: (context) {
            if (isPro) {
              return pw.SizedBox();
            }
            // Hyprwise watermark across the page for the free tier using brand asset banner
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Transform.rotate(
                  angle: -0.40,
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      if (watermarkBannerImage != null) ...[
                        pw.Opacity(
                          opacity: 0.12,
                          child: pw.Image(watermarkBannerImage, width: 340),
                        ),
                        pw.SizedBox(height: 12),
                      ],
                      pw.Text(
                        'HYPRWISE',
                        style: pw.TextStyle(
                          color: watermarkColor,
                          fontSize: 76,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 6),
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
          // Top Document Branding Header (Rendered once on Page 1)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                children: [
                  if (brandLogo != null) ...[
                    pw.Container(
                      width: 26,
                      height: 26,
                      margin: const pw.EdgeInsets.only(right: 8),
                      child: pw.Image(brandLogo),
                    ),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'HYPRWISE',
                        style: pw.TextStyle(
                          color: brandPrimary,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      pw.Text(
                        'Personal Finance & Shift Management',
                        style: pw.TextStyle(color: secondaryTextColor, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: borderColor, width: 0.8),
                    ),
                    child: pw.Text(
                      switch (activeTabIndex) {
                        1 => 'INCOME REPORT',
                        2 => 'EXPENSE REPORT',
                        3 => 'LENT DEBTS REPORT',
                        4 => 'BORROWED DEBTS REPORT',
                        5 => 'SHIFTS & WORK REPORT',
                        _ => 'ANALYTICS OVERVIEW',
                      },
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    nowFormatted,
                    style: pw.TextStyle(color: secondaryTextColor, fontSize: 7.5),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: brandPrimary, thickness: 1.2),
          pw.SizedBox(height: 10),

          // Period & Currency Info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    switch (activeTabIndex) {
                      1 => 'Income & Earnings Analytics',
                      2 => 'Expense & Spending Analytics',
                      3 => 'Lending & Debt Receivables Summary',
                      4 => 'Borrowing & Debt Payables Summary',
                      5 => 'Work Shifts & Wages Summary',
                      _ => 'Comprehensive Analytics Summary',
                    },
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Period: $startDateStr - $endDateStr (${_filterLabelEnglish(vm.dateFilter)})',
                    style: pw.TextStyle(fontSize: 9.5, color: secondaryTextColor),
                  ),
                ],
              ),
              pw.Text(
                'Base Currency: $currency',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          ..._buildSectionsForTab(
            activeTabIndex: activeTabIndex,
            vm: vm,
            currency: currency,
            incomeTotal: incomeTotal,
            expenseTotal: expenseTotal,
            netSavingsMinor: netSavingsMinor,
            savingsRate: savingsRate,
            netDebtMinor: netDebtMinor,
            incomeData: incomeData,
            expenseData: expenseData,
            lendData: lendData,
            borrowData: borrowData,
            workData: workData,
            transactions: transactions,
            darkColor: darkColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            secondaryTextColor: secondaryTextColor,
            incomeColor: incomeColor,
            expenseColor: expenseColor,
            barFillColor: barFillColor,
            barTrackColor: barTrackColor,
          ),
        ],
      ),
    );

    // Save PDF to a safe working directory first (guaranteed zero PathAccessException)
    Directory targetDir;
    if (outputDirectory != null) {
      targetDir = outputDirectory;
    } else {
      try {
        targetDir = await getTemporaryDirectory();
      } catch (_) {
        try {
          targetDir = await getApplicationDocumentsDirectory();
        } catch (_) {
          targetDir = Directory.systemTemp;
        }
      }
    }
    final dateStr = DateFormatter.numeric(DateTime.now(), locale: 'en').replaceAll('/', '-');
    final fileName = 'hyprwise_analytics_report_$dateStr.pdf';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save(), flush: true);

    return file;
  }

  static List<pw.Widget> _buildSectionsForTab({
    required int activeTabIndex,
    required AnalyticsViewModel vm,
    required String currency,
    required int incomeTotal,
    required int expenseTotal,
    required int netSavingsMinor,
    required double savingsRate,
    required int netDebtMinor,
    required AnalyticsTxTabData incomeData,
    required AnalyticsTxTabData expenseData,
    required AnalyticsDebtTabData lendData,
    required AnalyticsDebtTabData borrowData,
    required AnalyticsWorkTabData workData,
    required List<dynamic> transactions,
    required PdfColor darkColor,
    required PdfColor surfaceColor,
    required PdfColor borderColor,
    required PdfColor secondaryTextColor,
    required PdfColor incomeColor,
    required PdfColor expenseColor,
    required PdfColor barFillColor,
    required PdfColor barTrackColor,
  }) {
    switch (activeTabIndex) {
      case 1: // Income Tab Report
        final incomeTxns = transactions.where((t) => t.type == 'income').toList();
        return [
          pw.Text('1. INCOME OVERVIEW & PERFORMANCE', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Total Income', value: '$currency ${(incomeTotal / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Transactions', value: '${incomeData.count} records', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Avg per Transaction', value: '$currency ${(incomeData.count > 0 ? (incomeTotal / incomeData.count / 100) : 0).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          pw.SizedBox(height: 16),
          if (vm.dualChartData.hasAnyData) ...[
            pw.Text('2. DAILY INCOME ACTIVITY', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
            pw.SizedBox(height: 8),
            _buildTrendChart(data: vm.dualChartData, currency: currency, incomeColor: incomeColor, expenseColor: expenseColor, trackColor: barTrackColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryTextColor: secondaryTextColor),
            pw.SizedBox(height: 16),
          ],
          pw.Text('3. INCOME CATEGORIES (${incomeData.categories.length})', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: borderColor, width: 0.7)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (incomeData.categories.isEmpty)
                  pw.Text('No income records for this period.', style: pw.TextStyle(fontSize: 8.5, color: secondaryTextColor))
                else
                  for (final cat in incomeData.categories) ...[
                    _buildCategoryChartBar(label: _categoryEnglishName(cat.categoryKey, cat.label), amountMinor: cat.amountMinor, totalMinor: incomeTotal > 0 ? incomeTotal : 1, currency: currency, barColor: barFillColor, trackColor: barTrackColor, textColor: darkColor, secondaryTextColor: secondaryTextColor),
                    pw.SizedBox(height: 6),
                  ],
              ],
            ),
          ),
          if (incomeData.top.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('4. TOP INCOME SOURCES & PAYERS', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Payer / Income Source', 'Category', 'Count', 'Total Received'],
              data: [for (final s in incomeData.top) [_safeText(s.name), _categoryEnglishName('', s.category), '${s.count} txns', '$currency ${(s.amountMinor / 100).toStringAsFixed(2)}']],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text('5. ITEMIZED INCOME REGISTER (${incomeTxns.length} records)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (incomeTxns.isEmpty)
            pw.Text('No income transactions in this period.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              headers: ['Date', 'Category', 'Description / Note', 'Amount Received'],
              data: [
                for (final t in incomeTxns.take(120))
                  [DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(t.occurredAt)), _categoryEnglishName('', t.category), _safeText(t.note != null && t.note!.isNotEmpty ? t.note! : '-'), '+$currency ${(t.amountMinor / 100).toStringAsFixed(2)}'],
              ],
            ),
        ];

      case 2: // Expense Tab Report
        final expenseTxns = transactions.where((t) => t.type == 'expense').toList();
        return [
          pw.Text('1. EXPENSE OVERVIEW & PERFORMANCE', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Total Expenses', value: '$currency ${(expenseTotal / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Transactions', value: '${expenseData.count} records', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Avg per Transaction', value: '$currency ${(expenseData.count > 0 ? (expenseTotal / expenseData.count / 100) : 0).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          pw.SizedBox(height: 16),
          if (vm.dualChartData.hasAnyData) ...[
            pw.Text('2. DAILY EXPENSE ACTIVITY', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
            pw.SizedBox(height: 8),
            _buildTrendChart(data: vm.dualChartData, currency: currency, incomeColor: incomeColor, expenseColor: expenseColor, trackColor: barTrackColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryTextColor: secondaryTextColor),
            pw.SizedBox(height: 16),
          ],
          pw.Text('3. EXPENSE CATEGORIES (${expenseData.categories.length})', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: borderColor, width: 0.7)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (expenseData.categories.isEmpty)
                  pw.Text('No expense records for this period.', style: pw.TextStyle(fontSize: 8.5, color: secondaryTextColor))
                else
                  for (final cat in expenseData.categories) ...[
                    _buildCategoryChartBar(label: _categoryEnglishName(cat.categoryKey, cat.label), amountMinor: cat.amountMinor, totalMinor: expenseTotal > 0 ? expenseTotal : 1, currency: currency, barColor: barFillColor, trackColor: barTrackColor, textColor: darkColor, secondaryTextColor: secondaryTextColor),
                    pw.SizedBox(height: 6),
                  ],
              ],
            ),
          ),
          if (expenseData.top.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('4. TOP MERCHANTS & PAYEES', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Merchant / Payee', 'Category', 'Count', 'Total Spent'],
              data: [for (final m in expenseData.top) [_safeText(m.name), _categoryEnglishName('', m.category), '${m.count} txns', '$currency ${(m.amountMinor / 100).toStringAsFixed(2)}']],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text('5. ITEMIZED EXPENSE REGISTER (${expenseTxns.length} records)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (expenseTxns.isEmpty)
            pw.Text('No expense transactions in this period.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              headers: ['Date', 'Category', 'Description / Payee', 'Amount Paid'],
              data: [
                for (final t in expenseTxns.take(120))
                  [DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(t.occurredAt)), _categoryEnglishName('', t.category), _safeText(t.note != null && t.note!.isNotEmpty ? t.note! : '-'), '-$currency ${(t.amountMinor / 100).toStringAsFixed(2)}'],
              ],
            ),
        ];

      case 3: // Lent Debts Tab Report
        final allLentDebts = vm.financeStore.debts.where((d) => d.type == 'lent').toList();
        return [
          pw.Text('1. LENDING OVERVIEW (MONEY YOU LENT)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Total Lent', value: '$currency ${(lendData.totalMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Outstanding', value: '$currency ${(lendData.outstandingMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Settled', value: '$currency ${(lendData.settledMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('2. DEBTORS & BORROWERS SUMMARY (${lendData.parties.length} parties)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (lendData.parties.isEmpty)
            pw.Text('No lending records found.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Borrower Name', 'Total Lent Amount', 'Loan Records Count'],
              data: [for (final p in lendData.parties) [p.name, '$currency ${(p.amountMinor / 100).toStringAsFixed(2)}', '${p.count} loans']],
            ),
          pw.SizedBox(height: 16),
          pw.Text('3. ITEMIZED LENT DEBTS REGISTER (${allLentDebts.length} records)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (allLentDebts.isEmpty)
            pw.Text('No individual lending records.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              headers: ['Date', 'Borrower', 'Principal / Remaining', 'Status', 'Note'],
              data: [
                for (final d in allLentDebts.take(100))
                  [
                    DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(d.createdAt)),
                    d.personName,
                    '$currency ${(d.amountMinor / 100).toStringAsFixed(2)}',
                    d.isSettled ? 'SETTLED' : 'ACTIVE',
                    _safeText(d.note != null && d.note!.isNotEmpty ? d.note! : '-'),
                  ],
              ],
            ),
        ];

      case 4: // Borrowed Debts Tab Report
        final allBorrowedDebts = vm.financeStore.debts.where((d) => d.type == 'borrowed').toList();
        return [
          pw.Text('1. BORROWING OVERVIEW (MONEY YOU OWE)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Total Borrowed', value: '$currency ${(borrowData.totalMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Outstanding', value: '$currency ${(borrowData.outstandingMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Settled', value: '$currency ${(borrowData.settledMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('2. CREDITORS & LENDERS SUMMARY (${borrowData.parties.length} parties)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (borrowData.parties.isEmpty)
            pw.Text('No borrowing records found.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Creditor / Lender Name', 'Total Borrowed Amount', 'Loan Records Count'],
              data: [for (final p in borrowData.parties) [p.name, '$currency ${(p.amountMinor / 100).toStringAsFixed(2)}', '${p.count} loans']],
            ),
          pw.SizedBox(height: 16),
          pw.Text('3. ITEMIZED BORROWED DEBTS REGISTER (${allBorrowedDebts.length} records)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (allBorrowedDebts.isEmpty)
            pw.Text('No individual borrowing records.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              headers: ['Date', 'Creditor', 'Principal / Remaining', 'Status', 'Note'],
              data: [
                for (final d in allBorrowedDebts.take(100))
                  [
                    DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(d.createdAt)),
                    d.personName,
                    '$currency ${(d.amountMinor / 100).toStringAsFixed(2)}',
                    d.isSettled ? 'SETTLED' : 'ACTIVE',
                    _safeText(d.note != null && d.note!.isNotEmpty ? d.note! : '-'),
                  ],
              ],
            ),
        ];

      case 5: // Shifts & Work Tab Report
        final allShifts = vm.financeStore.shifts;
        return [
          pw.Text('1. WORK & SHIFTS OVERVIEW', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Total Shift Earnings', value: '$currency ${(workData.earningsMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Completed Shifts', value: '${workData.shiftCount} shifts', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Hours Worked', value: '${(workData.totalMinutes / 60.0).toStringAsFixed(1)} hrs', subtitle: 'Overtime: ${workData.overtimeMinutes}m · Breaks: ${workData.breakMinutes}m', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('2. JOBS & ROLES SUMMARY (${workData.jobs.length} jobs)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (workData.jobs.isEmpty)
            pw.Text('No work jobs recorded.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Job Title', 'Hours Logged', 'Completed Shifts', 'Total Earnings'],
              data: [for (final j in workData.jobs) [j.job.name, '${(j.minutes / 60.0).toStringAsFixed(1)} hrs', '${j.shifts} shifts', '$currency ${(j.earningsMinor / 100).toStringAsFixed(2)}']],
            ),
          pw.SizedBox(height: 16),
          pw.Text('3. RECENT SHIFTS REGISTER (${allShifts.length} records)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          if (allShifts.isEmpty)
            pw.Text('No shifts found.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              headers: ['Date', 'Start - End', 'Total Duration', 'Status'],
              data: [
                for (final s in allShifts.take(100))
                  [
                    DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(s.startAt)),
                    '${DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(s.startAt))} - ${s.endAt != null ? DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(s.endAt!)) : "Ongoing"}',
                    '${s.endAt != null ? (((s.endAt! - s.startAt) / 60000).round() / 60.0).toStringAsFixed(1) : "0.0"} hrs',
                    s.status.toUpperCase(),
                  ],
              ],
            ),
        ];

      case 0:
      default: // Comprehensive Overview
        return [
          pw.Text('1. EXECUTIVE OVERVIEW', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Total Income', value: '$currency ${(incomeTotal / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Total Expenses', value: '$currency ${(expenseTotal / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Net Savings', value: '$currency ${(netSavingsMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Savings Rate', value: '${savingsRate.toStringAsFixed(1)}%', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Net Debt Position', value: '$currency ${(netDebtMinor / 100).toStringAsFixed(2)}', subtitle: 'Lent: ${(lendData.totalMinor / 100).toStringAsFixed(2)} | Borrowed: ${(borrowData.totalMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Work Earnings', value: '$currency ${(workData.earningsMinor / 100).toStringAsFixed(2)}', subtitle: '${workData.shiftCount} shifts · ${(workData.totalMinutes / 60.0).toStringAsFixed(1)} hrs', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          pw.SizedBox(height: 16),
          if (vm.dualChartData.hasAnyData) ...[
            pw.Text('2. CASH FLOW OVERVIEW & DAILY ACTIVITY', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
            pw.SizedBox(height: 8),
            _buildTrendChart(data: vm.dualChartData, currency: currency, incomeColor: incomeColor, expenseColor: expenseColor, trackColor: barTrackColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryTextColor: secondaryTextColor),
            pw.SizedBox(height: 16),
          ],
          pw.Text(vm.dualChartData.hasAnyData ? '3. INCOME ANALYSIS' : '2. INCOME ANALYSIS', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: borderColor, width: 0.7)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Income Categories (${incomeData.categories.length})', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkColor)),
                  pw.Text('Total: $currency ${(incomeTotal / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, color: secondaryTextColor, fontWeight: pw.FontWeight.bold)),
                ]),
                pw.SizedBox(height: 8),
                if (incomeData.categories.isEmpty)
                  pw.Text('No income records for this period.', style: pw.TextStyle(fontSize: 8.5, color: secondaryTextColor))
                else
                  for (final cat in incomeData.categories.take(6)) ...[
                    _buildCategoryChartBar(label: _categoryEnglishName(cat.categoryKey, cat.label), amountMinor: cat.amountMinor, totalMinor: incomeTotal > 0 ? incomeTotal : 1, currency: currency, barColor: barFillColor, trackColor: barTrackColor, textColor: darkColor, secondaryTextColor: secondaryTextColor),
                    pw.SizedBox(height: 6),
                  ],
              ],
            ),
          ),
          if (incomeData.top.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Top Income Source / Payer', 'Category', 'Count', 'Total Amount'],
              data: [for (final s in incomeData.top.take(5)) [_safeText(s.name), _categoryEnglishName('', s.category), '${s.count} txns', '$currency ${(s.amountMinor / 100).toStringAsFixed(2)}']],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text(vm.dualChartData.hasAnyData ? '4. EXPENSE ANALYSIS' : '3. EXPENSE ANALYSIS', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: borderColor, width: 0.7)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Expense Categories (${expenseData.categories.length})', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkColor)),
                  pw.Text('Total: $currency ${(expenseTotal / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, color: secondaryTextColor, fontWeight: pw.FontWeight.bold)),
                ]),
                pw.SizedBox(height: 8),
                if (expenseData.categories.isEmpty)
                  pw.Text('No expense records for this period.', style: pw.TextStyle(fontSize: 8.5, color: secondaryTextColor))
                else
                  for (final cat in expenseData.categories.take(6)) ...[
                    _buildCategoryChartBar(label: _categoryEnglishName(cat.categoryKey, cat.label), amountMinor: cat.amountMinor, totalMinor: expenseTotal > 0 ? expenseTotal : 1, currency: currency, barColor: barFillColor, trackColor: barTrackColor, textColor: darkColor, secondaryTextColor: secondaryTextColor),
                    pw.SizedBox(height: 6),
                  ],
              ],
            ),
          ),
          if (expenseData.top.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Top Merchant / Payee', 'Category', 'Count', 'Total Amount'],
              data: [for (final m in expenseData.top.take(5)) [_safeText(m.name), _categoryEnglishName('', m.category), '${m.count} txns', '$currency ${(m.amountMinor / 100).toStringAsFixed(2)}']],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text(vm.dualChartData.hasAnyData ? '5. LENDING & BORROWING (DEBTS)' : '4. LENDING & BORROWING (DEBTS)', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Total Lent (Money You Lent)', value: '$currency ${(lendData.totalMinor / 100).toStringAsFixed(2)}', subtitle: 'Outstanding: $currency ${(lendData.outstandingMinor / 100).toStringAsFixed(2)} · Settled: $currency ${(lendData.settledMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Total Borrowed (Money You Owe)', value: '$currency ${(borrowData.totalMinor / 100).toStringAsFixed(2)}', subtitle: 'Outstanding: $currency ${(borrowData.outstandingMinor / 100).toStringAsFixed(2)} · Settled: $currency ${(borrowData.settledMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          if (lendData.parties.isNotEmpty || borrowData.parties.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Party Name', 'Type', 'Amount', 'Debts Count'],
              data: [
                for (final p in lendData.parties.take(5)) [p.name, 'Lent (To Them)', '$currency ${(p.amountMinor / 100).toStringAsFixed(2)}', '${p.count}'],
                for (final p in borrowData.parties.take(5)) [p.name, 'Borrowed (From Them)', '$currency ${(p.amountMinor / 100).toStringAsFixed(2)}', '${p.count}'],
              ],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text(vm.dualChartData.hasAnyData ? '6. SHIFTS & WORK ANALYSIS' : '5. SHIFTS & WORK ANALYSIS', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildMetricCard(title: 'Completed Shifts', value: '${workData.shiftCount}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Total Hours Worked', value: '${(workData.totalMinutes / 60.0).toStringAsFixed(1)} hrs', subtitle: 'Overtime: ${workData.overtimeMinutes}m · Breaks: ${workData.breakMinutes}m', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildMetricCard(title: 'Total Shift Earnings', value: '$currency ${(workData.earningsMinor / 100).toStringAsFixed(2)}', valueColor: darkColor, surfaceColor: surfaceColor, borderColor: borderColor, textColor: darkColor, secondaryColor: secondaryTextColor)),
            ],
          ),
          if (workData.jobs.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              headers: ['Job Name', 'Hours Worked', 'Completed Shifts', 'Total Earnings'],
              data: [for (final j in workData.jobs) [j.job.name, '${(j.minutes / 60.0).toStringAsFixed(1)} hrs', '${j.shifts}', '$currency ${(j.earningsMinor / 100).toStringAsFixed(2)}']],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            vm.dualChartData.hasAnyData ? '7. ITEMIZED TRANSACTION REGISTER (${transactions.length} records)' : '6. ITEMIZED TRANSACTION REGISTER (${transactions.length} records)',
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkColor, letterSpacing: 0.5),
          ),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Text('No transactions recorded in this period.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8.5))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkColor),
              headerDecoration: pw.BoxDecoration(color: surfaceColor),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              headers: ['Date', 'Type', 'Category', 'Description / Note', 'Amount'],
              data: [
                for (final t in transactions.take(100))
                  [DateFormatter.numeric(DateTime.fromMillisecondsSinceEpoch(t.occurredAt)), t.type.toUpperCase(), _categoryEnglishName('', t.category), _safeText(t.note != null && t.note!.isNotEmpty ? t.note! : '-'), '$currency ${(t.amountMinor / 100).toStringAsFixed(2)}'],
              ],
            ),
        ];
    }
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
    required PdfColor trackColor,
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
                color: trackColor,
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

  static pw.Widget _buildTrendChart({
    required DualBarChartData data,
    required String currency,
    required PdfColor incomeColor,
    required PdfColor expenseColor,
    required PdfColor trackColor,
    required PdfColor surfaceColor,
    required PdfColor borderColor,
    required PdfColor textColor,
    required PdfColor secondaryTextColor,
  }) {
    if (!data.hasAnyData || data.labels.isEmpty) {
      return pw.SizedBox();
    }

    double maxVal = 0.0;
    for (int i = 0; i < data.incomeValues.length; i++) {
      if (data.incomeValues[i] > maxVal) maxVal = data.incomeValues[i];
      if (i < data.expenseValues.length && data.expenseValues[i] > maxVal) {
        maxVal = data.expenseValues[i];
      }
    }
    if (maxVal <= 0) maxVal = 1.0;

    // Show at most 14 latest bars to keep columns crisp and clean on A4
    final count = data.labels.length;
    final startIndex = count > 14 ? count - 14 : 0;
    final visibleLabels = data.labels.sublist(startIndex);
    final visibleIncome = data.incomeValues.sublist(startIndex);
    final visibleExpense = data.expenseValues.sublist(startIndex);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: surfaceColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Income vs Expense Flow (${visibleLabels.length} Intervals)',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textColor),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: incomeColor, borderRadius: pw.BorderRadius.circular(2))),
                  pw.SizedBox(width: 4),
                  pw.Text('Income', style: pw.TextStyle(fontSize: 7.5, color: secondaryTextColor, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 10),
                  pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: expenseColor, borderRadius: pw.BorderRadius.circular(2))),
                  pw.SizedBox(width: 4),
                  pw.Text('Expense', style: pw.TextStyle(fontSize: 7.5, color: secondaryTextColor, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 64,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < visibleLabels.length; i++) ...[
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          height: 48,
                          alignment: pw.Alignment.bottomCenter,
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              // Income Bar
                              pw.Container(
                                width: 5.5,
                                height: ((visibleIncome[i] / maxVal) * 44).clamp(1.5, 44.0),
                                decoration: pw.BoxDecoration(
                                  color: visibleIncome[i] > 0 ? incomeColor : trackColor,
                                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(1.5)),
                                ),
                              ),
                              pw.SizedBox(width: 2),
                              // Expense Bar
                              pw.Container(
                                width: 5.5,
                                height: ((visibleExpense[i] / maxVal) * 44).clamp(1.5, 44.0),
                                decoration: pw.BoxDecoration(
                                  color: visibleExpense[i] > 0 ? expenseColor : trackColor,
                                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          visibleLabels[i],
                          style: pw.TextStyle(fontSize: 6.5, color: secondaryTextColor),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive export sheet focused strictly on high-quality PDF export
  static Future<void> showPdfExportSheet(BuildContext context, AnalyticsViewModel viewModel, {int activeTabIndex = 0}) async {
    final currency = viewModel.baseCurrency;
    final tr = context.strings;
    final String typeLabel;
    final String reportTotal;
    final Color totalColor;

    switch (activeTabIndex) {
      case 1:
        typeLabel = tr.income;
        reportTotal = MoneyFormatter.format(viewModel.txTabData(TransactionType.income).totalMinor, currency);
        totalColor = const Color(0xFF10B981);
        break;
      case 2:
        typeLabel = tr.analyticsTabExpenses;
        reportTotal = MoneyFormatter.format(viewModel.txTabData(TransactionType.expense).totalMinor, currency);
        totalColor = const Color(0xFFEF4444);
        break;
      case 3:
        typeLabel = tr.analyticsTabLend;
        reportTotal = MoneyFormatter.format(viewModel.debtTabData(DebtType.lent).totalMinor, currency);
        totalColor = const Color(0xFF10B981);
        break;
      case 4:
        typeLabel = tr.analyticsTabBorrow;
        reportTotal = MoneyFormatter.format(viewModel.debtTabData(DebtType.borrowed).totalMinor, currency);
        totalColor = const Color(0xFFEF4444);
        break;
      case 5:
        typeLabel = tr.analyticsTabShiftsWork;
        reportTotal = MoneyFormatter.format(viewModel.workTabData().earningsMinor, currency);
        totalColor = const Color(0xFF1F7A45);
        break;
      case 0:
      default:
        typeLabel = tr.analyticsTabOverview;
        reportTotal = MoneyFormatter.format(viewModel.netMinor, currency, signed: true);
        totalColor = viewModel.netMinor >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        break;
    }

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
                            reportTotal,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: totalColor,
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
                    await _executePdfExport(context, viewModel, shareAfter: false, activeTabIndex: activeTabIndex);
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(tr.shareToAppsTitle),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _executePdfExport(context, viewModel, shareAfter: true, activeTabIndex: activeTabIndex);
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
    int activeTabIndex = 0,
  }) async {
    try {
      final tr = context.strings;
      showToast(context, tr.t('Generating branded PDF report...', ne: 'PDF रिपोर्ट तयार हुँदैछ...', es: 'Generando informe PDF...', fr: 'Génération du rapport PDF...', de: 'PDF-Bericht wird erstellt...', ja: 'PDFレポートを作成中...', zh: '正在生成 PDF 报告...', it: 'Generazione report PDF...'));
      final file = await generatePdf(viewModel, activeTabIndex: activeTabIndex);

      if (!context.mounted) return;

      if (shareAfter) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Hyprwise Analytics Report (${viewModel.dateFilter.label})',
          ),
        );
      } else {
        String finalSavedPath = file.path;
        final dateStr = DateFormatter.numeric(DateTime.now(), locale: 'en').replaceAll('/', '-');
        final fileName = 'hyprwise_analytics_report_$dateStr.pdf';

        try {
          final bytes = await file.readAsBytes();
          final chosenPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save PDF Report',
            fileName: fileName,
            bytes: bytes,
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );

          if (chosenPath != null) {
            finalSavedPath = chosenPath;
            final chosenFile = File(chosenPath);
            if (!await chosenFile.exists() || await chosenFile.length() == 0) {
              await chosenFile.writeAsBytes(bytes, flush: true);
            }
          } else {
            // User dismissed or cancelled file picker
            return;
          }
        } catch (_) {
          // Fallback: try copying to public downloads directory safely
          try {
            final publicDir = await ExportService.getPublicDownloadsDirectory();
            final targetFile = File('${publicDir.path}/$fileName');
            await file.copy(targetFile.path);
            finalSavedPath = targetFile.path;
          } catch (_) {
            // Keep using the verified file in temp/docs
          }
        }

        if (!context.mounted) return;

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
                      finalSavedPath,
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
                    SharePlus.instance.share(ShareParams(files: [XFile(finalSavedPath)]));
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

  static String _filterLabelEnglish(AnalyticsDateFilter filter) {
    return switch (filter) {
      AnalyticsDateFilter.thisMonth => 'This Month',
      AnalyticsDateFilter.thisWeek => 'This Week',
      AnalyticsDateFilter.last30Days => 'Last 30 Days',
      AnalyticsDateFilter.thisYear => 'This Year',
      AnalyticsDateFilter.custom => 'Custom Period',
    };
  }

  static String _categoryEnglishName(String categoryKey, String fallback) {
    if (categoryKey.isNotEmpty) {
      for (final cat in TransactionCategories.builtIn) {
        if (cat.value == categoryKey || cat.defaultLabel.toLowerCase() == categoryKey.toLowerCase()) {
          return cat.defaultLabel;
        }
      }
    }
    final hasNonAscii = fallback.runes.any((r) => r > 127);
    if (!hasNonAscii) return fallback;
    final f = fallback.toLowerCase();
    if (f.contains('食料品') || f.contains('食')) return 'Groceries';
    if (f.contains('交通') || f.contains('費')) return 'Transport';
    if (f.contains('シフト') || f.contains('給')) return 'Shift Pay';
    if (f.contains('給与') || f.contains('給料')) return 'Salary';
    if (f.contains('住居') || f.contains('家賃')) return 'Housing & Rent';
    if (f.contains('光熱費') || f.contains('電気')) return 'Utilities';
    if (f.contains('外食') || f.contains('飲食')) return 'Dining & Takeaway';
    if (f.contains('買物') || f.contains('ショッピング')) return 'Shopping';
    if (f.contains('娯楽')) return 'Entertainment';
    if (f.contains('医療') || f.contains('健康')) return 'Health & Medical';
    if (f.contains('投資')) return 'Investment';
    if (f.contains('ギフト') || f.contains('贈与')) return 'Gift';
    if (f.contains('収入')) return 'Other Income';
    if (f.contains('支出') || f.contains('その他')) return 'Other Expense';

    final buffer = StringBuffer();
    for (final rune in fallback.runes) {
      if (rune <= 127) buffer.writeCharCode(rune);
    }
    final cleaned = buffer.toString().trim();
    return cleaned.isNotEmpty ? cleaned : 'Category';
  }

  static String _safeText(String text) {
    if (text.isEmpty) return text;
    final hasNonAscii = text.runes.any((r) => r > 127);
    if (!hasNonAscii) return text;
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune <= 127) buffer.writeCharCode(rune);
    }
    final cleaned = buffer.toString().trim();
    return cleaned.isNotEmpty ? cleaned : 'Item';
  }
}
