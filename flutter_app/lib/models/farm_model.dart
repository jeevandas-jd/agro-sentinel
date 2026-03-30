import 'package:cloud_firestore/cloud_firestore.dart';

import 'lat_lng.dart';

class FarmModel {
  final String id;
  final String farmerUid;
  final String name;
  final String surveyNumber;
  final String cropType;
  final double areaHectares;
  final List<LatLng> boundaries;
  final LatLng center;
  final DateTime? createdAt;

  const FarmModel({
    required this.id,
    required this.farmerUid,
    required this.name,
    required this.surveyNumber,
    required this.cropType,
    required this.areaHectares,
    required this.boundaries,
    required this.center,
    this.createdAt,
  });

  factory FarmModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final boundaryPoints = (data['boundaries'] as List<dynamic>? ?? <dynamic>[])
        .whereType<GeoPoint>()
        .map(LatLng.fromGeoPoint)
        .toList(growable: false);

    final centerPoint = data['center'] is GeoPoint
        ? LatLng.fromGeoPoint(data['center'] as GeoPoint)
        : const LatLng(latitude: 0, longitude: 0);

    return FarmModel(
      id: doc.id,
      farmerUid: (data['farmer_uid'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      surveyNumber: (data['survey_number'] as String?) ?? '',
      cropType: (data['crop_type'] as String?) ?? '',
      areaHectares: _asDouble(data['area_hectares']),
      boundaries: boundaryPoints,
      center: centerPoint,
      createdAt: _asDateTime(data['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'farmer_uid': farmerUid,
      'name': name,
      'survey_number': surveyNumber,
      'crop_type': cropType,
      'area_hectares': areaHectares,
      'boundaries': boundaries.map((point) => point.toGeoPoint()).toList(),
      'center': center.toGeoPoint(),
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
