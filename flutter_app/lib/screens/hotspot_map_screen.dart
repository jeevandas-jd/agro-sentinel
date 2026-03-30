import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../models/hotspot_model.dart';
import '../theme/app_theme.dart';
import 'camera_capture_screen.dart';
import 'dossier_review_screen.dart';

class HotspotMapScreen extends StatefulWidget {
  final FarmModel farm;
  final FarmerModel farmer;
  final DisasterEventModel initialEvent;

  const HotspotMapScreen({
    super.key,
    required this.farm,
    required this.farmer,
    required this.initialEvent,
  });

  @override
  State<HotspotMapScreen> createState() => _HotspotMapScreenState();
}

class _HotspotMapScreenState extends State<HotspotMapScreen> {
  bool _tapMode = true;
  late List<HotspotModel> _hotspots;

  @override
  void initState() {
    super.initState();
    _hotspots = List<HotspotModel>.from(widget.initialEvent.hotspots);
  }

  void _addHotspot(double lat, double lng) {
    final hotspot = HotspotModel(
      id: '${_hotspots.length + 1}',
      latitude: lat,
      longitude: lng,
      treesLost: 0,
      capturedAt: DateTime.now(),
    );
    setState(() => _hotspots = [..._hotspots, hotspot]);
  }

  void _addHotspotFromCanvasTap(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      _addHotspot(widget.farm.center.latitude, widget.farm.center.longitude);
      return;
    }
    final dx = (localPosition.dx / size.width) - 0.5;
    final dy = (localPosition.dy / size.height) - 0.5;
    final lat = widget.farm.center.latitude - (dy * 0.003);
    final lng = widget.farm.center.longitude + (dx * 0.003);
    _addHotspot(lat, lng);
  }

  Future<void> _useGps() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }
      _addHotspot(position.latitude, position.longitude);
      return;
    }

    _addHotspot(widget.farm.center.latitude, widget.farm.center.longitude);
  }

  Future<void> _openCapture(HotspotModel hotspot) async {
    final updated = await Navigator.of(context).push<HotspotModel>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(hotspot: hotspot),
      ),
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _hotspots = _hotspots
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
  }

  void _finish() {
    final ready = _hotspots.any((hotspot) => hotspot.hasAnalysedPhoto);
    if (!ready) {
      return;
    }
    final damagedCount = _hotspots
        .where((hotspot) => (hotspot.aiResult ?? '').toUpperCase() == 'DAMAGED')
        .length;
    final treesLost = _hotspots.fold<int>(0, (sum, hotspot) => sum + hotspot.treesLost);
    final event = widget.initialEvent.copyWith(
      hotspots: _hotspots,
      totalTreesLost: treesLost,
      estimatedLossInr: treesLost * 2500,
      aiNarrative:
          'AI review indicates $damagedCount damaged area(s) with visible canopy loss and broken crowns.',
      status: 'submitted',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DossierReviewScreen(
          farm: widget.farm,
          farmer: widget.farmer,
          event: event,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _hotspots
        .map(
          (hotspot) => gmaps.Marker(
            markerId: gmaps.MarkerId(hotspot.id),
            position: gmaps.LatLng(hotspot.latitude, hotspot.longitude),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueRed,
            ),
            infoWindow: gmaps.InfoWindow(title: 'Hotspot ${hotspot.id}'),
          ),
        )
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Damaged Areas')),
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapDown: (details) {
                          if (_tapMode) {
                            _addHotspotFromCanvasTap(details.localPosition, size);
                          }
                        },
                        child: Container(
                          color: const Color(0xFFE7EFE0),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_outlined, size: 64, color: AppColors.primaryDark),
                              SizedBox(height: 8),
                              Text('Web demo map canvas'),
                              SizedBox(height: 4),
                              Text('Tap to add hotspot when tap mode is on'),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : gmaps.GoogleMap(
                    initialCameraPosition: gmaps.CameraPosition(
                      target:
                          gmaps.LatLng(widget.farm.center.latitude, widget.farm.center.longitude),
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    onTap: (pos) {
                      if (_tapMode) {
                        _addHotspot(pos.latitude, pos.longitude);
                      }
                    },
                    markers: markers,
                  ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Tap on the map or visit the location to mark damage',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.22,
            maxChildSize: 0.65,
            builder: (context, controller) {
              final hasReady = _hotspots.any((hotspot) => hotspot.hasAnalysedPhoto);
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _tapMode = !_tapMode),
                            child: Text(
                              _tapMode ? 'Tap Mode: ON' : 'Tap Location on Map',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _useGps,
                            child: const Text('Use My GPS Location'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._hotspots.map((hotspot) {
                      final done = hotspot.hasAnalysedPhoto;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: done ? Colors.green : Colors.red,
                          child: Text(
                            hotspot.id,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('Hotspot ${hotspot.id}'),
                        subtitle: Text(done
                            ? 'Photo taken and AI analysed'
                            : 'Photo not taken yet'),
                        trailing: const Icon(Icons.camera_alt_outlined),
                        onTap: () => _openCapture(hotspot),
                      );
                    }),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasReady ? _finish : null,
                        child: const Text('Done — Generate Report'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
