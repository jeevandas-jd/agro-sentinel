import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../core/utils/map_marker_utils.dart';
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
  late List<HotspotModel> _hotspots;
  gmaps.BitmapDescriptor? _hotspotIcon;
  gmaps.BitmapDescriptor? _visitedHotspotIcon;

  @override
  void initState() {
    super.initState();
    _hotspots = List<HotspotModel>.from(widget.initialEvent.hotspots);
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    final hotspotIcon = await bitmapDescriptorFromIcon(
      Icons.place,
      AppColors.hotspotMarkerColor,
      size: 72,
    );
    final visitedIcon = await bitmapDescriptorFromIcon(
      Icons.place,
      AppColors.visitedHotspotColor,
      size: 72,
    );
    if (!mounted) return;
    setState(() {
      _hotspotIcon = hotspotIcon;
      _visitedHotspotIcon = visitedIcon;
    });
  }

  HotspotModel _addHotspot(double lat, double lng) {
    final hotspot = HotspotModel(
      id: '${_hotspots.length + 1}',
      latitude: lat,
      longitude: lng,
      treesLost: 0,
      capturedAt: DateTime.now(),
    );
    setState(() => _hotspots = [..._hotspots, hotspot]);
    return hotspot;
  }

  Future<void> _confirmAndAddHotspot(gmaps.LatLng pos) async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark this as damaged area?'),
          content: Text(
            'Lat: ${pos.latitude.toStringAsFixed(6)}\nLng: ${pos.longitude.toStringAsFixed(6)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldAdd != true) return;
    final hotspot = _addHotspot(pos.latitude, pos.longitude);
    await _openCapture(hotspot);
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
      final hotspot = _addHotspot(position.latitude, position.longitude);
      await _openCapture(hotspot);
      return;
    }

    final hotspot = _addHotspot(widget.farm.center.latitude, widget.farm.center.longitude);
    await _openCapture(hotspot);
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
            icon: hotspot.hasAnalysedPhoto
                ? (_visitedHotspotIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueGreen,
                  ))
                : (_hotspotIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueRed,
                  )),
            infoWindow: gmaps.InfoWindow(title: 'Hotspot ${hotspot.id}'),
          ),
        )
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Damaged Areas')),
      body: Stack(
        children: [
          Positioned.fill(
            child: gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: gmaps.LatLng(widget.farm.center.latitude, widget.farm.center.longitude),
                zoom: 16,
              ),
              myLocationEnabled: true,
              onLongPress: _confirmAndAddHotspot,
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
                            onPressed: _hotspots.isEmpty ? null : () => setState(() => _hotspots = []),
                            child: const Text('Clear Hotspots'),
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
