import 'package:flutter/material.dart';

import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final _notifications = const [
    _NotifData(
      icon: Icons.satellite_alt,
      title: 'New Hotspot Detected — HS-001',
      body:
          'NDVI drop of −42% detected in Paddy field (3.2 ha) via Planet NICFI. '
          'Elephant raid suspected. Verification required.',
      time: '10 Mar 2024  •  08:30',
      color: AppColors.alertHigh,
      tag: 'HIGH RISK',
    ),
    _NotifData(
      icon: Icons.satellite_alt,
      title: 'New Hotspot Detected — HS-002',
      body:
          'NDVI drop of −31% detected in Banana field (1.8 ha) via Planet NICFI. '
          'Flood damage suspected. Verification required.',
      time: '11 Mar 2024  •  14:15',
      color: AppColors.alertMedium,
      tag: 'MEDIUM RISK',
    ),
    _NotifData(
      icon: Icons.satellite_alt,
      title: 'New Hotspot Detected — HS-003',
      body:
          'NDVI drop of −24% detected in Coconut grove (2.8 ha) via Planet NICFI. '
          'Wind damage suspected.',
      time: '09 Mar 2024  •  11:45',
      color: AppColors.alertMedium,
      tag: 'MEDIUM RISK',
    ),
    _NotifData(
      icon: Icons.check_circle_outline,
      title: 'Claim CLM-2024-001 Ready',
      body:
          'Your claim dossier is AIMS-compliant and ready for submission. '
          'AI damage score: 67.4%. Parcel: LND-KL-011-2201.',
      time: '12 Mar 2024  •  12:00',
      color: AppColors.accent,
      tag: 'CLAIM READY',
    ),
    _NotifData(
      icon: Icons.hourglass_empty_rounded,
      title: 'Claim CLM-2024-002 Under Review',
      body:
          'Your flood damage claim is currently under review by the agricultural '
          'insurance authority. Estimated 5–7 working days for decision.',
      time: '11 Mar 2024  •  18:30',
      color: AppColors.alertMedium,
      tag: 'UNDER REVIEW',
    ),
    _NotifData(
      icon: Icons.tips_and_updates_outlined,
      title: 'Tip: Capture within 10 m for accuracy',
      body:
          'For best AI segmentation results, ensure you are within 10 metres '
          'of the satellite-detected hotspot centre before capturing evidence.',
      time: '08 Mar 2024  •  09:00',
      color: AppColors.primary,
      tag: 'TIP',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.alertHigh.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.alertHigh.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${_notifications.length} NEW',
                style: const TextStyle(
                  color: AppColors.alertHigh,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final start = (index * 0.10).clamp(0.0, 1.0);
          final end = (start + 0.4).clamp(0.0, 1.0);
          final fade = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _entryController,
              curve: Interval(start, end, curve: Curves.easeOut),
            ),
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _entryController,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            ),
          );

          return AnimatedBuilder(
            animation: _entryController,
            builder: (context, child) => FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotifCard(data: notif),
            ),
          );
        },
      ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color color;
  final String tag;

  const _NotifData({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.tag,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifData data;
  const _NotifCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: data.color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        data.tag,
                        style: TextStyle(
                          color: data.color,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.time,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
