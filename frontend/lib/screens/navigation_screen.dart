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
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;

  // Bearing toward target (NE direction for demo)
  static const double _targetBearing = 0.78; // ~45 degrees in radians

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
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

  String get _proximityStatus {
    if (_distanceMeters <= 10) return 'TARGET REACHED';
    if (_distanceMeters <= 50) return 'APPROACHING ZONE';
    if (_distanceMeters <= 200) return 'CLOSING IN';
    return 'NAVIGATING TO HOTSPOT';
  }

  Color get _proximityColor {
    if (_distanceMeters <= 10) return AppColors.accent;
    if (_distanceMeters <= 50) return AppColors.alertMedium;
    if (_distanceMeters <= 200) return AppColors.alertMedium;
    return AppColors.textSecondary;
  }

  double get _proximityFraction =>
      (1.0 - (_distanceMeters / 1400.0)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Truth Walk'),
            Text(
              widget.hotspot.id,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.hotspot.severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.hotspot.severityColor.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              widget.hotspot.severityLabel,
              style: TextStyle(
                color: widget.hotspot.severityColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Target info card
              _buildTargetCard(),
              const SizedBox(height: 20),

              // Compass + distance
              _buildCompassSection(),
              const SizedBox(height: 20),

              // GPS coordinates
              _buildCoordinatesCard(),
              const SizedBox(height: 20),

              // Proximity progress bar
              _buildProximityBar(),
              const SizedBox(height: 24),

              // Demo simulate button
              if (!_isUnlocked)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSimulating ? null : _simulateApproach,
                    icon: _isSimulating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : const Icon(Icons.directions_walk, size: 16),
                    label: Text(
                      _isSimulating ? 'Walking to hotspot...' : 'Simulate Approach  (Demo)',
                    ),
                  ),
                ),
              if (!_isUnlocked) const SizedBox(height: 12),

              // Capture Evidence button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUnlocked
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CameraScreen(hotspot: widget.hotspot),
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    _isUnlocked ? Icons.camera_alt : Icons.lock_outline,
                    size: 18,
                  ),
                  label: Text(
                    _isUnlocked
                        ? 'Capture Evidence'
                        : 'Get within 10 m to unlock',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUnlocked
                        ? AppColors.accent
                        : AppColors.card,
                    foregroundColor: _isUnlocked
                        ? Colors.white
                        : AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: _isUnlocked
                        ? null
                        : const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.hotspot.severityColor.withValues(alpha: 
                    0.15 * _pulseAnimation.value,
                  ),
                  border: Border.all(
                    color: widget.hotspot.severityColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.my_location,
                  color: widget.hotspot.severityColor,
                  size: 18,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target: ${widget.hotspot.cropType} Field',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.hotspot.damageCause,
                  style: TextStyle(
                    color: widget.hotspot.severityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.hotspot.estimatedAreaHa} ha',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Text(
                'Affected area',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompassSection() {
    return Column(
      children: [
        // Distance
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Text(
              _distanceLabel,
              style: TextStyle(
                color: _proximityColor,
                fontSize: 54,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _proximityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _proximityColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            _proximityStatus,
            style: TextStyle(
              color: _proximityColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        CompassWidget(
          bearing: _targetBearing + math.pi * _proximityFraction * 0.05,
          distanceMeters: _distanceMeters,
        ),
        const SizedBox(height: 8),
        const Text(
          'Needle points toward target hotspot',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCoordinatesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              const Text(
                'GPS COORDINATES',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CoordBlock(
                label: 'YOUR POSITION',
                lat: '10.7835',
                lng: '76.6502',
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              const SizedBox(width: 12),
              _CoordBlock(
                label: 'TARGET',
                lat: widget.hotspot.latitude.toStringAsFixed(4),
                lng: widget.hotspot.longitude.toStringAsFixed(4),
                color: widget.hotspot.severityColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProximityBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PROXIMITY TO ZONE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${(_proximityFraction * 100).toInt()}%',
              style: TextStyle(
                color: _proximityColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                valueColor: AlwaysStoppedAnimation<Color>(_proximityColor),
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
                Icon(Icons.lock_open, size: 10, color: AppColors.accent),
                const SizedBox(width: 3),
                const Text(
                  'UNLOCK AT 10 m',
                  style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CoordBlock extends StatelessWidget {
  final String label;
  final String lat;
  final String lng;
  final Color? color;

  const _CoordBlock({
    required this.label,
    required this.lat,
    required this.lng,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.textSecondary;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lat,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            lng,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
