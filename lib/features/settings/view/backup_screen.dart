import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/export/export_service.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/network/api_client.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<SettingsViewModel>();
    final authService = getIt<AuthService>();
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppTopBar(
        title: tr.backupExportRestore,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.backUpYourData,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    tr.t(
                      'Your data stays safe on your device. Backup copies to Google Drive or Hyprwise Cloud so you can restore effortlessly on any new phone.',
                      ne: 'तपाईंको वित्तीय डाटा यन्त्रमै सुरक्षित रहन्छ। गुगल ड्राइभ वा हाइपरवाइज क्लाउडमार्फत सुरक्षित प्रतिलिपि राख्नुहोस् ता कि फोन हराउँदा वा नयाँ किन्दा सजिलै फिर्ता ल्याउन सकियोस्।',
                      es: 'Tus datos permanecen seguros en tu dispositivo. Guarda copias en Google Drive o Hyprwise Cloud para restaurar fácilmente.',
                      fr: 'Vos données restent sécurisées sur votre appareil. Sauvegardez sur Drive ou Cloud pour restaurer à tout moment.',
                      de: 'Ihre Daten bleiben sicher auf Ihrem Gerät. Erstellen Sie Backups in Google Drive oder Hyprwise Cloud.',
                      ja: 'データは端末内に安全に保管されます。Googleドライブやクラウドにバックアップしておけば機種変更時も安心です。',
                      zh: '所有数据安全保存在本机。通过云端硬盘或Hyprwise云备份，更换手机轻松一键恢复。',
                      it: 'I tuoi dati rimangono al sicuro sul tuo dispositivo. Esegui backup su Drive o Cloud.',
                    ),
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _FeaturePoint(
                    icon: HugeIcons.strokeRoundedLockPassword,
                    title: tr.encryptedBeforeUpload,
                    subtitle: tr.leavesPhoneUnreadable,
                  ),
                  const SizedBox(height: AppSpace.md),
                  _FeaturePoint(
                    icon: HugeIcons.strokeRoundedGoogleDrive,
                    title: tr.storedInGoogleDrive,
                    subtitle: tr.directlyInPrivateStorage,
                  ),
                  const SizedBox(height: AppSpace.md),
                  _FeaturePoint(
                    icon: HugeIcons.strokeRoundedSmartPhone01,
                    title: tr.restoreAnytimeNewPhone,
                    subtitle: tr.oneClickToRestore,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Google Drive Backup
                  ListRow(
                    leading: const IconTile(HugeIcons.strokeRoundedGoogleDrive),
                    title: tr.googleDriveBackup,
                    subtitle: tr.googleDriveBackupDesc,
                    trailing: const Chevron(),
                    onTap: () => _backupToGoogleDrive(context),
                  ),
                  const RowDivider(),

                  // Hyprwise Cloud Sync (Hono Backend)
                  ListRow(
                    leading: const IconTile(HugeIcons.strokeRoundedCloud),
                    title: tr.hyprwiseCloudSync,
                    subtitle: authService.isAuthenticated
                        ? tr.connectedAccountEmail(authService.currentUser?.email ?? '')
                        : tr.signInToSyncHono,
                    onTap: () {
                      final subService = getIt<SubscriptionService>();
                      if (!subService.isPro) {
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
                      _showCloudSyncSheet(context, viewModel, authService);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!getIt<SubscriptionService>().isPro) ...[
                          const ProCrownBadge(isCompact: true),
                          const SizedBox(width: AppSpace.xs),
                        ],
                        const Chevron(),
                      ],
                    ),
                  ),
                  const RowDivider(),

                  // Export formats
                  ListRow(
                    leading: const IconTile(HugeIcons.strokeRoundedDownload01),
                    title: tr.exportDataFormats,
                    subtitle: tr.saveToDownloadsOrShare,
                    trailing: const Chevron(),
                    onTap: () => ExportService.showExportDialog(context),
                  ),
                  const RowDivider(),

                  // Restore from JSON
                  ListRow(
                    leading: const IconTile(HugeIcons.strokeRoundedUpload01),
                    title: tr.restoreFromJsonBackup,
                    subtitle: tr.chooseJsonBackupFile,
                    trailing: const Chevron(),
                    onTap: () => _pickAndRestoreBackup(context, viewModel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),

            AppButton(
              tr.done,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupToGoogleDrive(BuildContext context) async {
    final tr = context.strings;
    try {
      showToast(context, tr.preparingDriveBackup);
      final dataRepo = getIt<DataRepository>();
      final jsonContent = await dataRepo.exportJson();

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormatter.numeric(DateTime.now()).replaceAll('/', '-');
      final fileName = 'hyprwise_backup_$dateStr.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json', name: fileName)],
          subject: 'Hyprwise Finance Backup ($dateStr)',
          text: 'Encrypted backup file from Hyprwise. Save this to your Google Drive.',
        ),
      );

      if (context.mounted) {
        showToast(context, tr.chooseDriveToComplete);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Backup error: $e');
      }
    }
  }

  void _showCloudSyncSheet(
    BuildContext context,
    SettingsViewModel viewModel,
    AuthService authService,
  ) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        bool isSyncing = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(HugeIcons.strokeRoundedCloud, size: 22, color: scheme.primary),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.hyprwiseCloudSync,
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authService.isAuthenticated
                                  ? (authService.currentUser?.email ?? 'Logged in')
                                  : tr.offlineSignInRequired,
                              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.serverSyncStatus,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr.t(
                            'End-to-end encrypted backup powered by Hyprwise decoupled Hono sync engine.',
                            ne: 'हाम्रो सुरक्षित Hono ब्याकइन्ड सर्भरमार्फत तपाईंको डाटा इन्क्रिप्ट गरेर सुरक्षित राखिन्छ।',
                            es: 'Copia cifrada de extremo a extremo mediante el motor de sincronización Hono de Hyprwise.',
                            fr: 'Sauvegarde chiffrée de bout en bout propulsée par le moteur Hono d\'Hyprwise.',
                            de: 'Ende-zu-Ende verschlüsselte Sicherung mit der Hyprwise Hono-Engine.',
                            ja: 'Hyprwiseの安全なHono同期エンジンによる完全暗号化バックアップ。',
                            zh: '基于 Hyprwise 专属 Hono 云端引擎打造的端到端高强度加密备份。',
                            it: 'Backup crittografato end-to-end con il motore di sincronizzazione Hono.',
                          ),
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  // Push Button
                  AppButton(
                    tr.pushDataToCloud,
                    onPressed: isSyncing
                        ? null
                        : () async {
                            setSheetState(() => isSyncing = true);
                            try {
                              final dataRepo = getIt<DataRepository>();
                              final jsonString = await dataRepo.exportJson();
                              final dataMap = jsonDecode(jsonString) as Map<String, dynamic>;

                              final result = await ApiClient.instance.pushSync(dataMap);
                              if (result != null && result['success'] == true && context.mounted) {
                                final v = result['version'] ?? 1;
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
                                Navigator.of(ctx).pop();
                                return;
                              }

                              if (context.mounted) {
                                showToast(
                                  context,
                                  tr.couldNotConnectServer,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showToast(context, 'Sync error: $e');
                              }
                            } finally {
                              setSheetState(() => isSyncing = false);
                            }
                          },
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Pull Button
                  AppButton(
                    tr.pullDataFromCloud,
                    kind: AppButtonKind.secondary,
                    onPressed: isSyncing
                        ? null
                        : () async {
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

                            if (confirmed && context.mounted) {
                              setSheetState(() => isSyncing = true);
                              try {
                                final result = await ApiClient.instance.pullSync();
                                if (result == null || result['empty'] == true || result['data'] == null) {
                                  if (context.mounted) {
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
                                  }
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
                                  Navigator.of(ctx).pop();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showToast(context, 'Restore error: $e');
                                }
                              } finally {
                                setSheetState(() => isSyncing = false);
                              }
                            }
                          },
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  }

  Future<void> _pickAndRestoreBackup(BuildContext context, SettingsViewModel viewModel) async {
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

class _FeaturePoint extends StatelessWidget {
  const _FeaturePoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconGlyph icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconTile(icon),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
