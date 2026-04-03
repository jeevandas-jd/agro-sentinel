import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/dart_define_config.dart';
import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/hotspot_model.dart';
import 'gemini_narrative_client.dart';

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
    final tf = _tfliteRollup(event.hotspots);
    final pipelineConf = event.confidence > 0
        ? '${(event.confidence * 100).toStringAsFixed(1)}% (from merged pipeline when available)'
        : 'not set (use per-hotspot TFLite rows below instead)';

    final groqJson = event.satelliteGroqDetailsJson.trim();
    final groqErr = event.satelliteGroqError.trim();
    final groqConfLine = event.satelliteGroqConfidence > 0
        ? '${(event.satelliteGroqConfidence * 100).toStringAsFixed(1)}% '
            '(Groq vision model self-assessment; separate from TFLite above)'
        : 'n/a';

    return '''
You are a certified agricultural insurance officer writing a formal damage
assessment paragraph for an insurance claim dossier.

── Farm ──────────────────────────────────────────────
Farm name   : ${_s(farm?.name, 'N/A')}
Crop        : $crop plantation
Survey No.  : $survey
Area        : $area ha

── Incident ──────────────────────────────────────────
Type        : ${event.disasterType}
Occurred    : ${_date(event.occurredAt)}
Reported    : ${_date(event.reportedAt)}
Status      : ${event.status}
Farmer note : ${event.farmerDescription}

── On-device damage model (TFLite, binary damaged vs healthy) ─
Model asset : bundled classifier on captured field photos (resize + ImageNet norm).
Hotspots total      : ${tf.total}
Photos analysed     : ${tf.analysed}
Pending / no result : ${tf.pending}
Class DAMAGED       : ${tf.damagedCount}
Class HEALTHY       : ${tf.healthyCount}
Mean confidence (damaged hotspots only)   : ${tf.meanConfDamaged}
Mean confidence (healthy hotspots only)     : ${tf.meanConfHealthy}
Mean confidence (all analysed hotspots)     : ${tf.meanConfAll}
Trees lost (sum of hotspot estimates)       : ${tf.treesSumFromHotspots}
Event total_trees_lost field (authoritative if set): ${event.totalTreesLost}
Estimated loss (INR, from event)              : ${event.estimatedLossInr.toStringAsFixed(0)}
Merged pipeline confidence (optional)         : $pipelineConf

Per hotspot (use these rows; do not invent extra locations):
${tf.perHotspotLines}

── Groq cloud vision (satellite before/after tiles, separate API from TFLite) ─
Call succeeded              : ${event.satelliteGroqOk ? 'yes' : 'no'}
${groqErr.isNotEmpty ? 'Groq / satellite API error     : $groqErr\n' : ''}Groq model confidence         : $groqConfLine

Parsed JSON returned by Groq (authoritative for remote sensing when call succeeded;
if call failed, treat numbers below as placeholders — do not present them as verified):
${groqJson.isEmpty ? '(none — satellite/Groq step not run, failed, or returned no payload)' : groqJson}

── Satellite roll-up (aligned with Groq JSON when call succeeded) ─
Damage score        : ${event.damageScore.toStringAsFixed(1)} / 100
Affected area       : ${event.affectedAreaHa.toStringAsFixed(2)} ha
Destroyed canopy    : ${event.destroyedAreaM2.toStringAsFixed(0)} m²
Narrative summary   : ${event.satelliteSummary.isEmpty ? '(none)' : event.satelliteSummary}
On-device photo path (debug) : ${event.capturedImagePath ?? '(none)'}

── Instructions ──────────────────────────────────────
Write 3–5 sentences in formal insurance English.
Integrate BOTH: (1) TFLite per-hotspot field photos and (2) Groq satellite comparison
when the Groq call succeeded. Mention Groq-reported damage score, areas, summary, and
its self-confidence where relevant. If Groq did not succeed, briefly note that remote
sensing was unavailable or failed${groqErr.isNotEmpty ? ' (see error above)' : ''} and rely on TFLite and the farmer statement.
Do not treat Groq numeric fields as verified facts when "Call succeeded" is no.
Prioritise TFLite for ground-truth at each hotspot; use Groq to describe wider canopy
loss context when available. Mention how many locations were analysed and how many
classified as damaged. Include crop, survey/area where relevant, incident date, and
estimated loss or tree counts from the data above. Do not invent numbers not listed.
''';
  }

  String _fallbackNarrative({
    required DisasterEventModel event,
    required FarmModel? farm,
  }) {
    final crop = _s(farm?.cropType, 'the');
    final survey = _s(farm?.surveyNumber, 'N/A');
    final area = (farm?.areaHectares ?? 0).toStringAsFixed(2);
    final tf = _tfliteRollup(event.hotspots);
    final camLine = tf.analysed > 0
        ? 'On-device TFLite analysis covered ${tf.analysed} photo(s) at '
            '${event.hotspots.length} hotspot(s): ${tf.damagedCount} classified DAMAGED, '
            '${tf.healthyCount} HEALTHY, pending ${tf.pending}. '
            'Mean model confidence on damaged plots was ${tf.meanConfDamaged}; '
            'tree loss estimated from hotspots totals ${tf.treesSumFromHotspots} '
            '(event roll-up: ${event.totalTreesLost}). '
        : 'Field photos and TFLite results were not yet available for all hotspots '
            '(${event.hotspots.length} marked). ';

    final satLine = event.damageScore > 0 ||
            event.affectedAreaHa > 0 ||
            event.destroyedAreaM2 > 0 ||
            event.satelliteSummary.isNotEmpty
        ? 'Remote/satellite indicators: damage score ${event.damageScore.toStringAsFixed(1)}/100, '
            '${event.affectedAreaHa.toStringAsFixed(2)} ha affected, '
            '${event.destroyedAreaM2.toStringAsFixed(0)} m² canopy loss'
            '${event.satelliteSummary.isNotEmpty ? '; summary: ${event.satelliteSummary}' : ''}. '
        : '';

    final groqLine = event.satelliteGroqOk
        ? 'Groq vision (satellite tiles) reported model confidence '
            '${(event.satelliteGroqConfidence * 100).toStringAsFixed(0)}% '
            'with automated summary aligned to remote sensing. '
        : (event.satelliteGroqError.trim().isNotEmpty
            ? 'Groq satellite analysis did not complete (${event.satelliteGroqError.trim()}). '
            : '');

    return 'A damage assessment was conducted for the $crop plantation '
        '(Survey No. $survey, $area ha) following the ${event.disasterType} '
        'incident on ${_date(event.occurredAt)}. '
        'Farmer statement: "${event.farmerDescription}". '
        '$camLine'
        '$satLine'
        '$groqLine'
        'Estimated economic exposure (from event): '
        '${event.estimatedLossInr.toStringAsFixed(0)} INR.';
  }

  String _s(String? v, String fallback) =>
      (v == null || v.trim().isEmpty) ? fallback : v.trim();

  String _date(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

class _TfliteRollup {
  const _TfliteRollup({
    required this.total,
    required this.analysed,
    required this.pending,
    required this.damagedCount,
    required this.healthyCount,
    required this.meanConfDamaged,
    required this.meanConfHealthy,
    required this.meanConfAll,
    required this.treesSumFromHotspots,
    required this.perHotspotLines,
  });

  final int total;
  final int analysed;
  final int pending;
  final int damagedCount;
  final int healthyCount;
  final String meanConfDamaged;
  final String meanConfHealthy;
  final String meanConfAll;
  final int treesSumFromHotspots;
  final String perHotspotLines;
}

const _kMaxHotspotLinesInPrompt = 30;

_TfliteRollup _tfliteRollup(List<HotspotModel> hotspots) {
  if (hotspots.isEmpty) {
    return const _TfliteRollup(
      total: 0,
      analysed: 0,
      pending: 0,
      damagedCount: 0,
      healthyCount: 0,
      meanConfDamaged: 'n/a',
      meanConfHealthy: 'n/a',
      meanConfAll: 'n/a',
      treesSumFromHotspots: 0,
      perHotspotLines: '  (no hotspots)',
    );
  }

  final damaged = <double>[];
  final healthy = <double>[];
  final all = <double>[];
  var damagedCount = 0;
  var healthyCount = 0;
  var pending = 0;
  var analysed = 0;
  var treesSum = 0;
  final lines = StringBuffer();
  var lineCount = 0;

  for (final h in hotspots) {
    treesSum += h.treesLost;
    final label = (h.aiResult ?? '').trim();
    final upper = label.toUpperCase();
    final hasLabel = upper == 'DAMAGED' || upper == 'HEALTHY';
    final c = h.aiConfidence;

    if (hasLabel) {
      analysed++;
      if (upper == 'DAMAGED') {
        damagedCount++;
      } else {
        healthyCount++;
      }
      if (c != null) {
        all.add(c);
        if (upper == 'DAMAGED') {
          damaged.add(c);
        } else {
          healthy.add(c);
        }
      }
    } else {
      pending++;
    }

    if (lineCount < _kMaxHotspotLinesInPrompt) {
      final pct = c != null ? '${(c * 100).toStringAsFixed(1)}%' : 'n/a';
      lines.writeln(
        '  #${h.id}: ${hasLabel ? upper : 'PENDING'} — confidence $pct, '
        'trees_lost ${h.treesLost}, '
        'lat ${h.latitude.toStringAsFixed(5)}, lng ${h.longitude.toStringAsFixed(5)}',
      );
      lineCount++;
    }
  }

  if (hotspots.length > _kMaxHotspotLinesInPrompt) {
    lines.writeln(
      '  … (${hotspots.length - _kMaxHotspotLinesInPrompt} more hotspots omitted; '
      'totals above are complete)',
    );
  }

  String mean(List<double> xs) => xs.isEmpty
      ? 'n/a'
      : '${(xs.reduce((a, b) => a + b) / xs.length * 100).toStringAsFixed(1)}%';

  return _TfliteRollup(
    total: hotspots.length,
    analysed: analysed,
    pending: pending,
    damagedCount: damagedCount,
    healthyCount: healthyCount,
    meanConfDamaged: mean(damaged),
    meanConfHealthy: mean(healthy),
    meanConfAll: mean(all),
    treesSumFromHotspots: treesSum,
    perHotspotLines: lines.toString().trimRight(),
  );
}

/// Uses [loadGeminiApiKey] when non-empty; otherwise falls back to templated text.
AINarrativeService narrativeServiceWithOptionalGemini({FirebaseFirestore? firestore}) {
  return AINarrativeService(
    firestore: firestore,
    caller: (prompt) async {
      final key = await loadGeminiApiKey();
      if (key.isEmpty) return '';
      return GeminiNarrativeClient.complete(apiKey: key, prompt: prompt);
    },
  );
}
