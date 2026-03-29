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
import '../theme/app_theme.dart';

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

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

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
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (value) {
            setState(() {
              _index = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Claims',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
