import 'package:flutter/material.dart';
import '../models/hotspot.dart';
import '../services/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/damage_gauge.dart';

class ClaimScreen extends StatefulWidget {
  final Hotspot hotspot;

  const ClaimScreen({super.key, required this.hotspot});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen>
    with SingleTickerProviderStateMixin {
  bool _isGenerating = false;
  bool _isGenerated = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _isGenerated = true;
    });
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accent, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Generated!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CLM-2024-001_dossier.pdf',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '842 KB  •  AIMS Compliant',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'The verified claim dossier is ready for submission to your insurance provider or government agricultural office.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = DemoData.aiAnalysis;
    final claim = DemoData.claim;
    final parcel = widget.hotspot.landParcel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim Dossier'),
            Text(
              'AI-Verified Evidence Report',
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Claim ID banner
              _buildClaimBanner(claim),
              const SizedBox(height: 16),

              // Before / After comparison
              _buildBeforeAfterSection(),
              const SizedBox(height: 16),

              // Land parcel details
              if (parcel != null) ...[
                _buildSectionHeader(
                  Icons.landscape,
                  'Land Parcel Details',
                ),
                const SizedBox(height: 10),
                _buildParcelCard(parcel),
                const SizedBox(height: 16),
              ],

              // AI Analysis
              _buildSectionHeader(Icons.biotech, 'AI Damage Analysis'),
              const SizedBox(height: 10),
              _buildAIAnalysisCard(analysis),
              const SizedBox(height: 16),

              // Satellite data
              _buildSectionHeader(
                Icons.satellite_alt,
                'Satellite Detection Data',
              ),
              const SizedBox(height: 10),
              _buildSatelliteCard(),
              const SizedBox(height: 16),

              // Evidence chain
              _buildSectionHeader(Icons.link, 'Evidence Chain'),
              const SizedBox(height: 10),
              _buildEvidenceChain(),
              const SizedBox(height: 28),

              // Generate button
              _buildGenerateButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimBanner(Map<String, dynamic> claim) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim['claimId'] as String,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Generated: ${claim['createdAt']}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'READY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.compare, 'Before / After Comparison'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ImageCard(
                label: 'BEFORE',
                sublabel: '10 Mar 2024',
                color: AppColors.accent,
                icon: Icons.satellite_alt,
                ndvi: '0.60',
                ndviLabel: 'NDVI Healthy',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ImageCard(
                label: 'AFTER',
                sublabel: '12 Mar 2024',
                color: AppColors.alertHigh,
                icon: Icons.camera_alt_outlined,
                ndvi: '0.18',
                ndviLabel: 'NDVI Damaged',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParcelCard(LandParcel parcel) {
    return _InfoCard(
      children: [
        _DetailRow(
          label: 'Parcel ID',
          value: parcel.parcelId,
          mono: true,
        ),
        _DetailRow(label: 'Owner', value: parcel.ownerName),
        _DetailRow(
          label: 'Registered Area',
          value: '${parcel.registeredAreaHa} ha',
        ),
        _DetailRow(
          label: 'Crop Type',
          value: widget.hotspot.cropType,
        ),
        _DetailRow(label: 'Season', value: parcel.cropSeason),
      ],
    );
  }

  Widget _buildAIAnalysisCard(Map<String, dynamic> analysis) {
    final damage = analysis['damagePercentage'] as double;
    final confidence = ((analysis['confidenceScore'] as double) * 100)
        .toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DamageGauge(percentage: damage, size: 100),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SmallDetailRow(
                      label: 'Damage Class',
                      value: analysis['damageClass'] as String,
                      valueColor: AppColors.alertHigh,
                    ),
                    const SizedBox(height: 10),
                    _SmallDetailRow(
                      label: 'AI Confidence',
                      value: '$confidence%',
                      valueColor: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _SmallDetailRow(
                      label: 'Healthy Pixels',
                      value:
                          '${((analysis['healthyPixelRatio'] as double) * 100).toStringAsFixed(1)}%',
                      valueColor: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _SmallDetailRow(
                      label: 'Damaged Pixels',
                      value:
                          '${((analysis['damagedPixelRatio'] as double) * 100).toStringAsFixed(1)}%',
                      valueColor: AppColors.alertHigh,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Evidence ID',
                  value: analysis['evidenceId'] as String,
                  mono: true,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Hotspot',
                  value: widget.hotspot.id,
                  mono: true,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Area Affected',
                  value: '${widget.hotspot.estimatedAreaHa} ha',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteCard() {
    final analysis = DemoData.aiAnalysis;
    return _InfoCard(
      children: [
        _DetailRow(label: 'Detection Date', value: '10 Mar 2024'),
        _DetailRow(
          label: 'NDVI Before',
          value: '${analysis['ndviBefore']}',
          valueColor: AppColors.accent,
        ),
        _DetailRow(
          label: 'NDVI After',
          value: '${analysis['ndviAfter']}',
          valueColor: AppColors.alertHigh,
        ),
        _DetailRow(
          label: 'NDVI Drop',
          value: '${widget.hotspot.ndviDeltaLabel} change',
          valueColor: AppColors.alertHigh,
        ),
        _DetailRow(
          label: 'Source',
          value: 'Planet NICFI / Google Earth Engine',
        ),
      ],
    );
  }

  Widget _buildEvidenceChain() {
    final items = [
      _EvidenceStep(
        icon: Icons.satellite_alt,
        title: 'Satellite Detection',
        subtitle: 'NDVI anomaly detected  •  10 Mar 2024',
        isComplete: true,
      ),
      _EvidenceStep(
        icon: Icons.explore,
        title: 'GPS Truth Walk',
        subtitle: 'Farmer navigated to hotspot  •  12 Mar 2024',
        isComplete: true,
      ),
      _EvidenceStep(
        icon: Icons.camera_alt_outlined,
        title: 'Ground Evidence Captured',
        subtitle: 'AI scan: 67.4% damage  •  Confidence 89%',
        isComplete: true,
      ),
      _EvidenceStep(
        icon: Icons.description_outlined,
        title: 'Claim Dossier Generated',
        subtitle: 'CLM-2024-001  •  AIMS Compliant PDF',
        isComplete: _isGenerated,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isComplete
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.border,
                          border: Border.all(
                            color: item.isComplete
                                ? AppColors.accent
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          item.isComplete ? Icons.check : item.icon,
                          size: 15,
                          color: item.isComplete
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                      if (i < items.length - 1)
                        Container(
                          width: 1.5,
                          height: 24,
                          color: item.isComplete
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.border,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < items.length - 1 ? 32 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: item.isComplete
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenerateButton() {
    if (_isGenerated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Generated',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'CLM-2024-001_dossier.pdf  •  842 KB',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 14),
              label: const Text('Download'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateReport,
        icon: _isGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf, size: 18),
        label: Text(
          _isGenerating ? 'Generating AIMS Report...' : 'Generate Report PDF',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _ImageCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final String ndvi;
  final String ndviLabel;

  const _ImageCard({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.ndvi,
    required this.ndviLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, size: 36, color: color.withValues(alpha: 0.4)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sublabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'NDVI $ndvi',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ndviLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          return Column(
            children: [
              entry.value,
              if (entry.key < children.length - 1) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _SmallDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SmallDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _MiniStat({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _EvidenceStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComplete;

  const _EvidenceStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isComplete,
  });
}
