import 'package:cloud_firestore/cloud_firestore.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({
    required this.latitude,
    required this.longitude,
  });

  factory LatLng.fromGeoPoint(GeoPoint point) {
    return LatLng(
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }

  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }
}
