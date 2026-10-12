import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedHome01),
            label: 'Home',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar03),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar03),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedBanknote),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedBanknote),
            label: 'Money',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedBriefcaseBusiness),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedBriefcaseBusiness),
            label: 'Work',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedAnalytics01),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedAnalytics01),
            label: 'Plan',
          ),
        ],
      ),
    );
  }
}
