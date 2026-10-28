import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class LiveShiftScreen extends StatelessWidget {
  const LiveShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final shift = viewModel.activeShift;
        final text = Theme.of(context).textTheme;
        final colors = context.colors;
        final tr = context.strings;

        if (shift == null) {
          return PopScope(
            canPop: context.canPop(),
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              context.go(AppRoutes.home);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(tr.liveShift),
                leading: BackButton(onPressed: handleBack),
              ),
              body: Center(
                child: EmptyState(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  title: tr.noActiveShift,
                  message: tr.notCurrentlyClockedIn,
                  actionLabel: tr.returnHome,
                  onAction: () => context.go(AppRoutes.home),
                ),
              ),
            ),
          );
        }

        final job = viewModel.jobsById[shift.jobId];
        final startTime = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
        final elapsed = viewModel.activeShiftElapsed;
        final liveEarnings = viewModel.activeShiftLiveEarnings;

        return PopScope(
          canPop: context.canPop(),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            context.go(AppRoutes.home);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: handleBack),
              title: Text(job?.name ?? tr.activeShift),
              elevation: 0,
              backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(
                  viewModel.isOnBreak ? Icons.play_arrow_rounded : Icons.coffee_rounded,
                ),
                tooltip: viewModel.isOnBreak ? tr.resumeShift : tr.takeBreak,
                onPressed: () => viewModel.toggleBreak(),
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar_outlined),
                tooltip: tr.editStartTime,
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(startTime),
                  );
                  if (picked != null) {
                    final newStart = DateTime(
                      startTime.year,
                      startTime.month,
                      startTime.day,
                      picked.hour,
                      picked.minute,
                    );
                    await viewModel.shiftRepo.update(shift.id, startAt: newStart);
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.page),
              children: [
                Row(
                  children: [
                    Text(tr.startedAt(AppDate.timeOnly(startTime)), style: text.bodySmall),
                    const Spacer(),
                    StatusChip(tr.inProgress, tone: ChipTone.success),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(job?.name ?? tr.activeShift, style: text.headlineMedium),
                const SizedBox(height: AppSpace.xxl),

                Center(
                  child: Column(
                    children: [
                      if (viewModel.isOnBreak) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.warningBg,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(HugeIcons.strokeRoundedCoffee01, size: 14, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text(
                                tr.onBreakTimerPausedUpper,
                                style: text.labelSmall?.copyWith(color: colors.warning, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                      ],
                      Text(
                        _formatTimer(elapsed),
                        style: text.displayLarge?.copyWith(
                          fontFamily: 'RedditMono',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: viewModel.isOnBreak ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      if (viewModel.isOnBreak)
                        Text(
                          '${tr.breakTime}: ${_formatTimer(viewModel.currentBreakDuration)}',
                          style: text.bodyMedium?.copyWith(
                            color: colors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (liveEarnings != null)
                        Text(
                          '≈ ${MoneyFormatter.format(liveEarnings.earningsMinor, job?.currencyCode ?? viewModel.baseCurrency)} ${tr.earned}',
                          style: text.bodyMedium?.copyWith(
                            color: colors.income,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.xxxl),
                AppButton(
                  viewModel.isOnBreak ? tr.resumeShift : tr.takeBreak,
                  icon: viewModel.isOnBreak ? HugeIcons.strokeRoundedPlay : HugeIcons.strokeRoundedCoffee01,
                  kind: viewModel.isOnBreak ? AppButtonKind.primary : AppButtonKind.outline,
                  onPressed: () => viewModel.toggleBreak(),
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  tr.endShift,
                  kind: AppButtonKind.danger,
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: tr.endShiftNow,
                      message: '${job?.name ?? "Shift"} · ${elapsed.inHours}h ${elapsed.inMinutes % 60}m (${viewModel.currentBreakMinutes}m).',
                      confirmLabel: tr.endShift,
                      cancelLabel: tr.keepWorking,
                    );
                    if (confirmed && context.mounted) {
                      final earnings = await viewModel.endShift(
                        shift.id,
                        breakMinutes: viewModel.currentBreakMinutes,
                      );
                      if (context.mounted) {
                        context.go(AppRoutes.shiftDone(shift.id), extra: earnings);
                      }
                    }
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  tr.editStartTime,
                  kind: AppButtonKind.outline,
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                    );
                    if (picked != null) {
                      final newStart = DateTime(
                        startTime.year,
                        startTime.month,
                        startTime.day,
                        picked.hour,
                        picked.minute,
                      );
                      await viewModel.shiftRepo.update(shift.id, startAt: newStart);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  String _formatTimer(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
