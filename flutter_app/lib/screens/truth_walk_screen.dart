import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../core/utils/map_marker_utils.dart';
import '../models/hotspot_model.dart';
import '../theme/app_theme.dart';
import 'camera_capture_screen.dart';

class TruthWalkScreen extends StatefulWidget {
  final HotspotModel hotspot;

  const TruthWalkScreen({super.key, required this.hotspot});

  @override
  State<TruthWalkScreen> createState() => _TruthWalkScreenState();
}

class _TruthWalkScreenState extends State<TruthWalkScreen>
    with SingleTickerProviderStateMixin {
  static const double _proximityThresholdMetres = 15.0;

  StreamSubscription<Position>? _positionSub;
  double? _distanceMetres;
  bool _permissionDenied = false;

  gmaps.BitmapDescriptor? _hotspotIcon;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadMarkerIcon();
    _startLocationStream();
  }

  Future<void> _loadMarkerIcon() async {
    final icon = await bitmapDescriptorFromIcon(
      Icons.place,
      AppColors.hotspotMarkerColor,
      size: 72,
    );
    if (!mounted) return;
    setState(() => _hotspotIcon = icon);
  }

  Future<void> _startLocationStream() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      if (!mounted) return;
      setState(() => _permissionDenied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission required for truth walk. Please enable it in settings.',
          ),
        ),
      );
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      if (!mounted) return;
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.hotspot.latitude,
        widget.hotspot.longitude,
      );
      setState(() => _distanceMetres = dist);
    });
  }

  bool get _withinRange =>
      _distanceMetres != null && _distanceMetres! <= _proximityThresholdMetres;

  Future<void> _openCamera() async {
    final updated = await Navigator.of(context).push<HotspotModel>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(hotspot: widget.hotspot),
      ),
    );
    if (!mounted || updated == null) return;
    Navigator.of(context).pop(updated);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotspotLatLng = gmaps.LatLng(
      widget.hotspot.latitude,
      widget.hotspot.longitude,
    );

    final markers = <gmaps.Marker>{
      gmaps.Marker(
        markerId: const gmaps.MarkerId('hotspot-target'),
        position: hotspotLatLng,
        icon: _hotspotIcon ??
            gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueRed,
            ),
        infoWindow: gmaps.InfoWindow(
          title: 'Hotspot ${widget.hotspot.id}',
          snippet: 'Walk here to take photo',
        ),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk to Hotspot'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: hotspotLatLng,
                zoom: 18,
              ),
              mapType: gmaps.MapType.satellite,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: markers,
            ),
          ),
          // Top instruction banner
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _InstructionBanner(withinRange: _withinRange),
          ),
          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomPanel(
              distanceMetres: _distanceMetres,
              permissionDenied: _permissionDenied,
              withinRange: _withinRange,
              pulseAnimation: _pulseAnimation,
              onTakePhoto: _openCamera,
              hotspot: widget.hotspot,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  final bool withinRange;

  const _InstructionBanner({required this.withinRange});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Card(
        key: ValueKey(withinRange),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                withinRange
                    ? Icons.check_circle_outline
                    : Icons.directions_walk,
                size: 18,
                color: withinRange ? AppColors.primary : AppColors.alertMedium,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  withinRange
                      ? 'You are at the hotspot — camera is unlocked'
                      : 'Walk closer to the red marker to unlock the camera',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final double? distanceMetres;
  final bool permissionDenied;
  final bool withinRange;
  final Animation<double> pulseAnimation;
  final VoidCallback onTakePhoto;
  final HotspotModel hotspot;

  const _BottomPanel({
    required this.distanceMetres,
    required this.permissionDenied,
    required this.withinRange,
    required this.pulseAnimation,
    required this.onTakePhoto,
    required this.hotspot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.raised,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Proximity ring + distance
          _ProximityRing(
            distanceMetres: distanceMetres,
            withinRange: withinRange,
            pulseAnimation: pulseAnimation,
          ),
          const SizedBox(height: 20),
          // Hotspot coordinate label
          Text(
            'Hotspot ${hotspot.id}  •  '
            '${hotspot.latitude.toStringAsFixed(5)}°N  '
            '${hotspot.longitude.toStringAsFixed(5)}°E',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Take photo button
          SizedBox(
            width: double.infinity,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: withinRange
                  ? ElevatedButton.icon(
                      key: const ValueKey('enabled'),
                      onPressed: onTakePhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take Photo'),
                    )
                  : ElevatedButton.icon(
                      key: const ValueKey('disabled'),
                      onPressed: null,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(
                        permissionDenied
                            ? 'Location permission required'
                            : distanceMetres == null
                                ? 'Getting your location…'
                                : 'Camera locked — walk closer',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProximityRing extends StatelessWidget {
  final double? distanceMetres;
  final bool withinRange;
  final Animation<double> pulseAnimation;

  const _ProximityRing({
    required this.distanceMetres,
    required this.withinRange,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    const double ringSize = 148;
    const double threshold = 15.0;

    final dist = distanceMetres;

    // progress: 1.0 when within range, approaches 0 as far away
    final double progress;
    if (dist == null) {
      progress = 0.0;
    } else if (dist <= threshold) {
      progress = 1.0;
    } else {
      // Cap display at 200 m so the ring gives useful feedback near the hotspot
      progress = (1.0 - ((dist - threshold) / 200.0)).clamp(0.0, 1.0);
    }

    final ringColor = withinRange ? AppColors.primary : AppColors.alertMedium;

    Widget ring = SizedBox(
      width: ringSize,
      height: ringSize,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: ringColor,
          trackColor: AppColors.border,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: dist == null
                    ? const SizedBox(
                        key: ValueKey('spinner'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : withinRange
                        ? Icon(
                            key: const ValueKey('check'),
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 36,
                          )
                        : Text(
                            key: const ValueKey('dist'),
                            dist >= 1000
                                ? '${(dist / 1000).toStringAsFixed(1)} km'
                                : '${dist.round()} m',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
              ),
              const SizedBox(height: 2),
              Text(
                withinRange ? 'You\'re here!' : 'away',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );

    // Pulse the ring when within range
    if (withinRange) {
      ring = AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: pulseAnimation.value,
          child: child,
        ),
        child: ring,
      );
    }

    return ring;
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 9.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
