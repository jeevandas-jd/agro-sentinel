import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';

typedef NarrativeModelCaller = Future<String> Function(String prompt);

class AINarrativeService {
  AINarrativeService({
    FirebaseFirestore? firestore,
    NarrativeModelCaller? caller,
    String farmsCollection = 'farms',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _caller = caller,
        _farmsCollection = farmsCollection;

  final FirebaseFirestore _firestore;
  final NarrativeModelCaller? _caller;
  final String _farmsCollection;

  /// Calls watsonx.ai or Gemini with structured damage data.
  /// Returns a paragraph of professional insurance language.
  ///
  /// Fallback behavior:
  /// - If any data lookup fails OR the API call fails, returns a safe, pre-written
  ///   template string. Never surfaces raw errors to the farmer.
  Future<String> generateNarrative(DisasterEventModel event) async {
    try {
      final farm = await _tryLoadFarm(event.farmId);
      final prompt = _buildPrompt(event: event, farm: farm);

      final caller = _caller;
      if (caller == null) {
        return _fallbackNarrative(event: event, farm: farm);
      }

      final response = (await caller(prompt)).trim();
      if (response.isEmpty) {
        return _fallbackNarrative(event: event, farm: farm);
      }
      return response;
    } catch (_) {
      return _fallbackNarrative(event: event, farm: null);
    }
  }

  Future<FarmModel?> _tryLoadFarm(String farmId) async {
    if (farmId.trim().isEmpty) return null;
    try {
      final doc = await _firestore.collection(_farmsCollection).doc(farmId).get();
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
    final cropType = (farm?.cropType ?? 'Unknown').trim().isEmpty
        ? 'Unknown'
        : farm!.cropType.trim();
    final surveyNumber = (farm?.surveyNumber ?? 'Unknown').trim().isEmpty
        ? 'Unknown'
        : farm!.surveyNumber.trim();
    final area = (farm?.areaHectares ?? 0).toStringAsFixed(2);

    final damagedCount = event.damagedHotspotsCount;
    final totalCount = event.hotspots.length;
    final treesLost = event.totalTreesLost;
    final date = _formatDate(event.occurredAt);

    return '''
You are an agricultural damage assessment officer. Based on the following 
field data, write a professional 2-3 sentence damage assessment paragraph 
suitable for an insurance claim report.

Farm: $cropType plantation, Survey No. $surveyNumber, $area hectares
Disaster type: ${event.disasterType}
Date of incident: $date
Farmer's account: ${event.farmerDescription}
AI damage assessment: $damagedCount of $totalCount locations showed 
significant damage
Estimated trees lost: $treesLost

Write in formal English. Be factual and precise. Do not add information 
not provided above.
''';
  }

  String _fallbackNarrative({
    required DisasterEventModel event,
    required FarmModel? farm,
  }) {
    final cropType = (farm?.cropType ?? 'the').trim().isEmpty ? 'the' : farm!.cropType.trim();
    final surveyNumber = (farm?.surveyNumber ?? 'N/A').trim().isEmpty ? 'N/A' : farm!.surveyNumber;
    final area = (farm?.areaHectares ?? 0).toStringAsFixed(2);

    final damagedCount = event.damagedHotspotsCount;
    final totalCount = event.hotspots.length;
    final date = _formatDate(event.occurredAt);

    return 'Based on field observations and available records, a damage survey '
        'was conducted for the $cropType plantation (Survey No. $surveyNumber, $area ha) '
        'for the reported ${event.disasterType} incident dated $date. '
        'The farmer reported: "${event.farmerDescription}". '
        'AI-assisted review indicates $damagedCount of $totalCount surveyed locations '
        'showed significant damage, with an estimated tree loss of ${event.totalTreesLost}.';
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

