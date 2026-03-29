import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/hotspot.dart';
import '../theme/app_theme.dart';
import '../widgets/compass_widget.dart';
import 'camera_screen.dart';

class NavigationScreen extends StatefulWidget {
  final Hotspot hotspot;

  const NavigationScreen({super.key, required this.hotspot});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  double _distanceMeters = 1400.0;
  bool _isSimulating = false;
  bool get _isUnlocked => _distanceMeters <= 10.0;

  late AnimationController _pulseController;
  late AnimationController _entryController;
  late AnimationController _liveController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _headerFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _liveBlink;

  static const double _targetBearing = 0.78;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _liveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _liveBlink = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _liveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    _liveController.dispose();
    super.dispose();
  }

  void _simulateApproach() async {
    if (_isSimulating) return;
    setState(() => _isSimulating = true);

    final steps = [1400.0, 950.0, 520.0, 210.0, 85.0, 30.0, 8.0];
    for (final dist in steps) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _distanceMeters = dist);
    }
    setState(() => _isSimulating = false);
  }

  String get _distanceLabel {
    if (_distanceMeters >= 1000) {
      return '${(_distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${_distanceMeters.toInt()} m';
  }

  double get _proximityFraction =>
      (1.0 - (_distanceMeters / 1400.0)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Aerial image header
              SliverToBoxAdapter(child: _buildAerialHeader()),

              // Main content cards
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDamageInfoCard(),
                          const SizedBox(height: 14),
                          _buildSatelliteDataCard(),
                          const SizedBox(height: 14),
                          _buildCompassSection(),
                          const SizedBox(height: 14),
                          _buildProximityBar(),
                          const SizedBox(height: 14),
                          if (!_isUnlocked)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isSimulating ? null : _simulateApproach,
                                icon: _isSimulating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(Icons.directions_walk,
                                        size: 16),
                                label: Text(
                                  _isSimulating
                                      ? 'Walking to hotspot...'
                                      : 'Simulate Approach (Demo)',
                                ),
                              ),
                            ),
                          if (!_isUnlocked) const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUnlocked
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CameraScreen(
                                              hotspot: widget.hotspot),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: Icon(
                                _isUnlocked
                                    ? Icons.camera_alt
                                    : Icons.lock_outline,
                                size: 18,
                              ),
                              label: Text(
                                _isUnlocked
                                    ? 'Capture Evidence'
                                    : 'Get within 10 m to unlock',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isUnlocked
                                    ? AppColors.primary
                                    : AppColors.border,
                                foregroundColor: _isUnlocked
                                    ? Colors.white
                                    : AppColors.textMuted,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back button overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.base,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAerialHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SizedBox(
        height: 280,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Simulated aerial field image
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A1A),
                    const Color(0xFF2D5226),
                    const Color(0xFF3A6B32),
                    const Color(0xFF1E4015),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Crop row pattern
            CustomPaint(painter: _CropRowPainter()),

            // Damage zone overlay — simulated brown patch
            Positioned(
              top: 60,
              right: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => Opacity(
                  opacity: 0.55 + _pulseAnimation.value * 0.25,
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B3B12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.alertHigh.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'DAMAGE\nZONE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Gradient overlay (bottom fade)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Field info overlay
            Positioned(
              left: 16,
              top: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${widget.hotspot.cropType.toUpperCase()} FIELD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedBuilder(
                        animation: _liveBlink,
                        builder: (context, child) => Opacity(
                          opacity: _liveBlink.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.alertHigh,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pill),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    size: 6, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'live',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.hotspot.estimatedAreaHa} ha  •  ${widget.hotspot.damageCause}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Stat overlay row (bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _HeaderStatCard(
                      icon: Icons.analytics_outlined,
                      value: widget.hotspot.ndviScore.toStringAsFixed(2),
                      label: 'NDVI (damaged)',
                    ),
                    const SizedBox(width: 10),
                    _HeaderStatCard(
                      icon: Icons.trending_down,
                      value: widget.hotspot.ndviDeltaLabel,
                      label: 'NDVI drop',
                    ),
                    const SizedBox(width: 10),
                    _HeaderStatCard(
                      icon: Icons.crop_landscape_outlined,
                      value: '${widget.hotspot.estimatedAreaHa} ha',
                      label: 'Area affected',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card showing damage cause and severity — core to verification mission
  Widget _buildDamageInfoCard() {
    final h = widget.hotspot;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Damage Assessment',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: h.severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: h.severityColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  h.severityLabel,
                  style: TextStyle(
                    color: h.severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _DamageInfoItem(
                label: 'CAUSE',
                value: h.damageCause,
                icon: Icons.warning_amber_outlined,
                color: h.severityColor,
              ),
              const SizedBox(width: 16),
              _DamageInfoItem(
                label: 'CROP',
                value: h.cropType,
                icon: Icons.grass_outlined,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DamageInfoItem(
                label: 'HOTSPOT ID',
                value: h.id,
                icon: Icons.place_outlined,
                color: AppColors.alertVerified,
                mono: true,
              ),
              const SizedBox(width: 16),
              _DamageInfoItem(
                label: 'DETECTED',
                value: h.detectedAt,
                icon: Icons.access_time,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (h.landParcel != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.landscape_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Parcel: ${h.landParcel!.parcelId}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    h.landParcel!.cropSeason,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// NDVI satellite data card — core to the satellite scout module
  Widget _buildSatelliteDataCard() {
    final h = widget.hotspot;
    // Compute "before" NDVI from delta (after + |delta| = before)
    final ndviBefore = (h.ndviScore - h.ndviDelta).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Satellite NDVI Data',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Text(
                  'Planet NICFI',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Before / After NDVI comparison
          Row(
            children: [
              Expanded(
                child: _NdviBlock(
                  label: 'BEFORE',
                  value: ndviBefore.toStringAsFixed(2),
                  color: AppColors.accent,
                  sublabel: 'Healthy',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const Icon(Icons.arrow_forward,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(height: 2),
                    Text(
                      h.ndviDeltaLabel,
                      style: const TextStyle(
                        color: AppColors.alertHigh,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _NdviBlock(
                  label: 'AFTER',
                  value: h.ndviScore.toStringAsFixed(2),
                  color: AppColors.alertHigh,
                  sublabel: 'Damaged',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // NDVI visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (h.ndviScore * 100).toInt(),
                  child: Container(
                    height: 10,
                    color: AppColors.ndviNegative,
                  ),
                ),
                Expanded(
                  flex: ((ndviBefore - h.ndviScore) * 100).toInt(),
                  child: Container(
                    height: 10,
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                Expanded(
                  flex: ((1.0 - ndviBefore) * 100).toInt(),
                  child: Container(
                    height: 10,
                    color: AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0.0  (Dead)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
              Text(
                'GPS: ${h.latitude.toStringAsFixed(4)}, ${h.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 9),
              ),
              const Text(
                '1.0  (Healthy)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompassSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'GPS Navigation',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  _distanceLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CompassWidget(
            bearing: _targetBearing +
                math.pi * _proximityFraction * 0.05,
            distanceMeters: _distanceMeters,
          ),
          const SizedBox(height: 8),
          const Text(
            'Needle points toward satellite-detected hotspot',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildProximityBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.l),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROXIMITY TO DAMAGE ZONE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${(_proximityFraction * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _proximityFraction),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isUnlocked ? AppColors.accent : AppColors.primary,
                  ),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'START (1.4 km)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
              Row(
                children: [
                  Icon(
                    _isUnlocked ? Icons.lock_open : Icons.lock_outline,
                    size: 10,
                    color: _isUnlocked
                        ? AppColors.accent
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _isUnlocked ? 'CAPTURE UNLOCKED' : 'UNLOCK AT 10 m',
                    style: TextStyle(
                      color: _isUnlocked
                          ? AppColors.accent
                          : AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _DamageInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool mono;

  const _DamageInfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NdviBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String sublabel;

  const _NdviBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Stat card for header overlay
class _HeaderStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.40),
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Crop row pattern painter for aerial view
class _CropRowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final diagPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.8;

    for (double x = -size.height; x < size.width + size.height; x += 28) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        diagPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
