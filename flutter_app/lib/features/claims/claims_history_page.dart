import 'package:flutter/material.dart';

import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';

class ClaimsHistoryPage extends StatefulWidget {
  const ClaimsHistoryPage({super.key});

  @override
  State<ClaimsHistoryPage> createState() => _ClaimsHistoryPageState();
}

class _ClaimsHistoryPageState extends State<ClaimsHistoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    const n = 6;
    _cardFades = List.generate(n, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _cardSlides = List.generate(n, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, _) => FadeTransition(
        opacity: _cardFades[i],
        child: SlideTransition(position: _cardSlides[i], child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotspots = DemoData.hotspots;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claims History'),
            Text(
              'AIMS-Compliant Verified Dossiers',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'AIMS',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Summary stats row
          SliverToBoxAdapter(
            child: _animated(
              0,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildStatsRow(),
              ),
            ),
          ),

          // Section header: Active Claims
          SliverToBoxAdapter(
            child: _animated(
              1,
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  'ACTIVE CLAIMS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),

          // CLM-2024-001
          SliverToBoxAdapter(
            child: _animated(
              2,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ClaimCard(
                  claimId: 'CLM-2024-001',
                  hotspotId: hotspots[0].id,
                  cropType: hotspots[0].cropType,
                  status: 'READY FOR SUBMISSION',
                  statusColor: AppColors.accent,
                  createdAt: '12 Mar 2024',
                  damagePct: 67.4,
                  areaHa: hotspots[0].estimatedAreaHa,
                  cause: hotspots[0].damageCause,
                  ndviBefore: 0.60,
                  ndviAfter: hotspots[0].ndviScore,
                  parcelId: hotspots[0].landParcel?.parcelId ?? '—',
                ),
              ),
            ),
          ),

          // CLM-2024-002
          SliverToBoxAdapter(
            child: _animated(
              3,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _ClaimCard(
                  claimId: 'CLM-2024-002',
                  hotspotId: hotspots[1].id,
                  cropType: hotspots[1].cropType,
                  status: 'UNDER REVIEW',
                  statusColor: AppColors.alertMedium,
                  createdAt: '11 Mar 2024',
                  damagePct: 41.2,
                  areaHa: hotspots[1].estimatedAreaHa,
                  cause: hotspots[1].damageCause,
                  ndviBefore: 0.53,
                  ndviAfter: hotspots[1].ndviScore,
                  parcelId: hotspots[1].landParcel?.parcelId ?? '—',
                ),
              ),
            ),
          ),

          // Evidence Chain section
          SliverToBoxAdapter(
            child: _animated(
              4,
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  'EVIDENCE PIPELINE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _animated(
              5,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: _EvidenceChainCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatChip(
          label: 'Total Claims',
          value: '2',
          color: AppColors.primary,
          icon: Icons.assignment_outlined,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Ready',
          value: '1',
          color: AppColors.accent,
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Under Review',
          value: '1',
          color: AppColors.alertMedium,
          icon: Icons.hourglass_empty_rounded,
        ),
      ],
    );
  }
}

/// Individual claim card
class _ClaimCard extends StatelessWidget {
  final String claimId;
  final String hotspotId;
  final String cropType;
  final String status;
  final Color statusColor;
  final String createdAt;
  final double damagePct;
  final double areaHa;
  final String cause;
  final double ndviBefore;
  final double ndviAfter;
  final String parcelId;

  const _ClaimCard({
    required this.claimId,
    required this.hotspotId,
    required this.cropType,
    required this.status,
    required this.statusColor,
    required this.createdAt,
    required this.damagePct,
    required this.areaHa,
    required this.cause,
    required this.ndviBefore,
    required this.ndviAfter,
    required this.parcelId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadii.l),
                topRight: Radius.circular(AppRadii.l),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.12),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Icon(
                    Icons.verified_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claimId,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Generated: $createdAt  •  $hotspotId',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _DetailItem(
                        label: 'Crop', value: cropType, flex: 3),
                    _DetailItem(
                        label: 'Cause', value: cause, flex: 2),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _DetailItem(
                        label: 'Parcel ID',
                        value: parcelId,
                        flex: 3,
                        mono: true),
                    _DetailItem(
                        label: 'Area', value: '$areaHa ha', flex: 2),
                  ],
                ),
                const SizedBox(height: 12),
                // NDVI comparison bar
                _NdviBar(
                    before: ndviBefore,
                    after: ndviAfter,
                    damagePct: damagePct),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final int flex;
  final bool mono;

  const _DetailItem({
    required this.label,
    required this.value,
    this.flex = 1,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: mono ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NdviBar extends StatelessWidget {
  final double before;
  final double after;
  final double damagePct;

  const _NdviBar({
    required this.before,
    required this.after,
    required this.damagePct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadii.s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'NDVI CHANGE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                'Damage: ${damagePct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.alertHigh,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    before.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'BEFORE',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (after * 100).toInt(),
                            child: Container(
                              height: 8,
                              color: AppColors.ndviPositive,
                            ),
                          ),
                          Expanded(
                            flex: ((before - after) * 100).toInt(),
                            child: Container(
                              height: 8,
                              color: AppColors.ndviNegative,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: after / before,
                        backgroundColor:
                            AppColors.alertHigh.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    after.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppColors.alertHigh,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'AFTER',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat chip for summary row
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4-step evidence chain visualisation
class _EvidenceChainCard extends StatelessWidget {
  const _EvidenceChainCard();

  static const _steps = [
    _Step(
      icon: Icons.satellite_alt,
      title: 'Satellite Detection',
      subtitle: 'NDVI anomaly detected via Planet NICFI',
      color: AppColors.alertVerified,
      date: '10 Mar 2024',
    ),
    _Step(
      icon: Icons.gps_fixed,
      title: 'GPS Truth Walk',
      subtitle: 'Farmer navigated to hotspot using AgriSentinel',
      color: AppColors.primary,
      date: '12 Mar 2024',
    ),
    _Step(
      icon: Icons.biotech,
      title: 'AI Ground Evidence',
      subtitle: 'U-Net scan: 67.4% damage • Confidence 89%',
      color: AppColors.alertMedium,
      date: '12 Mar 2024',
    ),
    _Step(
      icon: Icons.picture_as_pdf_outlined,
      title: 'Claim Dossier',
      subtitle: 'CLM-2024-001 • AIMS Compliant PDF',
      color: AppColors.accent,
      date: '12 Mar 2024',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            _StepRow(step: _steps[i], stepNumber: i + 1),
            if (i < _steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Container(
                  width: 1,
                  height: 20,
                  color: AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String date;

  const _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.date,
  });
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final int stepNumber;

  const _StepRow({required this.step, required this.stepNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.color.withValues(alpha: 0.12),
              border: Border.all(color: step.color, width: 1.5),
            ),
            child: Icon(step.icon, color: step.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            step.date,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
