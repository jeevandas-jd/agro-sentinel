import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';

typedef NarrativeModelCaller = Future<String> Function(String prompt);

class AINarrativeService {
  AINarrativeService({
    FirebaseFirestore? firestore,
    NarrativeModelCaller? caller,
    String farmsCollection = 'farms',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _caller = caller,
       _farmsCollection = farmsCollection;

  final FirebaseFirestore _firestore;
  final NarrativeModelCaller? _caller;
  final String _farmsCollection;

  Future<String> generateNarrative(DisasterEventModel event) async {
    try {
      final farm = await _tryLoadFarm(event.farmId);
      final prompt = _buildPrompt(event: event, farm: farm);
      final caller = _caller;
      if (caller == null) return _fallbackNarrative(event: event, farm: farm);
      final response = (await caller(prompt)).trim();
      return response.isEmpty
          ? _fallbackNarrative(event: event, farm: farm)
          : response;
    } catch (_) {
      return _fallbackNarrative(event: event, farm: null);
    }
  }

  Future<FarmModel?> _tryLoadFarm(String farmId) async {
    if (farmId.trim().isEmpty) return null;
    try {
      final doc = await _firestore
          .collection(_farmsCollection)
          .doc(farmId)
          .get();
      if (!doc.exists) return null;
      return FarmModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  String _buildPrompt({
    required DisasterEventModel event,
    required FarmModel? farm,
  }) {
    final crop = _s(farm?.cropType, 'Unknown');
    final survey = _s(farm?.surveyNumber, 'Unknown');
    final area = (farm?.areaHectares ?? 0).toStringAsFixed(2);

    return '''
You are a certified agricultural insurance officer writing a formal damage
assessment paragraph for an insurance claim dossier.

── Farm ──────────────────────────────────────────────
Crop        : $crop plantation
Survey No.  : $survey
Area        : $area ha

── Incident ──────────────────────────────────────────
Type        : ${event.disasterType}
Date        : ${_date(event.occurredAt)}
Farmer note : ${event.farmerDescription}

── Camera AI (TFLite on-device) ──────────────────────
Locations surveyed  : ${event.hotspots.length}
Locations damaged   : ${event.damagedHotspotsCount}
Model confidence    : ${(event.confidence * 100).toStringAsFixed(1)}%

── Satellite analysis ────────────────────────────────
Damage score        : ${event.damageScore.toStringAsFixed(1)} / 100
Affected area       : ${event.affectedAreaHa.toStringAsFixed(2)} ha
Destroyed canopy    : ${event.destroyedAreaM2.toStringAsFixed(0)} m²
Trees lost          : ${event.totalTreesLost}
Summary             : ${event.satelliteSummary}

── Instructions ──────────────────────────────────────
Write 3–4 sentences in formal insurance English.
Be factual. Mention crop type, area, damage score,
trees lost, and incident date. Do not invent data.
''';
  }

  String _fallbackNarrative({
    required DisasterEventModel event,
    required FarmModel? farm,
  }) {
    final crop = _s(farm?.cropType, 'the');
    final survey = _s(farm?.surveyNumber, 'N/A');
    final area = (farm?.areaHectares ?? 0).toStringAsFixed(2);

    return 'A damage assessment was conducted for the $crop plantation '
        '(Survey No. $survey, $area ha) following the '
        '${event.disasterType} incident on ${_date(event.occurredAt)}. '
        'Farmer testimony: "${event.farmerDescription}". '
        'On-field camera AI recorded ${(event.confidence * 100).toStringAsFixed(1)}% '
        'confidence of damage across ${event.damagedHotspotsCount} of '
        '${event.hotspots.length} surveyed locations. '
        'Satellite analysis returned a damage score of '
        '${event.damageScore.toStringAsFixed(1)}/100, with '
        '${event.affectedAreaHa.toStringAsFixed(2)} ha affected, '
        '${event.destroyedAreaM2.toStringAsFixed(0)} m² of canopy destroyed, '
        'and an estimated ${event.totalTreesLost} trees lost.';
  }

  String _s(String? v, String fallback) =>
      (v == null || v.trim().isEmpty) ? fallback : v.trim();

  String _date(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
