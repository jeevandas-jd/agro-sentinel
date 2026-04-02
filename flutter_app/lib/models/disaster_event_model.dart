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

  // ── NEW: populated by ReportService before generating the dossier ─────────
  // All optional with safe defaults so existing code compiles unchanged.
  final double damageScore; // SatelliteService → 'damage_score'
  final double confidence; // InferenceService → 'confidence'
  final double destroyedAreaM2; // SatelliteService → 'destroyed_area_m2'
  final double affectedAreaHa; // SatelliteService → 'affected_area_ha'
  final String satelliteSummary; // SatelliteService → 'summary'
  final String? capturedImagePath; // on-device photo from CameraScreen
  // ─────────────────────────────────────────────────────────────────────────

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
    // new — all optional
    this.damageScore = 0.0,
    this.confidence = 0.0,
    this.destroyedAreaM2 = 0.0,
    this.affectedAreaHa = 0.0,
    this.satelliteSummary = '',
    this.capturedImagePath,
  });

  int get damagedHotspotsCount => hotspots
      .where((h) => (h.aiResult ?? '').toUpperCase() == 'DAMAGED')
      .length;

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
    // new
    double? damageScore,
    double? confidence,
    double? destroyedAreaM2,
    double? affectedAreaHa,
    String? satelliteSummary,
    String? capturedImagePath,
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
      damageScore: damageScore ?? this.damageScore,
      confidence: confidence ?? this.confidence,
      destroyedAreaM2: destroyedAreaM2 ?? this.destroyedAreaM2,
      affectedAreaHa: affectedAreaHa ?? this.affectedAreaHa,
      satelliteSummary: satelliteSummary ?? this.satelliteSummary,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
    );
  }

  // fromFirestore / toFirestore are UNCHANGED — new fields are runtime-only,
  // not persisted (they come from live service calls, not Firestore docs).
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
      // new fields intentionally omitted — they are never read from Firestore
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
      'hotspots': hotspots.map((h) => h.toMap()).toList(),
      'ai_narrative': aiNarrative,
      'total_trees_lost': totalTreesLost,
      'estimated_loss_inr': estimatedLossInr,
      // new runtime fields deliberately NOT written to Firestore
    };
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    return 0;
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return 0;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
