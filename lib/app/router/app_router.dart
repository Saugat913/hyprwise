import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:finance_tracker/features/shell/presentation/app_shell.dart';
import 'package:finance_tracker/features/placeholder/presentation/placeholder_screen.dart';
import 'package:finance_tracker/features/splash/presentation/app_splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const calendar = '/calendar';
  static const money = '/money';
  static const work = '/work';
  static const plan = '/plan';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const AppSplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder:
                  (context, state) => const PlaceholderScreen(
                    title: 'Home',
                    description: 'Your financial overview will live here.',
                    icon: HugeIcons.strokeRoundedHome01,
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder:
                  (context, state) => const PlaceholderScreen(
                    title: 'Calendar',
                    description: 'Explore transactions and upcoming dates.',
                    icon: HugeIcons.strokeRoundedCalendar03,
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.money,
              builder: (context, state) => const AccountsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.work,
              builder:
                  (context, state) => const PlaceholderScreen(
                    title: 'Work',
                    description: 'Track shifts and expected income.',
                    icon: HugeIcons.strokeRoundedBriefcaseBusiness,
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.plan,
              builder:
                  (context, state) => const PlaceholderScreen(
                    title: 'Plan',
                    description: 'Goals, forecasts and financial plans.',
                    icon: HugeIcons.strokeRoundedAnalytics01,
                  ),
            ),
          ],
        ),
      ],
    ),
  ],
);
