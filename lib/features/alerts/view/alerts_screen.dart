import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AlertsViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final tr = context.strings;
        final settings = viewModel.settings;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.alertPreferences,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.whichAlertsQuestion,
                    style: text.headlineMedium,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    tr.changeThemAnytime,
                    style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  Expanded(
                    child: ListView(
                      children: [
                        SwitchRow(
                          title: tr.shiftRemindersTitle,
                          subtitle: tr.oneHourBefore,
                          value: settings.shiftReminders,
                          onChanged: viewModel.toggleShiftReminders,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.clockOutReminderTitle,
                          subtitle: tr.after6Hours,
                          value: settings.clockOutReminder,
                          onChanged: viewModel.toggleClockOutReminder,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.billsDueTitle,
                          subtitle: tr.oneDayBefore,
                          value: settings.billsDue,
                          onChanged: viewModel.toggleBillsDue,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.goalNudgesTitle,
                          subtitle: tr.weekly,
                          value: settings.goalNudges,
                          onChanged: viewModel.toggleGoalNudges,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.weeklySummaryTitle,
                          subtitle: tr.sundayEvening,
                          value: settings.weeklySummary,
                          onChanged: viewModel.toggleWeeklySummary,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.quietHoursTitle,
                          subtitle: tr.quietHoursTimeRange,
                          value: settings.quietHours,
                          onChanged: viewModel.toggleQuietHours,
                        ),
                      ],
                    ),
                  ),

                  AppButton(
                    tr.done,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
