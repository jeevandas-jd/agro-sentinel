import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/feature_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <({String title, String subtitle, IconData icon})>[
      (
        title: 'New hotspot detected',
        subtitle: 'NDVI anomaly flagged in parcel LND-KL-011-2201',
        icon: Icons.warning_amber_rounded,
      ),
      (
        title: 'Claim review ready',
        subtitle: 'Your latest field evidence has been processed',
        icon: Icons.task_alt,
      ),
      (
        title: 'Advisory update',
        subtitle: 'Heavy rain forecast for your region this week',
        icon: Icons.cloud_queue,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return FeatureCard(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
          );
        },
      ),
    );
  }
}
