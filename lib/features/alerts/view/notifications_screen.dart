import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/alerts/data/model/alerts.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        getIt<AlertsViewModel>().markAllAsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AlertsViewModel>();
    final tr = context.strings;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final alerts = viewModel.alerts;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.notifications,
            actions: [
              TopBarAction(HugeIcons.strokeRoundedSlidersHorizontal, onPressed: () => context.push(AppRoutes.alerts)),
            ],
          ),
          body: SafeArea(
            child: alerts.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: HugeIcons.strokeRoundedNotification01,
                      title: tr.allCaughtUp,
                      message: tr.notificationsEmptySubtitle,
                      actionLabel: tr.manageAlerts,
                      onAction: () => context.push(AppRoutes.alerts),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                        child: Text(tr.today, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < alerts.length; i++) ...[
                              if (i > 0) const RowDivider(),
                              Padding(
                                padding: const EdgeInsets.all(AppSpace.lg),
                                child: Row(
                                  children: [
                                    IconTile(
                                      alerts[i].severity == AlertSeverity.critical
                                          ? HugeIcons.strokeRoundedAlertCircle
                                          : HugeIcons.strokeRoundedInformationCircle,
                                      size: 36,
                                    ),
                                    const SizedBox(width: AppSpace.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(alerts[i].title, style: text.titleSmall),
                                          Text(alerts[i].message, style: text.bodySmall),
                                        ],
                                      ),
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
          ),
        );
      },
    );
  }
}
