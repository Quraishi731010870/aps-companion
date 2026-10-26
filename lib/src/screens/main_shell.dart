import 'package:flutter/material.dart';

import '../data/mock_payment_gateway.dart';
import '../l10n/app_localizations.dart';
import 'activity_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'services_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.gateway});
  final PaymentGateway gateway;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        gateway: widget.gateway,
        onNotificationsPressed: () => setState(() => index = 2),
      ),
      ServicesScreen(gateway: widget.gateway),
      ActivityScreen(gateway: widget.gateway),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: context.tr('Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: context.tr('Services'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: context.tr('Activity'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: context.tr('Profile'),
          ),
        ],
      ),
    );
  }
}
