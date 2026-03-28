import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/feature_card.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          FeatureCard(
            icon: Icons.help_outline,
            title: 'How claim verification works',
            subtitle: 'Read step-by-step guidance for field evidence capture',
          ),
          SizedBox(height: 8),
          FeatureCard(
            icon: Icons.chat_bubble_outline,
            title: 'Contact support',
            subtitle: 'Email: support@agrisentinel.demo',
          ),
          SizedBox(height: 8),
          FeatureCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            subtitle: 'Demo policy page (placeholder)',
          ),
          SizedBox(height: 8),
          FeatureCard(
            icon: Icons.gavel_outlined,
            title: 'Terms of service',
            subtitle: 'Demo terms page (placeholder)',
          ),
        ],
      ),
    );
  }
}
