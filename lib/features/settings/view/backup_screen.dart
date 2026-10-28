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
  int _selectedTab = 0;

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
        final hasBackup = lastBackupDate != null;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.backupExportRestore,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.md,
                AppSpace.page,
                AppSpace.xxxl,
              ),
              children: [
                // ============================================================
                // STATUS HERO SUMMARY CARD
                // ============================================================
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: hasBackup ? colors.incomeBg : colors.brandBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: AppIcon(
                          hasBackup
                              ? HugeIcons.strokeRoundedCloudSavingDone01
                              : HugeIcons.strokeRoundedCloudUpload,
                          size: 24,
                          color: hasBackup ? colors.income : colors.brand,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasBackup
                                  ? tr.t(
                                      'Backup Active',
                                      ne: 'ब्याकअप सक्रिय छ',
                                      es: 'Respaldo activo',
                                      fr: 'Sauvegarde active',
                                      de: 'Backup aktiv',
                                      ja: 'バックアップ有効',
                                      zh: '备份已激活',
                                      it: 'Backup attivo',
                                    )
                                  : tr.t(
                                      'No Recent Backup',
                                      ne: 'हालसालै ब्याकअप छैन',
                                      es: 'Sin respaldo reciente',
                                      fr: 'Aucune sauvegarde récente',
                                      de: 'Kein aktuelles Backup',
                                      ja: '最近のバックアップなし',
                                      zh: '暂无近期备份',
                                      it: 'Nessun backup recente',
                                    ),
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasBackup
                                  ? '${AppDate.header(lastBackupDate)} • ${AppDate.timeOnly(lastBackupDate)}'
                                  : tr.t(
                                      'Keep your ledger safe in the cloud or on device',
                                      ne: 'आफ्नो हिसाब क्लाउड वा फोनमा सुरक्षित राख्नुहोस्',
                                      es: 'Mantén tus registros seguros en la nube o dispositivo',
                                      fr: 'Gardez vos comptes en sécurité dans le cloud ou sur l\'appareil',
                                      de: 'Sichern Sie Ihre Daten in der Cloud oder auf dem Gerät',
                                      ja: 'データをクラウドまたは端末に安全に保護します',
                                      zh: '将您的账本安全保存在云端或本地设备中',
                                      it: 'Mantieni i tuoi conti al sicuro nel cloud o sul dispositivo',
                                    ),
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      StatusChip(
                        hasBackup
                            ? tr.t('Protected', ne: 'सुरक्षित', es: 'Protegido', fr: 'Protégé', de: 'Gesichert', ja: '保護済', zh: '已保护', it: 'Protetto')
                            : tr.t('Pending', ne: 'बाँकी', es: 'Pendiente', fr: 'En attente', de: 'Ausstehend', ja: '未設定', zh: '待备份', it: 'In attesa'),
                        tone: hasBackup ? ChipTone.success : ChipTone.neutral,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.lg),

                // ============================================================
                // SEGMENTED TABS: CLOUD vs EXPORT & LOCAL
                // ============================================================
                SegmentedTabs<int>(
                  value: _selectedTab,
                  onChanged: (v) => setState(() => _selectedTab = v),
                  options: {
                    0: tr.t(
                      'Cloud Backup',
                      ne: 'क्लाउड ब्याकअप',
                      es: 'Copia en Nube',
                      fr: 'Sauvegarde Cloud',
                      de: 'Cloud-Backup',
                      ja: 'クラウド保存',
                      zh: '云端备份',
                      it: 'Backup Cloud',
                    ),
                    1: tr.t(
                      'Export & Local',
                      ne: 'निर्यात र फाइल',
                      es: 'Exportar y Local',
                      fr: 'Export & Local',
                      de: 'Export & Lokal',
                      ja: '出力と復元',
                      zh: '导出与本地',
                      it: 'Esporta e File',
                    ),
                  },
                ),

                const SizedBox(height: AppSpace.lg),

                if (_selectedTab == 0) ...[
                  // ==========================================================
                  // TAB 0: CLOUD BACKUP (GOOGLE DRIVE & HYPRWISE CLOUD)
                  // ==========================================================
                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const IconTile(
                              HugeIcons.strokeRoundedGoogleDrive,
                              size: 44,
                            ),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    driveEmail ?? tr.googleDriveBackupDesc,
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.lg),
                        AppButton(
                          _isDriveBackingUp
                              ? tr.t('Backing up...', ne: 'ब्याकअप हुँदैछ...', es: 'Guardando...', fr: 'Sauvegarde...', de: 'Sichere...', ja: '保存中...', zh: '正在备份...', it: 'Backup in corso...')
                              : tr.t('Back Up to Google Drive', ne: 'गुगल ड्राइभमा ब्याकअप गर्नुहोस्', es: 'Respaldar en Google Drive', fr: 'Sauvegarder sur Google Drive', de: 'In Google Drive sichern', ja: 'Googleドライブにバックアップ', zh: '备份到 Google 云端硬盘', it: 'Esegui backup su Google Drive'),
                          icon: HugeIcons.strokeRoundedCloudUpload,
                          onPressed: (_isDriveBackingUp || _isDriveRestoring)
                              ? null
                              : () => _handleGoogleDriveBackup(context),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        AppButton(
                          _isDriveRestoring
                              ? tr.t('Restoring...', ne: 'रिस्टोर हुँदैछ...', es: 'Restaurando...', fr: 'Restauration...', de: 'Lade...', ja: '復元中...', zh: '正在恢复...', it: 'Ripristino...')
                              : tr.t('Restore from Google Drive', ne: 'गुगल ड्राइभबाट रिस्टोर गर्नुहोस्', es: 'Restaurar desde Google Drive', fr: 'Restaurer depuis Google Drive', de: 'Aus Google Drive wiederherstellen', ja: 'Googleドライブから復元', zh: '从 Google 云端硬盘恢复', it: 'Ripristina da Google Drive'),
                          kind: AppButtonKind.secondary,
                          icon: HugeIcons.strokeRoundedCloudDownload,
                          onPressed: (_isDriveBackingUp || _isDriveRestoring)
                              ? null
                              : () => _handleGoogleDriveRestore(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.lg),

                  // Hyprwise Cloud Sync Card (Pro)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const IconTile(
                              HugeIcons.strokeRoundedCloud,
                              size: 44,
                            ),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    _authService.isAuthenticated
                                        ? tr.connectedAccountEmail(
                                            _authService.currentUser?.email ?? '',
                                          )
                                        : tr.signInToSyncHono,
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                _isCloudPushing
                                    ? tr.t('Pushing...', ne: 'अपलोड हुँदैछ...', es: 'Subiendo...', fr: 'Envoi...', de: 'Sende...', ja: '送信中...', zh: '同步中...', it: 'Invio...')
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
                                    ? tr.t('Pulling...', ne: 'डाउनलोड हुँदैछ...', es: 'Descargando...', fr: 'Récupération...', de: 'Lade...', ja: '取得中...', zh: '拉取中...', it: 'Scaricamento...')
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
                ] else ...[
                  // ==========================================================
                  // TAB 1: EXPORT & LOCAL FILES
                  // ==========================================================
                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const IconTile(
                              HugeIcons.strokeRoundedFileExport,
                              size: 44,
                            ),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    tr.t(
                                      'Export CSV spreadsheets for Excel/Sheets, full JSON backups, or summary reports.',
                                      ne: 'CSV स्प्रेडसिट, पूर्ण JSON ब्याकअप वा सारांश रिपोर्ट निर्यात गर्नुहोस्।',
                                      es: 'Exporta hojas CSV para Excel, respaldos JSON o informes resumidos.',
                                      fr: 'Exportez des fichiers CSV, des sauvegardes JSON ou des rapports.',
                                      de: 'CSV-Tabellen, vollständige JSON-Backups oder Berichte exportieren.',
                                      ja: 'CSVスプレッドシート、JSONバックアップ、レポートを出力します。',
                                      zh: '导出适用于 Excel 的 CSV 表格、完整 JSON 备份或财务汇总报告。',
                                      it: 'Esporta fogli CSV, backup JSON completi o report riepilogativi.',
                                    ),
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.lg),
                        AppButton(
                          tr.t(
                            'Choose Export Format',
                            ne: 'निर्यात ढाँचा छान्नुहोस्',
                            es: 'Elegir formato de exportación',
                            fr: 'Choisir le format d\'export',
                            de: 'Exportformat wählen',
                            ja: 'エクスポート形式を選択',
                            zh: '选择导出格式',
                            it: 'Scegli formato di esportazione',
                          ),
                          icon: HugeIcons.strokeRoundedDownload01,
                          onPressed: () => ExportService.showExportDialog(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.lg),

                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconTile(
                              HugeIcons.strokeRoundedFolderOpen,
                              size: 44,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    tr.t(
                                      'Select a saved Hyprwise .json backup file from your device storage to restore all records.',
                                      ne: 'फोनमा सेभ गरिएको .json ब्याकअप फाइल छानेर सबै रेकर्डहरू रिस्टोर गर्नुहोस्।',
                                      es: 'Selecciona un archivo .json guardado en tu dispositivo para restaurar tus datos.',
                                      fr: 'Sélectionnez un fichier .json sur votre appareil pour restaurer vos données.',
                                      de: 'Wählen Sie eine gespeicherte .json-Datei vom Gerät zur Wiederherstellung.',
                                      ja: '端末内の .json バックアップファイルを選択して全データを復元します。',
                                      zh: '从设备存储中选择已保存的 Hyprwise .json 备份文件以恢复全部记录。',
                                      it: 'Seleziona un file .json salvato sul dispositivo per ripristinare i dati.',
                                    ),
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.lg),
                        AppButton(
                          tr.t(
                            'Select .json Backup File',
                            ne: '.json ब्याकअप फाइल छान्नुहोस्',
                            es: 'Seleccionar archivo .json',
                            fr: 'Sélectionner un fichier .json',
                            de: '.json-Datei auswählen',
                            ja: '.json バックアップファイルを選択',
                            zh: '选择 .json 备份文件',
                            it: 'Seleziona file .json',
                          ),
                          kind: AppButtonKind.secondary,
                          icon: HugeIcons.strokeRoundedUpload01,
                          onPressed: () => _pickAndRestoreBackup(context, _viewModel),
                        ),
                      ],
                    ),
                  ),
                ],
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
