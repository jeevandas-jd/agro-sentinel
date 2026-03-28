import 'package:flutter/material.dart';

import '../features/auth/auth_models.dart';
import '../features/auth/auth_service.dart';
import '../features/claims/claims_history_page.dart';
import '../features/more/more_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/profile_service.dart';
import '../features/settings/settings_page.dart';
import '../features/support/support_page.dart';
import '../screens/dashboard_screen.dart';

class AppShell extends StatefulWidget {
  final DemoUser user;
  final AuthService authService;
  final Future<void> Function(DemoUser user) onUserUpdated;
  final Future<void> Function() onLogout;

  const AppShell({
    super.key,
    required this.user,
    required this.authService,
    required this.onUserUpdated,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          onChangePassword: (currentPassword, newPassword) {
            return widget.authService.changePassword(
              email: widget.user.email,
              currentPassword: currentPassword,
              newPassword: newPassword,
            );
          },
          onDeleteAccount: () async {
            await widget.authService.deleteAccount(widget.user.email);
            await widget.onLogout();
          },
        ),
      ),
    );
  }

  void _openSupport() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SupportPage()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardScreen(),
      const ClaimsHistoryPage(),
      ProfilePage(
        user: widget.user,
        profileService: ProfileService(widget.authService),
        onUserUpdated: widget.onUserUpdated,
        onLogout: widget.onLogout,
      ),
      MorePage(
        onOpenNotifications: _openNotifications,
        onOpenSettings: _openSettings,
        onOpenSupport: _openSupport,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Claims',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_open),
            selectedIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
