import 'package:flutter/material.dart';

import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/feature_card.dart';

class ClaimsHistoryPage extends StatelessWidget {
  const ClaimsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hotspots = DemoData.hotspots;
    final claim = DemoData.claim;

    if (hotspots.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppStateView(
          icon: Icons.assignment_late_outlined,
          title: 'No claims yet',
          subtitle: 'Captured evidence and generated claims will appear here.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Claims History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FeatureCard(
            icon: Icons.assignment_turned_in_outlined,
            title: claim['claimId'] as String,
            subtitle:
                'Status: ${claim['status']} • Created: ${claim['createdAt']}',
          ),
          const SizedBox(height: 8),
          ...hotspots.map(
            (hotspot) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FeatureCard(
                icon: Icons.agriculture_outlined,
                title: '${hotspot.id} • ${hotspot.cropType}',
                subtitle:
                    'Severity: ${hotspot.severity.toUpperCase()} • Estimated ${hotspot.estimatedAreaHa} ha',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Milestone B demo: claims list is based on local data. '
              'Next step can connect this page to backend claim APIs.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
