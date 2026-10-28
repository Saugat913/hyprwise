import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class ManageJobsScreen extends StatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  State<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen> {
  final WorkViewModel _viewModel = getIt<WorkViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobs = _viewModel.jobs;
    final tr = context.strings;

    return Scaffold(
      appBar: AppTopBar(
        title: tr.manageJobs,
        actions: [
          TopBarAction(
            HugeIcons.strokeRoundedPlusSign,
            tooltip: tr.newJob,
            onPressed: () => context.push(AppRoutes.addJob),
          ),
        ],
      ),
      body: jobs.isEmpty
          ? _buildEmptyState(theme, tr)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpace.lg),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobCard(job, theme, tr);
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppStrings tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              HugeIcons.strokeRoundedBriefcase01,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              tr.noJobsAddedYet,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              tr.t(
                'Add your workplace or clients to track shifts, hourly earnings, and overtime.',
                ne: 'सिफ्ट, प्रति घण्टा आम्दानी र ओभरटाइम ट्र्याक गर्न आफ्नो कार्यस्थल वा ग्राहक थप्नुहोस्।',
                es: 'Añade tu lugar de trabajo para controlar turnos, ganancias y horas extra.',
                fr: 'Ajoutez votre lieu de travail pour suivre quarts, revenus et heures sup.',
                de: 'Fügen Sie Ihren Arbeitsplatz hinzu, um Schichten und Überstunden zu erfassen.',
                ja: 'シフト、時給、残業代を追跡するために勤務先を追加してください。',
                zh: '添加您的工作单位以准确计算排班、时薪与加班收益。',
                it: 'Aggiungi il tuo posto di lavoro per tracciare turni, guadagni e straordinari.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              tr.addFirstJob,
              compact: true,
              onPressed: () => context.push(AppRoutes.addJob),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Job job, ThemeData theme, AppStrings tr) {
    final colors = context.colors;
    final palette = [
      theme.colorScheme.primary,
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
      const Color(0xFFC2185B),
      const Color(0xFFE65100),
      const Color(0xFF6A1B9A),
    ];
    final color = palette[job.colorIndex % palette.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    job.name.isNotEmpty ? job.name[0].toUpperCase() : 'J',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (job.employer != null && job.employer!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          job.employer!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusChip(
                  job.isActive ? tr.active : tr.archived,
                  tone: job.isActive ? ChipTone.success : ChipTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.hourlyRateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)} ${tr.perHour}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.income,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(tr.editRate),
                      onPressed: () => _showEditJobSheet(context, job),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditJobSheet(BuildContext context, Job job) {
    final tr = context.strings;
    final nameController = TextEditingController(text: job.name);
    final rateController = TextEditingController(
      text: (job.hourlyRateMinor / 100).toStringAsFixed(job.hourlyRateMinor % 100 == 0 ? 0 : 2),
    );
    final employerController = TextEditingController(text: job.employer ?? '');
    final breakController = TextEditingController(text: job.defaultBreakMinutes.toString());
    final alertHoursController = TextEditingController(
      text: (job.longShiftAlertMinutes / 60).toStringAsFixed(job.longShiftAlertMinutes % 60 == 0 ? 0 : 1),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final text = Theme.of(ctx).textTheme;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpace.lg,
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr.editJobName(job.name),
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr.t(
                  'Past shifts will preserve their original rate. New shifts will use this updated rate.',
                  ne: 'विगतका सिफ्टहरूले आफ्नो मूल दर कायम राख्नेछन्। नयाँ सिफ्टहरूले यो अद्यावधिक दर प्रयोग गर्नेछन्।',
                  es: 'Los turnos anteriores conservarán su tarifa original. Los nuevos turnos usarán esta.',
                  fr: 'Les quarts passés conservent leur taux. Les nouveaux utiliseront ce nouveau taux.',
                  de: 'Vergangene Schichten behalten ihren Stundensatz. Neue nutzen die Aktualisierung.',
                  ja: '過去のシフトは当時の時給を保持します。今後のシフトに新しい時給が適用されます。',
                  zh: '过去的班次将保留原有时薪记录，新班次将采用更新后的时薪。',
                  it: 'I turni passati manterranno la tariffa originale. I nuovi utilizzeranno questa.',
                ),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: tr.jobNameLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr.hourlyRateWithCurrency(job.currencyCode),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
                  prefixText: '${job.currencyCode} ',
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: employerController,
                decoration: InputDecoration(
                  labelText: tr.employerVenueOptional,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: breakController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr.defaultBreakDurationLabel,
                        suffixText: tr.minuteAbbr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: TextField(
                      controller: alertHoursController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr.longShiftNotificationLabel,
                        suffixText: tr.hourAbbr,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                tr.saveChanges,
                onPressed: () async {
                  final newRate = double.tryParse(rateController.text.trim());
                  final newName = nameController.text.trim();
                  final newBreak = int.tryParse(breakController.text.trim()) ?? job.defaultBreakMinutes;
                  final newAlertHours = double.tryParse(alertHoursController.text.trim());
                  final newAlertMin = newAlertHours != null
                      ? (newAlertHours * 60).round()
                      : job.longShiftAlertMinutes;
                  if (newRate != null && newRate > 0 && newName.isNotEmpty) {
                    await _viewModel.updateJob(
                      job.id,
                      name: newName,
                      hourlyRateMinor: (newRate * 100).round(),
                      employer: employerController.text.trim().isEmpty ? null : employerController.text.trim(),
                      defaultBreakMinutes: newBreak,
                      longShiftAlertMinutes: newAlertMin,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
