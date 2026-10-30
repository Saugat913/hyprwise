import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
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

  bool _isCloudPushing = false;
  bool _isCloudPulling = false;
  int _selectedTab = 0;

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
        final lastBackupDate = lastLocalBackupMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastLocalBackupMs)
            : null;
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
                  // TAB 0: HYPRWISE CLOUD SYNC (PRO)
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppButton(
                              _isCloudPushing
                                  ? tr.t('Pushing...', ne: 'अपलोड हुँदैछ...', hi: 'अपलोड हो रहा है...', es: 'Subiendo...', fr: 'Envoi...', de: 'Sende...', ja: '送信中...', zh: '同步中...', it: 'Invio...')
                                  : tr.pushDataToCloud,
                              icon: HugeIcons.strokeRoundedUpload04,
                              onPressed: (_isCloudPushing || _isCloudPulling)
                                  ? null
                                  : () => _handleCloudPush(context),
                            ),
                            const SizedBox(height: AppSpace.sm),
                            AppButton(
                              _isCloudPulling
                                  ? tr.t('Pulling...', ne: 'डाउनलोड हुँदैछ...', hi: 'डाउनलोड हो रहा है...', es: 'Descargando...', fr: 'Récupération...', de: 'Lade...', ja: '取得中...', zh: '拉取中...', it: 'Scaricamento...')
                                  : tr.pullDataFromCloud,
                              kind: AppButtonKind.secondary,
                              icon: HugeIcons.strokeRoundedDownload04,
                              onPressed: (_isCloudPushing || _isCloudPulling)
                                  ? null
                                  : () => _handleCloudPull(context),
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
      await _viewModel.settingsRepo.load();

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
