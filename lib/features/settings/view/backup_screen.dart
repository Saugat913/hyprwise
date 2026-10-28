import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/backup/google_drive_backup_service.dart';
import 'package:finance_tracker/core/export/export_service.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/network/api_client.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final SettingsViewModel _viewModel = getIt<SettingsViewModel>();
  final AuthService _authService = getIt<AuthService>();
  final SubscriptionService _subService = getIt<SubscriptionService>();

  bool _isDriveBackingUp = false;
  bool _isDriveRestoring = false;
  bool _isCloudPushing = false;
  bool _isCloudPulling = false;
  DriveBackupMetadata? _driveMetadata;

  @override
  void initState() {
    super.initState();
    _checkSilentDriveStatus();
  }

  Future<void> _checkSilentDriveStatus() async {
    final meta = await GoogleDriveBackupService.instance.checkExistingBackupSilently();
    if (mounted && meta != null) {
      setState(() => _driveMetadata = meta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _authService, _subService]),
      builder: (context, _) {
        final lastLocalBackupMs = _viewModel.settings.lastBackupAt;
        final lastBackupDate = _driveMetadata?.modifiedTime ??
            (lastLocalBackupMs != null
                ? DateTime.fromMillisecondsSinceEpoch(lastLocalBackupMs)
                : null);
        final driveEmail = _driveMetadata?.accountEmail ??
            GoogleDriveBackupService.instance.connectedEmail;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.backupExportRestore,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.page,
                vertical: AppSpace.md,
              ),
              children: [
                // Concise plain-text intro (never styled like clickable buttons)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  child: Text(
                    tr.t(
                      'Choose how you want to back up, export, or restore your financial records. All backups include your accounts, transactions, shifts, jobs, debts, and goals.',
                      ne: 'तपाईंको वित्तीय डाटा ब्याकअप, निर्यात वा रिस्टोर गर्ने माध्यम छान्नुहोस्। सबै ब्याकअपमा खाता, कारोबार, सिफ्ट, काम र लक्ष्यहरू समावेश हुन्छन्।',
                      es: 'Elige cómo respaldar, exportar o restaurar tus registros financieros. Incluye cuentas, transacciones, turnos y metas.',
                      fr: 'Choisissez comment sauvegarder, exporter ou restaurer vos données financières.',
                      de: 'Wählen Sie, wie Sie Ihre Finanzdaten sichern, exportieren oder wiederherstellen möchten.',
                      ja: 'データのバックアップ、エクスポート、復元方法を選択してください。すべての口座・取引・シフトが含まれます。',
                      zh: '选择备份、导出或恢复财务数据的方式。备份包含您的所有账户、收支、排班和目标。',
                      it: 'Scegli come eseguire il backup, esportare o ripristinare i tuoi dati finanziari.',
                    ),
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),

                // ============================================================
                // SECTION 1: CLOUD BACKUP & SYNC
                // ============================================================
                SectionHeader(
                  tr.t(
                    'CLOUD BACKUP',
                    ne: 'क्लाउड ब्याकअप',
                    es: 'COPIA EN LA NUBE',
                    fr: 'SAUVEGARDE CLOUD',
                    de: 'CLOUD-BACKUP',
                    ja: 'クラウドバックアップ',
                    zh: '云端备份',
                    it: 'BACKUP CLOUD',
                  ),
                ),
                const SizedBox(height: AppSpace.sm),

                // 1A. Google Drive Backup Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconTile(HugeIcons.strokeRoundedGoogleDrive),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.googleDriveBackup,
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  driveEmail ?? tr.googleDriveBackupDesc,
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            lastBackupDate != null
                                ? tr.t('Backed up', ne: 'सुरक्षित', es: 'Guardado', fr: 'Sauvegardé', de: 'Gesichert', ja: '保存済', zh: '已备份')
                                : tr.t('Not backed up', ne: 'ब्याकअप छैन', es: 'Sin copia', fr: 'Non sauvegardé', de: 'Kein Backup', ja: '未保存', zh: '未备份'),
                            tone: lastBackupDate != null ? ChipTone.success : ChipTone.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            AppIcon(
                              HugeIcons.strokeRoundedClock01,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Expanded(
                              child: Text(
                                lastBackupDate != null
                                    ? tr.t(
                                        'Last backup: ${AppDate.header(lastBackupDate)} • ${AppDate.timeOnly(lastBackupDate)}',
                                        ne: 'पछिल्लो ब्याकअप: ${AppDate.header(lastBackupDate)} • ${AppDate.timeOnly(lastBackupDate)}',
                                        es: 'Última copia: ${AppDate.header(lastBackupDate)} • ${AppDate.timeOnly(lastBackupDate)}',
                                        fr: 'Dernière sauvegarde : ${AppDate.header(lastBackupDate)} • ${AppDate.timeOnly(lastBackupDate)}',
                                        de: 'Letztes Backup: ${AppDate.header(lastBackupDate)} • ${AppDate.timeOnly(lastBackupDate)}',
                                        ja: '最終バックアップ: ${AppDate.header(lastBackupDate)} ${AppDate.timeOnly(lastBackupDate)}',
                                        zh: '上次备份：${AppDate.header(lastBackupDate)} ${AppDate.timeOnly(lastBackupDate)}',
                                      )
                                    : tr.t(
                                        'No Google Drive backup recorded yet',
                                        ne: 'अहिलेसम्म गुगल ड्राइभ ब्याकअप गरिएको छैन',
                                        es: 'Aún no hay copia en Google Drive',
                                        fr: 'Aucune sauvegarde Google Drive enregistrée',
                                        de: 'Noch kein Google Drive-Backup vorhanden',
                                        ja: 'Googleドライブへのバックアップ履歴はありません',
                                        zh: '尚未创建 Google 云端硬盘备份',
                                      ),
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              _isDriveBackingUp
                                  ? tr.t('Backing up...', ne: 'ब्याकअप हुँदैछ...', es: 'Guardando...', fr: 'Sauvegarde...', de: 'Sichere...', ja: '保存中...', zh: '正在备份...')
                                  : tr.t('Back Up Now', ne: 'अहिले ब्याकअप गर्नुहोस्', es: 'Respaldar ahora', fr: 'Sauvegarder', de: 'Jetzt sichern', ja: '今すぐバックアップ', zh: '立即备份'),
                              icon: HugeIcons.strokeRoundedCloudUpload,
                              onPressed: (_isDriveBackingUp || _isDriveRestoring)
                                  ? null
                                  : () => _handleGoogleDriveBackup(context),
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: AppButton(
                              _isDriveRestoring
                                  ? tr.t('Restoring...', ne: 'रिस्टोर हुँदैछ...', es: 'Restaurando...', fr: 'Restauration...', de: 'Lade...', ja: '復元中...', zh: '正在恢复...')
                                  : tr.t('Restore Drive', ne: 'ड्राइभबाट रिस्टोर', es: 'Restaurar Drive', fr: 'Restaurer Drive', de: 'Aus Drive laden', ja: 'ドライブから復元', zh: '从网盘恢复'),
                              kind: AppButtonKind.secondary,
                              icon: HugeIcons.strokeRoundedCloudDownload,
                              onPressed: (_isDriveBackingUp || _isDriveRestoring)
                                  ? null
                                  : () => _handleGoogleDriveRestore(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                // 1B. Hyprwise Cloud Sync Card (Pro)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconTile(HugeIcons.strokeRoundedCloud),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        tr.hyprwiseCloudSync,
                                        style: text.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!_subService.isPro) ...[
                                      const SizedBox(width: AppSpace.xs),
                                      const ProCrownBadge(isCompact: true),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _authService.isAuthenticated
                                      ? tr.connectedAccountEmail(
                                          _authService.currentUser?.email ?? '',
                                        )
                                      : tr.signInToSyncHono,
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              _isCloudPushing
                                  ? tr.t('Pushing...', ne: 'अपलोड हुँदैछ...', es: 'Subiendo...', fr: 'Envoi...', de: 'Sende...', ja: '送信中...', zh: '同步中...')
                                  : tr.pushDataToCloud,
                              icon: HugeIcons.strokeRoundedUpload04,
                              onPressed: (_isCloudPushing || _isCloudPulling)
                                  ? null
                                  : () => _handleCloudPush(context),
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: AppButton(
                              _isCloudPulling
                                  ? tr.t('Pulling...', ne: 'डाउनलोड हुँदैछ...', es: 'Descargando...', fr: 'Récupération...', de: 'Lade...', ja: '取得中...', zh: '拉取中...')
                                  : tr.pullDataFromCloud,
                              kind: AppButtonKind.secondary,
                              icon: HugeIcons.strokeRoundedDownload04,
                              onPressed: (_isCloudPushing || _isCloudPulling)
                                  ? null
                                  : () => _handleCloudPull(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.xl),

                // ============================================================
                // SECTION 2: LOCAL FILES & REPORTS
                // ============================================================
                SectionHeader(
                  tr.t(
                    'LOCAL FILES & REPORTS',
                    ne: 'स्थानीय फाइल र रिपोर्ट',
                    es: 'ARCHIVOS LOCALES Y REPORTES',
                    fr: 'FICHIERS LOCAUX & RAPPORTS',
                    de: 'LOKALE DATEIEN & BERICHTE',
                    ja: 'ローカルファイルとレポート',
                    zh: '本地文件与报表',
                    it: 'FILE LOCALI E REPORT',
                  ),
                ),
                const SizedBox(height: AppSpace.sm),

                // 2A. Export Data (CSV / JSON / Report)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconTile(HugeIcons.strokeRoundedDownload01),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.exportDataFormats,
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr.t(
                                    'Save CSV spreadsheets (Excel/Sheets), full JSON backups, or summary reports to your phone.',
                                    ne: 'CSV स्प्रेडसिट, पूर्ण JSON ब्याकअप वा सारांश रिपोर्ट फोनमा सेभ वा सेयर गर्नुहोस्।',
                                    es: 'Guarda hojas CSV (Excel/Sheets), copias JSON completas o informes en tu teléfono.',
                                    fr: 'Enregistrez des feuilles CSV, des sauvegardes JSON ou des rapports sur votre téléphone.',
                                    de: 'CSV-Tabellen, vollständige JSON-Backups oder Berichte auf dem Gerät speichern.',
                                    ja: 'CSVスプレッドシート、JSONバックアップ、サマリーレポートを端末に保存または共有します。',
                                    zh: '将 CSV 表格（支持 Excel）、完整 JSON 备份或财务汇总报告保存到手机。',
                                  ),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      AppButton(
                        tr.t(
                          'Export Data (CSV / JSON / Report)',
                          ne: 'डाटा निर्यात गर्नुहोस् (CSV / JSON)',
                          es: 'Exportar datos (CSV / JSON / Informe)',
                          fr: 'Exporter les données (CSV / JSON)',
                          de: 'Daten exportieren (CSV / JSON)',
                          ja: 'データをエクスポート (CSV / JSON)',
                          zh: '导出数据 (CSV / JSON / 报告)',
                        ),
                        kind: AppButtonKind.secondary,
                        icon: HugeIcons.strokeRoundedFileExport,
                        onPressed: () => ExportService.showExportDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                // 2B. Restore from Local JSON File
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconTile(
                            HugeIcons.strokeRoundedUpload01,
                            color: colors.brand,
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.restoreFromJsonBackup,
                                  style: text.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr.t(
                                    'Select a previously exported Hyprwise .json backup file from your device storage to restore all records.',
                                    ne: 'पहिले सेभ गरिएको .json ब्याकअप फाइल छानेर सबै पुराना रेकर्डहरू रिस्टोर गर्नुहोस्।',
                                    es: 'Selecciona un archivo .json de respaldo guardado en tu dispositivo para restaurar tus datos.',
                                    fr: 'Sélectionnez un fichier .json sur votre appareil pour restaurer vos enregistrements.',
                                    de: 'Wählen Sie eine gespeicherte .json-Backup-Datei vom Gerät, um alle Daten wiederherzustellen.',
                                    ja: '端末に保存された .json バックアップファイルを選択してデータを復元します。',
                                    zh: '从手机存储中选择之前导出的 Hyprwise .json 备份文件以恢复全部记录。',
                                  ),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      AppButton(
                        tr.t(
                          'Choose .json Backup File',
                          ne: '.json ब्याकअप फाइल छान्नुहोस्',
                          es: 'Elegir archivo .json de copia',
                          fr: 'Choisir un fichier .json',
                          de: '.json Backup-Datei auswählen',
                          ja: '.json バックアップファイルを選択',
                          zh: '选择 .json 备份文件进行恢复',
                        ),
                        kind: AppButtonKind.secondary,
                        icon: HugeIcons.strokeRoundedFolderOpen,
                        onPressed: () => _pickAndRestoreBackup(context, _viewModel),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleDriveBackup(BuildContext context) async {
    final tr = context.strings;
    setState(() => _isDriveBackingUp = true);

    try {
      final result = await GoogleDriveBackupService.instance.backupToGoogleDrive();
      if (!context.mounted) return;

      if (result.success) {
        await _checkSilentDriveStatus();
        if (!context.mounted) return;
        showToast(
          context,
          tr.t(
            'Backed up to Google Drive (${result.accountEmail ?? result.fileName})',
            ne: 'गुगल ड्राइभमा सफलतापूर्वक ब्याकअप गरियो (${result.accountEmail ?? result.fileName})',
            es: 'Guardado en Google Drive (${result.accountEmail ?? result.fileName})',
            fr: 'Sauvegardé sur Google Drive (${result.accountEmail ?? result.fileName})',
            de: 'In Google Drive gesichert (${result.accountEmail ?? result.fileName})',
            ja: 'Googleドライブにバックアップしました (${result.accountEmail ?? result.fileName})',
            zh: '已成功备份至 Google 云端硬盘 (${result.accountEmail ?? result.fileName})',
          ),
        );
        return;
      }

      // If direct Google Drive OAuth wasn't completed or Google Play Services is unavailable,
      // offer an explicit fallback to save/share the backup file directly to the Google Drive app.
      final useShareSheet = await showConfirmDialog(
        context,
        title: tr.googleDriveBackup,
        message: tr.t(
          'Direct Google Drive sign-in could not be completed (${result.errorMessage ?? "unavailable"}). Would you like to save the backup file directly to your Google Drive app instead?',
          ne: 'सिधा गुगल ड्राइभ साइन-इन हुन सकेन। के तपाईं ब्याकअप फाइल सिधै गुगल ड्राइभ एपमा सेभ गर्न चाहनुहुन्छ?',
          es: 'No se pudo iniciar sesión directamente en Google Drive. ¿Deseas guardar el archivo en la app de Google Drive?',
          fr: 'Connexion directe à Google Drive indisponible. Voulez-vous enregistrer le fichier via l\'application Google Drive ?',
          de: 'Direkte Google Drive-Anmeldung nicht möglich. Möchten Sie die Backup-Datei direkt an die Google Drive-App senden?',
          ja: 'Googleドライブへの直接接続ができませんでした。代わりにGoogleドライブアプリへバックアップファイルを保存しますか？',
          zh: '无法直接连接 Google 云端硬盘。是否直接将备份文件发送并保存到 Google 云端硬盘应用？',
        ),
        confirmLabel: tr.t('Save to Drive App', ne: 'ड्राइभ एपमा सेभ', es: 'Guardar en Drive', fr: 'Enregistrer sur Drive', de: 'An Drive senden', ja: 'ドライブへ保存', zh: '保存到云端硬盘'),
        cancelLabel: tr.cancel,
      );

      if (useShareSheet && context.mounted) {
        await _shareBackupFileToDrive(context);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Backup error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDriveBackingUp = false);
      }
    }
  }

  Future<void> _shareBackupFileToDrive(BuildContext context) async {
    final tr = context.strings;
    final dataRepo = getIt<DataRepository>();
    final jsonContent = await dataRepo.exportJson();

    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormatter.numeric(DateTime.now()).replaceAll('/', '-');
    const fileName = 'hyprwise_backup.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonContent, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: fileName)],
        subject: 'Hyprwise Finance Backup ($dateStr)',
        text: 'Hyprwise backup file ($dateStr). Save to Google Drive.',
      ),
    );

    await _viewModel.settingsRepo.setBackupEnabled(true);
    await _viewModel.settingsRepo.setLastBackupAt(DateTime.now());

    if (context.mounted) {
      showToast(context, tr.chooseDriveToComplete);
    }
  }

  Future<void> _handleGoogleDriveRestore(BuildContext context) async {
    final tr = context.strings;
    setState(() => _isDriveRestoring = true);

    try {
      final metadata = await GoogleDriveBackupService.instance.findBackupOnDrive();
      if (!context.mounted) return;

      if (metadata == null) {
        final pickFromDevice = await showConfirmDialog(
          context,
          title: tr.t('No Drive Backup Found', ne: 'ड्राइभमा ब्याकअप भेटिएन', es: 'No se encontró copia en Drive', fr: 'Aucune sauvegarde trouvée', de: 'Kein Drive-Backup gefunden', ja: 'バックアップが見つかりません', zh: '未找到云端硬盘备份'),
          message: tr.t(
            'No automatic "hyprwise_backup.json" file was found in your Google Drive account. If you saved a backup file manually to Google Drive or your phone, you can select the .json file directly.',
            ne: 'तपाईंको गुगल ड्राइभमा स्वचालित ब्याकअप फाइल भेटिएन। यदि तपाईंले म्यानुअल रूपमा सेभ गर्नुभएको छ भने फाइल पिकरबाट .json फाइल छान्न सक्नुहुन्छ।',
            es: 'No se encontró "hyprwise_backup.json" en tu cuenta. Si guardaste el archivo manualmente, puedes seleccionarlo desde el selector de archivos.',
            fr: 'Aucun fichier "hyprwise_backup.json" trouvé. Vous pouvez sélectionner un fichier .json manuellement.',
            de: 'Keine "hyprwise_backup.json" gefunden. Sie können eine gespeicherte .json-Datei direkt über den Dateiwähler öffnen.',
            ja: 'Googleドライブ上に自動バックアップが見つかりませんでした。手動で保存した .json ファイルを選択して復元できます。',
            zh: '未在您的 Google 云端硬盘中找到自动备份文件。如果您之前手动保存过备份，可以直接选择 .json 文件进行恢复。',
          ),
          confirmLabel: tr.t('Choose .json File', ne: '.json फाइल छान्नुहोस्', es: 'Elegir archivo .json', fr: 'Choisir fichier .json', de: '.json Datei wählen', ja: 'ファイルを選択', zh: '选择 .json 文件'),
          cancelLabel: tr.cancel,
        );
        if (pickFromDevice && context.mounted) {
          await _pickAndRestoreBackup(context, _viewModel);
        }
        return;
      }

      final formattedDate = '${AppDate.header(metadata.modifiedTime)} • ${AppDate.timeOnly(metadata.modifiedTime)}';
      final confirmed = await showConfirmDialog(
        context,
        title: tr.restoreFromBackupQuestion,
        message: tr.t(
          'Found "${metadata.fileName}" on Google Drive ($formattedDate). Restoring will replace your current local data.',
          ne: 'गुगल ड्राइभमा "${metadata.fileName}" ($formattedDate) भेटियो। रिस्टोर गर्दा हालको स्थानीय डाटा प्रतिस्थापन हुनेछ।',
          es: 'Se encontró "${metadata.fileName}" en Google Drive ($formattedDate). Esto reemplazará tus datos actuales.',
          fr: 'Fichier "${metadata.fileName}" trouvé sur Google Drive ($formattedDate). Ceci remplacera vos données actuelles.',
          de: '"${metadata.fileName}" auf Google Drive gefunden ($formattedDate). Ersetzt Ihre aktuellen lokalen Daten.',
          ja: 'Googleドライブに「${metadata.fileName}」($formattedDate) が見つかりました。現在のデータを上書きして復元しますか？',
          zh: '在 Google 云端硬盘中找到 "${metadata.fileName}" ($formattedDate)。恢复操作将替换当前本地数据。',
        ),
        confirmLabel: tr.restoreDataAction,
        cancelLabel: tr.cancel,
      );

      if (!confirmed || !context.mounted) return;

      final restored = await GoogleDriveBackupService.instance.restoreFromDriveFile(
        metadata.fileId,
      );
      if (!context.mounted) return;

      if (restored) {
        setState(() => _driveMetadata = metadata);
        showToast(
          context,
          tr.t(
            'Data restored successfully from Google Drive!',
            ne: 'गुगल ड्राइभबाट डाटा सफलतापूर्वक रिस्टोर भयो!',
            es: '¡Datos restaurados con éxito desde Google Drive!',
            fr: 'Données restaurées avec succès depuis Google Drive !',
            de: 'Daten erfolgreich aus Google Drive wiederhergestellt!',
            ja: 'Googleドライブからデータを復元しました！',
            zh: '已成功从 Google 云端硬盘恢复数据！',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Restore error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDriveRestoring = false);
      }
    }
  }

  Future<void> _handleCloudPush(BuildContext context) async {
    final tr = context.strings;
    if (!_subService.isPro) {
      showProUpgradeSheet(
        context,
        title: tr.cloudSyncProFeature,
        message: tr.t(
          'Seamlessly back up and synchronize your transactions, shifts, and goals with Hyprwise Cloud.',
          ne: 'तपाईंका कारोबार, सिफ्ट र लक्ष्यहरू हाइपरवाइज क्लाउडमा सुरक्षित रूपमा सिंक गर्नुहोस्।',
          es: 'Haz copias y sincroniza tus transacciones, turnos y metas en la nube Hyprwise.',
          fr: 'Synchronisez vos transactions, quarts et objectifs en toute simplicité avec Hyprwise Cloud.',
          de: 'Sichern und sincronisieren Sie Ihre Transaktionen, Schichten und Ziele mit der Cloud.',
          ja: '取引、シフト、目標をHyprwiseクラウドとシームレスに同期・バックアップします。',
          zh: '通过 Hyprwise 专属云端无缝同步与备份您的每一笔收支、排班和储蓄目标。',
          it: 'Esegui backup e sincronizza transazioni, turni e obiettivi con Hyprwise Cloud.',
        ),
        featureHighlight: 'backup',
      );
      return;
    }

    setState(() => _isCloudPushing = true);
    try {
      final dataRepo = getIt<DataRepository>();
      final jsonString = await dataRepo.exportJson();
      final dataMap = jsonDecode(jsonString) as Map<String, dynamic>;

      final result = await ApiClient.instance.pushSync(dataMap);
      if (!context.mounted) return;

      if (result != null && result['success'] == true) {
        final v = result['version'] ?? 1;
        await _viewModel.settingsRepo.setBackupEnabled(true);
        await _viewModel.settingsRepo.setLastBackupAt(DateTime.now());
        if (!context.mounted) return;
        showToast(
          context,
          tr.t(
            'Cloud sync push successful (v$v)!',
            ne: 'क्लाउड सिंक सफलतापूर्वक सम्पन्न भयो (संस्करण $v)',
            es: '¡Sincronización en la nube exitosa (v$v)!',
            fr: 'Envoi sur le cloud réussi (v$v) !',
            de: 'Cloud-Upload erfolgreich (v$v)!',
            ja: 'クラウドへの送信が完了しました (v$v)',
            zh: '云端同步成功 (版本 $v)！',
            it: 'Sincronizzazione cloud riuscita (v$v)!',
          ),
        );
      } else {
        showToast(context, tr.couldNotConnectServer);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Sync error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudPushing = false);
      }
    }
  }

  Future<void> _handleCloudPull(BuildContext context) async {
    final tr = context.strings;
    if (!_subService.isPro) {
      showProUpgradeSheet(
        context,
        title: tr.cloudSyncProFeature,
        message: tr.t(
          'Seamlessly back up and synchronize your transactions, shifts, and goals with Hyprwise Cloud.',
          ne: 'तपाईंका कारोबार, सिफ्ट र लक्ष्यहरू हाइपरवाइज क्लाउडमा सुरक्षित रूपमा सिंक गर्नुहोस्।',
          es: 'Haz copias y sincroniza tus transacciones, turnos y metas en la nube Hyprwise.',
          fr: 'Synchronisez vos transactions, quarts et objectifs en toute simplicité avec Hyprwise Cloud.',
          de: 'Sichern und synchronisieren Sie Ihre Transaktionen, Schichten und Ziele mit der Cloud.',
          ja: '取引、シフト、目標をHyprwiseクラウドとシームレスに同期・バックアップします。',
          zh: '通过 Hyprwise 专属云端无缝同步与备份您的每一笔收支、排班和储蓄目标。',
          it: 'Esegui backup e sincronizza transazioni, turni e obiettivi con Hyprwise Cloud.',
        ),
        featureHighlight: 'backup',
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: tr.restoreFromCloudQuestion,
      message: tr.t(
        'This will replace current local data with the latest cloud backup.',
        ne: 'यसले हालको स्थानीय डाटालाई क्लाउडमा रहेको पछिल्लो डाटासँग बदल्नेछ।',
        es: 'Esto reemplazará los datos locales con la última copia de la nube.',
        fr: 'Ceci remplacera les données locales actuelles par la sauvegarde cloud.',
        de: 'Ersetzt die lokalen Daten durch das neueste Cloud-Backup.',
        ja: '現在の端末データをクラウドの最新バックアップで上書きします。',
        zh: '这将使用云端最新的完整备份替换当前本地全部数据。',
        it: 'Questo sostituirà i dati locali con l\'ultimo backup dal cloud.',
      ),
      confirmLabel: tr.restoreFromCloudAction,
      cancelLabel: tr.cancel,
    );

    if (!confirmed || !context.mounted) return;

    setState(() => _isCloudPulling = true);
    try {
      final result = await ApiClient.instance.pullSync();
      if (!context.mounted) return;

      if (result == null || result['empty'] == true || result['data'] == null) {
        showToast(
          context,
          tr.t(
            'No cloud backup found on server',
            ne: 'क्लाउडमा कुनै ब्याकअप फेला परेन',
            es: 'No se encontró copia en la nube',
            fr: 'Aucune sauvegarde trouvée sur le serveur',
            de: 'Kein Cloud-Backup auf dem Server gefunden',
            ja: 'サーバー上にバックアップが見つかりませんでした',
            zh: '服务器上未找到任何云端备份记录',
            it: 'Nessun backup trovato sul server',
          ),
        );
        return;
      }

      final dataPayload = result['data'];
      final jsonString = dataPayload is String ? dataPayload : jsonEncode(dataPayload);
      final dataRepo = getIt<DataRepository>();
      await dataRepo.importJson(jsonString);

      if (context.mounted) {
        final v = result['version'] ?? 1;
        showToast(
          context,
          tr.t(
            'Cloud data v$v pulled & synced successfully!',
            ne: 'क्लाउडबाट डाटा सफलतापूर्वक रिस्टोर भयो (संस्करण $v)',
            es: '¡Datos en la nube v$v recuperados y sincronizados!',
            fr: 'Données cloud v$v récupérées et synchronisées !',
            de: 'Cloud-Daten v$v erfolgreich geladen!',
            ja: 'クラウドデータ v$v を正常に復元しました！',
            zh: '云端备份 v$v 已成功拉取并还原！',
            it: 'Dati cloud v$v scaricati e sincronizzati!',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Restore error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudPulling = false);
      }
    }
  }

  Future<void> _pickAndRestoreBackup(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    final tr = context.strings;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      String jsonContent;

      if (pickedFile.path != null) {
        jsonContent = await File(pickedFile.path!).readAsString();
      } else if (pickedFile.bytes != null) {
        jsonContent = utf8.decode(pickedFile.bytes!);
      } else {
        if (context.mounted) {
          showToast(context, tr.couldNotReadFile);
        }
        return;
      }

      if (!context.mounted) return;

      final confirmed = await showConfirmDialog(
        context,
        title: tr.restoreFromBackupQuestion,
        message: tr.t(
          'This will replace your current financial data with the backup from "${pickedFile.name}". This action cannot be undone.',
          ne: 'यसले तपाईंको हालको डाटालाई "${pickedFile.name}" को डाटासँग प्रतिस्थापन गर्नेछ। यसलाई पूर्ववत गर्न सकिँदैन।',
          es: 'Esto reemplazará tus datos actuales con la copia de "${pickedFile.name}". No se puede deshacer.',
          fr: 'Ceci remplacera vos données actuelles par la sauvegarde "${pickedFile.name}". Irréversible.',
          de: 'Ersetzt Ihre Finanzdaten durch das Backup "${pickedFile.name}". Kann nicht rückgängig gemacht werden.',
          ja: '「${pickedFile.name}」のバックアップデータで現在の家計データを上書きします。元に戻すことはできません。',
          zh: '这将使用 "${pickedFile.name}" 替换您当前的所有财务数据，操作无法撤回。',
          it: 'Questo sostituirà i tuoi dati attuali con il backup da "${pickedFile.name}".',
        ),
        confirmLabel: tr.restoreDataAction,
        cancelLabel: tr.cancel,
      );

      if (confirmed && context.mounted) {
        await viewModel.importData(jsonContent);
        if (context.mounted) {
          showToast(
            context,
            tr.t(
              'Data restored successfully from ${pickedFile.name}',
              ne: '${pickedFile.name} बाट डाटा सफलतापूर्वक रिस्टोर भयो',
              es: 'Datos restaurados con éxito desde ${pickedFile.name}',
              fr: 'Données restaurées avec succès depuis ${pickedFile.name}',
              de: 'Daten erfolgreich wiederhergestellt aus ${pickedFile.name}',
              ja: '${pickedFile.name}からデータを復元しました',
              zh: '已成功从 ${pickedFile.name} 还原数据',
              it: 'Dati ripristinati con successo da ${pickedFile.name}',
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Restore error: $e');
      }
    }
  }
}
