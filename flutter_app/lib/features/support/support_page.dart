import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const _faqs = [
    _FaqItem(
      question: 'What is NDVI and how does AgriSentinel use it?',
      answer:
          'NDVI (Normalised Difference Vegetation Index) measures crop health '
          'from satellite imagery. Values range from −1 to 1; healthy crops '
          'score above 0.4, while damaged areas drop significantly. '
          'AgriSentinel uses Planet NICFI imagery to compute NDVI before and '
          'after an event, flagging fields with abnormal drops as damage hotspots.',
    ),
    _FaqItem(
      question: 'How do I start a Truth Walk verification?',
      answer:
          'From the Dashboard, tap any hotspot card. The Field Detail screen '
          'shows the GPS compass pointing toward the satellite-detected damage '
          'zone. Follow the compass and use "Simulate Approach (Demo)" to test '
          'the proximity unlock. Once within 10 m of the hotspot, the '
          '"Capture Evidence" button becomes active.',
    ),
    _FaqItem(
      question: 'What happens during AI evidence capture?',
      answer:
          'The camera runs a U-Net semantic segmentation model on-device via '
          'TensorFlow Lite. It classifies each pixel as healthy (green) or '
          'damaged (brown/yellow), producing a damage percentage and confidence '
          'score. All results are geotagged with your current GPS coordinates '
          'and timestamp.',
    ),
    _FaqItem(
      question: 'What is an AIMS-compliant claim dossier?',
      answer:
          'AIMS (Agricultural Insurance Management System) is the standard '
          'format for crop insurance claims in India. AgriSentinel generates a '
          'PDF dossier containing satellite NDVI data, GPS-geotagged ground '
          'photos, AI damage scores, land parcel details, and an evidence '
          'chain — all formatted for direct submission to insurers or '
          'government agricultural offices.',
    ),
    _FaqItem(
      question: 'Can I file a claim without internet connectivity?',
      answer:
          'Yes. AgriSentinel works offline for evidence capture — photos, GPS '
          'data, and AI analysis are stored locally. The PDF can be generated '
          'on-device. You will need connectivity to submit the dossier to the '
          'AIMS portal.',
    ),
    _FaqItem(
      question: 'What satellite data sources does AgriSentinel use?',
      answer:
          'AgriSentinel uses Planet NICFI (Norway\'s International Climate and '
          'Forest Initiative) high-resolution tropical imagery at 4.77 m/pixel. '
          'NDVI analysis is performed via Google Earth Engine. In future, '
          'Sentinel-2 data will also be supported.',
    ),
  ];

  static const _contacts = [
    _ContactItem(
      icon: Icons.email_outlined,
      label: 'Email Support',
      value: 'support@agrisentinel.app',
      color: AppColors.alertVerified,
    ),
    _ContactItem(
      icon: Icons.help_outline,
      label: 'Farmer Helpline',
      value: '1800-XXX-XXXX (Toll-free)',
      color: AppColors.primary,
    ),
    _ContactItem(
      icon: Icons.language,
      label: 'Documentation',
      value: 'docs.agrisentinel.app',
      color: AppColors.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.l),
              boxShadow: AppShadows.raised,
            ),
            child: const Row(
              children: [
                Icon(Icons.eco_rounded, color: Colors.white, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AgriSentinel Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Satellite-Guided Crop Damage Verification',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact cards
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'CONTACT US',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ..._contacts.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ContactCard(item: c),
            ),
          ),

          const SizedBox(height: 16),

          // FAQ section
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ..._faqs.map(
            (faq) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FaqCard(item: faq),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _ContactCard extends StatelessWidget {
  final _ContactItem item;
  const _ContactCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final _FaqItem item;
  const _FaqCard({required this.item});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(
            color: _expanded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 250),
                  turns: _expanded ? 0.25 : 0,
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Container(
                height: 1,
                color: AppColors.border,
              ),
              const SizedBox(height: 10),
              Text(
                widget.item.answer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
