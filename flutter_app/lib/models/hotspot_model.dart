import 'package:cloud_firestore/cloud_firestore.dart';

class HotspotModel {
  final String id;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String? aiResult;
  final double? aiConfidence;
  final String? gradcamUrl;
  final int treesLost;
  final DateTime capturedAt;

  const HotspotModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.aiResult,
    this.aiConfidence,
    this.gradcamUrl,
    required this.treesLost,
    required this.capturedAt,
  });

  HotspotModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? aiResult,
    double? aiConfidence,
    String? gradcamUrl,
    int? treesLost,
    DateTime? capturedAt,
  }) {
    return HotspotModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      aiResult: aiResult ?? this.aiResult,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      gradcamUrl: gradcamUrl ?? this.gradcamUrl,
      treesLost: treesLost ?? this.treesLost,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  bool get hasPhoto => (photoUrl ?? '').isNotEmpty;
  bool get hasAnalysedPhoto => hasPhoto && (aiResult ?? '').isNotEmpty;

  factory HotspotModel.fromMap(Map<String, dynamic> map) {
    return HotspotModel(
      id: (map['id'] as String?) ?? '',
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      photoUrl: map['photo_url'] as String?,
      aiResult: map['ai_result'] as String?,
      aiConfidence: map['ai_confidence'] is num
          ? (map['ai_confidence'] as num).toDouble()
          : null,
      gradcamUrl: map['gradcam_url'] as String?,
      treesLost: _asInt(map['trees_lost']),
      capturedAt: _asDateTime(map['captured_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'ai_result': aiResult,
      'ai_confidence': aiConfidence,
      'gradcam_url': gradcamUrl,
      'trees_lost': treesLost,
      'captured_at': Timestamp.fromDate(capturedAt),
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
