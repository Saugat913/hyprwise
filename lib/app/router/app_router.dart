import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/accounts/view/accounts_screen.dart';
import 'package:finance_tracker/features/accounts/view/wizards/add_account_wizard.dart';
import 'package:finance_tracker/features/accounts/view/wizards/edit_account_screen.dart';
import 'package:finance_tracker/features/alerts/view/alerts_screen.dart';
import 'package:finance_tracker/features/alerts/view/notifications_screen.dart';
import 'package:finance_tracker/features/analytics/view/analytics_screen.dart';
import 'package:finance_tracker/features/assistant/view/assistant_screen.dart';
import 'package:finance_tracker/features/calendar/view/calendar_screen.dart';
import 'package:finance_tracker/features/home/view/home_screen.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/view/money_screen.dart';
import 'package:finance_tracker/features/money/view/wizards/add_transaction_wizard.dart';
import 'package:finance_tracker/features/onboarding/view/currency_first_run_screen.dart';
import 'package:finance_tracker/features/onboarding/view/welcome_screen.dart';
import 'package:finance_tracker/features/goals/view/goal_screen.dart';
import 'package:finance_tracker/features/goals/view/wizards/add_goal_wizard.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/view/debts_screen.dart';
import 'package:finance_tracker/features/debts/view/wizards/add_debt_wizard.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/auth/view/login_screen.dart';
import 'package:finance_tracker/features/categories/view/categories_screen.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/settings/view/backup_screen.dart';
import 'package:finance_tracker/features/settings/view/currency_settings_screen.dart';
import 'package:finance_tracker/features/settings/view/manage_jobs_screen.dart';
import 'package:finance_tracker/features/settings/view/settings_screen.dart';
import 'package:finance_tracker/features/subscription/view/paywall_screen.dart';
import 'package:finance_tracker/features/shell/view/app_shell.dart';
import 'package:finance_tracker/features/transfers/presentation/transfers_screen.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/view/wizards/add_job_wizard.dart';
import 'package:finance_tracker/features/work/view/wizards/live_shift_screen.dart';
import 'package:finance_tracker/features/work/view/wizards/schedule_shift_wizard.dart';
import 'package:finance_tracker/features/work/view/wizards/shift_done_screen.dart';
import 'package:finance_tracker/features/work/view/wizards/start_shift_sheet.dart';
import 'package:finance_tracker/features/work/view/work_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorCalendar = GlobalKey<NavigatorState>(debugLabel: 'shellCalendar');
final GlobalKey<NavigatorState> _shellNavigatorWork = GlobalKey<NavigatorState>(debugLabel: 'shellWork');
final GlobalKey<NavigatorState> _shellNavigatorPlan = GlobalKey<NavigatorState>(debugLabel: 'shellPlan');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [TelemetryService.instance.navigationObserver],
  refreshListenable: Listenable.merge([getIt<SettingsRepository>(), getIt<AuthService>()]),
  initialLocation: AppRoutes.home,
  redirect: (context, state) {
    final settingsRepo = getIt<SettingsRepository>();
    final authService = getIt<AuthService>();
    final location = state.matchedLocation;

    // While authenticating, syncing from cloud, or checking if account is new or returning:
    // keep on the current screen (LoginScreen displays the setup loading screen).
    // Never let an unauthenticated session reach in-app routes while busy.
    if (authService.isLoading || authService.isCloudSyncing) {
      final isEntry = location == AppRoutes.login ||
          location == AppRoutes.welcome ||
          location == AppRoutes.currency;
      if (isEntry || authService.isAuthenticated) return null;
      return settingsRepo.settings.onboarded ? AppRoutes.login : AppRoutes.welcome;
    }

    // 1. First-time install / Not yet onboarded
    if (!settingsRepo.settings.onboarded) {
      if (!authService.isAuthenticated) {
        // Allow unauthenticated users to view the welcome pitch or proceed to login
        if (location == AppRoutes.welcome || location == AppRoutes.login) {
          return null;
        }
        return AppRoutes.welcome;
      }
      // Authenticated but not onboarded: guide to currency selection
      return location == AppRoutes.currency ? null : AppRoutes.currency;
    }

    // 2. Already onboarded, but signed out: must log in
    if (!authService.isAuthenticated) {
      return location == AppRoutes.login ? null : AppRoutes.login;
    }

    // 3. Authenticated and onboarded: keep out of entry screens
    if (location == AppRoutes.login || location == AppRoutes.welcome || location == AppRoutes.currency) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    // Auth & Entry
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.currency,
      builder: (context, state) => const CurrencyFirstRunScreen(),
    ),

    // Bottom Navigation Shell (4 tabs)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(shell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHome,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCalendar,
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorWork,
          routes: [
            GoRoute(
              path: AppRoutes.work,
              builder: (context, state) => const WorkScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorPlan,
          routes: [
            GoRoute(
              path: AppRoutes.plan,
              builder: (context, state) => const PlanScreen(),
            ),
          ],
        ),
      ],
    ),

    // Analytics (pushed from Home / Add menu)
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.analytics,
      builder: (context, state) => const AnalyticsScreen(),
    ),

    // Money routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.money,
      builder: (context, state) => const MoneyScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addTransaction,
      builder: (context, state) {
        final typeStr = state.uri.queryParameters['type'];
        final initialType = typeStr == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        return AddTransactionWizard(initialType: initialType);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.transfers,
      builder: (context, state) => const TransfersScreen(),
    ),

    // Accounts routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.accounts,
      builder: (context, state) => const AccountsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addAccount,
      builder: (context, state) => const AddAccountWizard(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.accountPattern,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
        return EditAccountScreen(accountId: id);
      },
    ),

    // Work routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addJob,
      builder: (context, state) => const AddJobWizard(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.scheduleShift,
      builder: (context, state) {
        final initialDate = state.extra is DateTime ? state.extra as DateTime : null;
        return ScheduleShiftWizard(initialDate: initialDate);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.startShift,
      builder: (context, state) => const StartShiftSheet(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.liveShift,
      builder: (context, state) {
        final action = state.uri.queryParameters['action'];
        return LiveShiftScreen(initialAction: action);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.shiftDonePattern,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
        final earnings = state.extra is ShiftEarnings ? state.extra as ShiftEarnings : null;
        return ShiftDoneScreen(shiftId: id, earnings: earnings);
      },
    ),

    // Plan routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addGoal,
      builder: (context, state) => const AddGoalWizard(),
    ),

    // Alerts & Notifications
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.alerts,
      builder: (context, state) => const AlertsScreen(),
    ),

    // Assistant (animated dialog from bottom)
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.assistant,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const AssistantScreen(),
        fullscreenDialog: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: Curves.easeOutCubic),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    ),

    // Debts (Lending & Borrowing)
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.debts,
      builder: (context, state) => const DebtsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addDebt,
      builder: (context, state) {
        final queryType = state.uri.queryParameters['type'];
        final queryPerson = state.uri.queryParameters['person'];
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          return AddDebtWizard(
            initialType: map['type'] as DebtType? ?? (queryType == 'borrowed' ? DebtType.borrowed : DebtType.lent),
            initialPersonName: map['personName'] as String? ?? queryPerson,
          );
        }
        final initialType = state.extra is DebtType
            ? state.extra as DebtType
            : (queryType == 'borrowed' ? DebtType.borrowed : DebtType.lent);
        return AddDebtWizard(initialType: initialType, initialPersonName: queryPerson);
      },
    ),

    // Categories & Merchants
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.categories,
      builder: (context, state) => const CategoriesScreen(),
    ),

    // Settings
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.manageJobs,
      builder: (context, state) => const ManageJobsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.currencySettings,
      builder: (context, state) => const CurrencySettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.backup,
      builder: (context, state) => const BackupScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.paywall,
      builder: (context, state) => const PaywallScreen(),
    ),
  ],
);
