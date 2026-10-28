import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/view/widgets/shift_rate_slider_protocol.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class StartShiftSheet extends StatefulWidget {
  const StartShiftSheet({super.key});

  @override
  State<StartShiftSheet> createState() => _StartShiftSheetState();
}

class _StartShiftSheetState extends State<StartShiftSheet> {
  int? _selectedJobId;
  bool _remindClockOut = true;
  ShiftRateConfig? _rateConfig;

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();
    final jobs = viewModel.jobs;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    if (jobs.isEmpty) {
      return Scaffold(
        appBar: AppTopBar(title: tr.startShift),
        body: SafeArea(
          child: EmptyState(
            icon: HugeIcons.strokeRoundedBriefcase01,
            title: tr.noJobsFound,
            message: tr.addJobBeforeShift,
            actionLabel: tr.addJobChecklist,
            onAction: () {
              context.pop();
              context.push(AppRoutes.manageJobs);
            },
          ),
        ),
      );
    }

    final activeId = _selectedJobId ?? viewModel.selectedJob?.id ?? jobs.first.id;
    final selectedJob = viewModel.jobsById[activeId] ?? jobs.first;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppTopBar(
        title: tr.clockIn,
        actions: [
          TopBarAction(
            HugeIcons.strokeRoundedBriefcase01,
            tooltip: tr.manageJobs,
            onPressed: () => context.push(AppRoutes.manageJobs),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.page),
          children: [
            Text(tr.startYourShift, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpace.xs),
            Text(
              tr.selectWhichJobClocking,
              style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpace.lg),

            Text(tr.workplace, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpace.sm),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpace.sm,
                mainAxisSpacing: AppSpace.sm,
                childAspectRatio: 1.35,
              ),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final j = jobs[index];
                final isSelected = j.id == activeId;
                return _JobSelectionGridCard(
                  job: j,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedJobId = j.id),
                );
              },
            ),

            const SizedBox(height: AppSpace.md),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr.clockInTime, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(
                          '${tr.today} ${AppDate.timeOnly(now)}',
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(tr.liveBadge, tone: ChipTone.success),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),

            // Shift Hourly Rate & Overtime Slider Protocol
            ShiftRateSliderProtocol(
              baseHourlyRateMinor: selectedJob.hourlyRateMinor,
              currencyCode: selectedJob.currencyCode,
              shiftDurationHours: 8.0,
              initialConfig: _rateConfig,
              onChanged: (config) {
                setState(() => _rateConfig = config);
              },
            ),
            const SizedBox(height: AppSpace.md),

            SwitchRow(
              title: tr.remindMeClockOut,
              subtitle: tr.alertAfter6Hours,
              value: _remindClockOut,
              onChanged: (val) => setState(() => _remindClockOut = val),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                tr.clockInAs(selectedJob.name),
                icon: HugeIcons.strokeRoundedPlay,
                onPressed: () async {
                  final rateOverride = (_rateConfig != null && _rateConfig!.isCustom)
                      ? _rateConfig!.getRateOverrideMinor(
                          baseHourlyRateMinor: selectedJob.hourlyRateMinor,
                          durationHours: 8.0,
                        )
                      : null;
                  await viewModel.startShift(
                    jobId: selectedJob.id,
                    rateOverrideMinor: rateOverride,
                  );
                  if (context.mounted) {
                    context.go(AppRoutes.liveShift);
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                tr.cancel,
                kind: AppButtonKind.secondary,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobSelectionGridCard extends StatelessWidget {
  const _JobSelectionGridCard({
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final Job job;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary.withValues(alpha: 0.08) : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      HugeIcons.strokeRoundedBriefcase01,
                      size: 16,
                      color: isSelected ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                job.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)} / h',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
