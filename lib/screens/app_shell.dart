import '../state/providers.dart';
import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'plans_tab_screen.dart';
import 'trends_screen.dart';
import 'settings_screen.dart';
import 'community_screen.dart';
import 'checkin_screen.dart';
import '../services/analytics_service.dart';

/// Main app shell with bottom navigation
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshReminders();
  }

  Future<void> _refreshReminders() async {
    try {
      final profile = await ref.read(userProfileRepoProvider).getProfile();
      if (mounted && profile != null) {
        await NotificationService().setupNotifications(profile);
      }
    } catch (_) {
      // Saved preferences remain intact; Settings can explicitly retry.
    }
  }

  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    PlansTabScreen(),
    TrendsScreen(),
    CommunityScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Track screen views
    final screens = ['home', 'nutrition', 'trends', 'community', 'settings'];
    final analytics = AnalyticsService();
    analytics.logScreenView(screens[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Circles',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/checkin'),
              child: const Icon(Icons.add),
              tooltip: 'Daily Check-in',
            )
          : null,
    );
  }
}
