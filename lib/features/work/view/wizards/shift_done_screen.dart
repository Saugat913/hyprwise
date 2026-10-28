import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class ShiftDoneScreen extends StatelessWidget {
  const ShiftDoneScreen({super.key, required this.shiftId, this.earnings});

  final int shiftId;
  final ShiftEarnings? earnings;

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;

    final shift = viewModel.shifts.firstWhere((s) => s.id == shiftId, orElse: () => viewModel.shifts.first);
    final job = viewModel.jobsById[shift.jobId];

    final calculated = earnings ??
        (job != null ? ShiftEarnings.forShift(shift, job) : null);

    final hours = (calculated?.workedMinutes ?? 0) ~/ 60;
    final minutes = (calculated?.workedMinutes ?? 0) % 60;

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.shiftComplete),
          leading: BackButton(onPressed: handleBack),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.page),
            children: [
              const SizedBox(height: AppSpace.xxl),
            Text(tr.shiftComplete, style: text.headlineMedium),
            const SizedBox(height: AppSpace.xl),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.jobs, style: text.bodySmall),
                  const SizedBox(height: 2),
                  Text(job?.name ?? tr.activeShift, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpace.lg),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr.duration, style: text.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              '${hours}h ${minutes}m',
                              style: text.titleMedium?.copyWith(
                                fontFamily: 'RedditMono',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr.earned, style: text.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              '+${MoneyFormatter.format(calculated?.earningsMinor ?? 0, job?.currencyCode ?? viewModel.baseCurrency)}',
                              style: text.titleMedium?.copyWith(
                                color: colors.income,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.page),
          child: AppButton(
            tr.done,
            onPressed: handleBack,
          ),
        ),
      ),
    ),
  );
}
}
