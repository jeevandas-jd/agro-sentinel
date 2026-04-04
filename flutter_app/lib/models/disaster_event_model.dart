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
  /// Short 2-3 sentence executive summary shown on the Damage Report Preview screen.
  /// Stored as [ai_narrative_short] in Firestore. Populated from the same Gemini call
  /// that produces [aiNarrative].
  final String? aiNarrativeShort;
  final int totalTreesLost;

  /// Age of the crop in years at the time the disaster was reported.
  /// Stored as [crop_age_years] in Firestore. Null when not provided.
  final int? cropAgeYears;

  /// Whether the crop was in a bearing (fruit/yield-producing) stage at the time
  /// of the incident. Stored as [is_bearing] in Firestore. Null when not provided.
  final bool? isBearing;
  final double estimatedLossInr;

  // ── Satellite / camera metrics (persisted for PDF redownload) ─────────────
  final double damageScore; // SatelliteService → 'damage_score'
  final double confidence; // InferenceService → 'confidence'
  final double destroyedAreaM2; // SatelliteService → 'destroyed_area_m2'
  final double affectedAreaHa; // SatelliteService → 'affected_area_ha'
  final String satelliteSummary; // SatelliteService → 'summary'
  /// Durable on-device path (app documents) after media files are copied before save.
  final String? capturedImagePath;

  /// Groq vision (satellite before/after); persisted for PDF redownload.
  final bool satelliteGroqOk;
  final String satelliteGroqError;
  final double satelliteGroqConfidence; // 0–1 from Groq JSON, not TFLite
  final String satelliteGroqDetailsJson; // pretty JSON of groq_response for Gemini
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
    this.aiNarrativeShort,
    required this.totalTreesLost,
    required this.estimatedLossInr,
    this.cropAgeYears,
    this.isBearing,
    // new — all optional
    this.damageScore = 0.0,
    this.confidence = 0.0,
    this.destroyedAreaM2 = 0.0,
    this.affectedAreaHa = 0.0,
    this.satelliteSummary = '',
    this.capturedImagePath,
    this.satelliteGroqOk = false,
    this.satelliteGroqError = '',
    this.satelliteGroqConfidence = 0.0,
    this.satelliteGroqDetailsJson = '',
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
    String? aiNarrativeShort,
    int? totalTreesLost,
    double? estimatedLossInr,
    int? cropAgeYears,
    bool? isBearing,
    // new runtime fields
    double? damageScore,
    double? confidence,
    double? destroyedAreaM2,
    double? affectedAreaHa,
    String? satelliteSummary,
    String? capturedImagePath,
    bool? satelliteGroqOk,
    String? satelliteGroqError,
    double? satelliteGroqConfidence,
    String? satelliteGroqDetailsJson,
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
      aiNarrativeShort: aiNarrativeShort ?? this.aiNarrativeShort,
      totalTreesLost: totalTreesLost ?? this.totalTreesLost,
      estimatedLossInr: estimatedLossInr ?? this.estimatedLossInr,
      cropAgeYears: cropAgeYears ?? this.cropAgeYears,
      isBearing: isBearing ?? this.isBearing,
      damageScore: damageScore ?? this.damageScore,
      confidence: confidence ?? this.confidence,
      destroyedAreaM2: destroyedAreaM2 ?? this.destroyedAreaM2,
      affectedAreaHa: affectedAreaHa ?? this.affectedAreaHa,
      satelliteSummary: satelliteSummary ?? this.satelliteSummary,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      satelliteGroqOk: satelliteGroqOk ?? this.satelliteGroqOk,
      satelliteGroqError: satelliteGroqError ?? this.satelliteGroqError,
      satelliteGroqConfidence:
          satelliteGroqConfidence ?? this.satelliteGroqConfidence,
      satelliteGroqDetailsJson:
          satelliteGroqDetailsJson ?? this.satelliteGroqDetailsJson,
    );
  }

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
      aiNarrativeShort: data['ai_narrative_short'] as String?,
      totalTreesLost: _asInt(data['total_trees_lost']),
      estimatedLossInr: _asDouble(data['estimated_loss_inr']),
      cropAgeYears: data['crop_age_years'] as int?,
      isBearing: data['is_bearing'] as bool?,
      damageScore: _asDouble(data['damage_score']),
      confidence: _asDouble(data['confidence']),
      destroyedAreaM2: _asDouble(data['destroyed_area_m2']),
      affectedAreaHa: _asDouble(data['affected_area_ha']),
      satelliteSummary: (data['satellite_summary'] as String?) ?? '',
      capturedImagePath: data['captured_image_path'] as String?,
      satelliteGroqOk: data['satellite_groq_ok'] as bool? ?? false,
      satelliteGroqError: (data['satellite_groq_error'] as String?) ?? '',
      satelliteGroqConfidence: _asDouble(data['satellite_groq_confidence']),
      satelliteGroqDetailsJson:
          (data['satellite_groq_details_json'] as String?) ?? '',
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
      'ai_narrative_short': aiNarrativeShort,
      'total_trees_lost': totalTreesLost,
      'estimated_loss_inr': estimatedLossInr,
      if (cropAgeYears != null) 'crop_age_years': cropAgeYears,
      if (isBearing != null) 'is_bearing': isBearing,
      'damage_score': damageScore,
      'confidence': confidence,
      'destroyed_area_m2': destroyedAreaM2,
      'affected_area_ha': affectedAreaHa,
      'satellite_summary': satelliteSummary,
      'satellite_groq_ok': satelliteGroqOk,
      'satellite_groq_error': satelliteGroqError,
      'satellite_groq_confidence': satelliteGroqConfidence,
      'satellite_groq_details_json': satelliteGroqDetailsJson,
      if ((capturedImagePath ?? '').isNotEmpty)
        'captured_image_path': capturedImagePath,
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
