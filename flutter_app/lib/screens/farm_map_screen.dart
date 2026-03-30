import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../models/hotspot_model.dart';
import '../theme/app_theme.dart';
import 'new_disaster_screen.dart';

class FarmMapScreen extends StatelessWidget {
  final FarmModel farm;
  final FarmerModel farmer;
  final DisasterEventModel? event;

  const FarmMapScreen({
    super.key,
    required this.farm,
    required this.farmer,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final hotspotCount = event?.hotspots.length ?? 0;
    final polygon = gmaps.Polygon(
      polygonId: const gmaps.PolygonId('farm-boundary'),
      points: farm.boundaries
          .map((point) => gmaps.LatLng(point.latitude, point.longitude))
          .toList(),
      strokeColor: Colors.green,
      fillColor: Colors.green.withValues(alpha: 0.2),
      strokeWidth: 2,
    );

    final markers = (event?.hotspots ?? <HotspotModel>[])
        .map<gmaps.Marker>(
          (hotspot) => gmaps.Marker(
            markerId: gmaps.MarkerId(hotspot.id),
            position: gmaps.LatLng(hotspot.latitude, hotspot.longitude),
            icon: hotspot.hasAnalysedPhoto
                ? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueGreen,
                  )
                : gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueOrange,
                  ),
          ),
        )
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Farm Map')),
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb
                ? Container(
                    color: const Color(0xFFE7EFE0),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map, size: 64, color: AppColors.primaryDark),
                        const SizedBox(height: 8),
                        Text(
                          'Map preview unavailable on web demo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Farm boundary points: ${farm.boundaries.length} • Hotspots: $hotspotCount',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : gmaps.GoogleMap(
                    initialCameraPosition: gmaps.CameraPosition(
                      target: gmaps.LatLng(farm.center.latitude, farm.center.longitude),
                      zoom: 16,
                    ),
                    polygons: {polygon},
                    markers: markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  farm.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.22,
            minChildSize: 0.16,
            maxChildSize: 0.44,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Crop Type: ${farm.cropType}'),
                    const SizedBox(height: 6),
                    Text('Area: ${farm.areaHectares.toStringAsFixed(1)} ha'),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NewDisasterScreen(
                              farmer: farmer,
                              farm: farm,
                            ),
                          ),
                        );
                      },
                      child: const Text('Start New Disaster Report'),
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
