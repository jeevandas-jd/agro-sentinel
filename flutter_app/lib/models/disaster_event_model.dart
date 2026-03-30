import 'package:cloud_firestore/cloud_firestore.dart';

import 'hotspot_model.dart';

class DisasterEventModel {
  final String id;
  final String farmerUid;
  final String farmId;
  final String disasterType;
  final String farmerDescription;
  final DateTime occurredAt;
  final DateTime reportedAt;
  final String status;
  final List<HotspotModel> hotspots;
  final String? aiNarrative;
  final int totalTreesLost;
  final double estimatedLossInr;

  const DisasterEventModel({
    required this.id,
    required this.farmerUid,
    required this.farmId,
    required this.disasterType,
    required this.farmerDescription,
    required this.occurredAt,
    required this.reportedAt,
    required this.status,
    required this.hotspots,
    this.aiNarrative,
    required this.totalTreesLost,
    required this.estimatedLossInr,
  });

  DisasterEventModel copyWith({
    String? id,
    String? farmerUid,
    String? farmId,
    String? disasterType,
    String? farmerDescription,
    DateTime? occurredAt,
    DateTime? reportedAt,
    String? status,
    List<HotspotModel>? hotspots,
    String? aiNarrative,
    int? totalTreesLost,
    double? estimatedLossInr,
  }) {
    return DisasterEventModel(
      id: id ?? this.id,
      farmerUid: farmerUid ?? this.farmerUid,
      farmId: farmId ?? this.farmId,
      disasterType: disasterType ?? this.disasterType,
      farmerDescription: farmerDescription ?? this.farmerDescription,
      occurredAt: occurredAt ?? this.occurredAt,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      hotspots: hotspots ?? this.hotspots,
      aiNarrative: aiNarrative ?? this.aiNarrative,
      totalTreesLost: totalTreesLost ?? this.totalTreesLost,
      estimatedLossInr: estimatedLossInr ?? this.estimatedLossInr,
    );
  }

  int get damagedHotspotsCount =>
      hotspots.where((hotspot) => (hotspot.aiResult ?? '').toUpperCase() == 'DAMAGED').length;

  factory DisasterEventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final hotspotList = (data['hotspots'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => HotspotModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    final now = DateTime.now();

    return DisasterEventModel(
      id: doc.id,
      farmerUid: (data['farmer_uid'] as String?) ?? '',
      farmId: (data['farm_id'] as String?) ?? '',
      disasterType: (data['disaster_type'] as String?) ?? '',
      farmerDescription: (data['farmer_description'] as String?) ?? '',
      occurredAt: _asDateTime(data['occurred_at']) ?? now,
      reportedAt: _asDateTime(data['reported_at']) ?? now,
      status: (data['status'] as String?) ?? 'draft',
      hotspots: hotspotList,
      aiNarrative: data['ai_narrative'] as String?,
      totalTreesLost: _asInt(data['total_trees_lost']),
      estimatedLossInr: _asDouble(data['estimated_loss_inr']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'farmer_uid': farmerUid,
      'farm_id': farmId,
      'disaster_type': disasterType,
      'farmer_description': farmerDescription,
      'occurred_at': Timestamp.fromDate(occurredAt),
      'reported_at': Timestamp.fromDate(reportedAt),
      'status': status,
      'hotspots': hotspots.map((hotspot) => hotspot.toMap()).toList(),
      'ai_narrative': aiNarrative,
      'total_trees_lost': totalTreesLost,
      'estimated_loss_inr': estimatedLossInr,
    };
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return 0;
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
