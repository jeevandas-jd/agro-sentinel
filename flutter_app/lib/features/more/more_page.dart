import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/feature_card.dart';

class MorePage extends StatelessWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSupport;

  const MorePage({
    super.key,
    required this.onOpenNotifications,
    required this.onOpenSettings,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FeatureCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'View hotspot alerts and claim updates',
            onTap: onOpenNotifications,
          ),
          const SizedBox(height: 8),
          FeatureCard(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Manage account and app preferences',
            onTap: onOpenSettings,
          ),
          const SizedBox(height: 8),
          FeatureCard(
            icon: Icons.support_agent,
            title: 'Help & support',
            subtitle: 'Get guidance and contact support',
            onTap: onOpenSupport,
          ),
        ],
      ),
    );
  }
}
