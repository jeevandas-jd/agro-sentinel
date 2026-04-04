import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/dart_define_config.dart';
import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/hotspot_model.dart';
import 'gemini_narrative_client.dart';

/// Holds both AI-generated narrative outputs from a single Gemini call.
///
/// [preview] is a 2-3 sentence executive summary shown on the Damage Report
/// Preview screen. [report] is the full 4-6 paragraph formal assessment used
/// inside the PDF.
class NarrativeResult {
  const NarrativeResult({required this.preview, required this.report});

  final String preview;
  final String report;

  static const empty = NarrativeResult(preview: '', report: '');
}

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

  Future<NarrativeResult> generateNarrative(DisasterEventModel event) async {
    try {
      final farm = await _tryLoadFarm(event.farmId);
      final prompt = _buildPrompt(event: event, farm: farm);
      final caller = _caller;
      if (caller == null) return _fallbackNarrative(event: event, farm: farm);
      final raw = (await caller(prompt)).trim();
      if (raw.isEmpty) return _fallbackNarrative(event: event, farm: farm);
      final parsed = _parseJsonResult(raw);
      if (parsed != null) return parsed;
      // Gemini returned plain text despite JSON instruction — treat as report
      // only and synthesise a short preview from the first two sentences.
      final preview = _firstSentences(raw, 2);
      return NarrativeResult(preview: preview, report: raw);
    } catch (_) {
      return _fallbackNarrative(event: event, farm: null);
    }
  }

  /// Attempts to extract {preview, report} from a Gemini JSON response.
  /// Strips markdown code fences if present before parsing.
  static NarrativeResult? _parseJsonResult(String raw) {
    try {
      var s = raw.trim();
      // Strip ```json ... ``` or ``` ... ``` fences Gemini sometimes adds.
      if (s.startsWith('```')) {
        final end = s.lastIndexOf('```');
        if (end > 3) {
          s = s.substring(s.indexOf('\n') + 1, end).trim();
        }
      }
      final map = jsonDecode(s) as Map<String, dynamic>;
      final preview = (map['preview'] as String? ?? '').trim();
      final report = (map['report'] as String? ?? '').trim();
      if (preview.isEmpty && report.isEmpty) return null;
      return NarrativeResult(
        preview: preview.isEmpty ? _firstSentences(report, 2) : preview,
        report: report.isEmpty ? raw : report,
      );
    } catch (_) {
      return null;
    }
  }

  static String _firstSentences(String text, int n) {
    final pattern = RegExp(r'[.!?]\s+');
    final matches = pattern.allMatches(text).toList();
    if (matches.length < n) return text.trim();
    final end = matches[n - 1].end;
    return text.substring(0, end).trim();
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

    final cropAge = event.cropAgeYears != null
        ? '${event.cropAgeYears} year(s)'
        : 'not recorded';
    final bearingStatus = event.isBearing == null
        ? 'not recorded'
        : (event.isBearing! ? 'bearing (in production)' : 'non-bearing');

    return '''
You are a certified agricultural insurance assessment officer writing a formal damage assessment dossier entry.

── Farm ──────────────────────────────────────────────
Farm name   : ${_s(farm?.name, 'N/A')}
Crop        : $crop plantation
Survey No.  : $survey
Area        : $area ha
Crop age    : $cropAge
Bearing     : $bearingStatus

── Incident ──────────────────────────────────────────
Type        : ${event.disasterType}
Occurred    : ${_date(event.occurredAt)}
Reported    : ${_date(event.reportedAt)}
Status      : ${event.status}
Farmer note : ${event.farmerDescription}

── On-device damage model (TFLite, binary damaged vs healthy) ─
Model asset : bundled classifier on captured field photos (resize + ImageNet norm).
Hotspots total                                : ${tf.total}
Photos analysed                               : ${tf.analysed}
Pending / no result                           : ${tf.pending}
Class DAMAGED                                 : ${tf.damagedCount}
Class HEALTHY                                 : ${tf.healthyCount}
Mean confidence (damaged hotspots only)       : ${tf.meanConfDamaged}
Mean confidence (healthy hotspots only)       : ${tf.meanConfHealthy}
Mean confidence (all analysed hotspots)       : ${tf.meanConfAll}
Trees lost (sum of hotspot estimates)         : ${tf.treesSumFromHotspots}
Event total_trees_lost field (authoritative)  : ${event.totalTreesLost}
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

── Output format ────────────────────────────────────
Return ONLY a valid JSON object (no markdown fences, no extra text) with exactly two keys:

"preview": A single short paragraph of 2-3 sentences written in plain, accessible English.
  This is shown to the farmer on the app preview screen. It must state: the disaster type,
  the date it occurred, the overall classification result (how many hotspots damaged vs healthy),
  and the estimated financial loss. Keep it concise and non-technical.

"report": A full formal insurance assessment of 4-6 paragraphs written in professional
  insurance-grade English. Structure as follows:
  § 1 — Farm & incident overview (farm name, crop, survey no., area, disaster type, dates).
  § 2 — Ground-level findings: TFLite per-hotspot results, confidence levels, trees lost.
  § 3 — Remote sensing evidence: Groq satellite analysis (damage score, affected area,
         destroyed canopy, Groq confidence, summary) when call succeeded; note unavailability
         if not. Do not treat Groq figures as verified when "Call succeeded" is no.
  § 4 — Economic exposure: estimated trees lost, estimated loss in INR, supporting data.
  § 5 — Assessment conclusion and recommendation for the claims officer.
  (Add § 6 only if there is meaningful additional context such as farmer statement nuances.)

Rules:
- Do not invent any number not present in the data above.
- Do not double-count TFLite and Groq figures.
- Use "₹" for INR amounts.
- The JSON must be parseable with json.decode — escape any quotes inside strings.
''';
  }

  NarrativeResult _fallbackNarrative({
    required DisasterEventModel event,
    required FarmModel? farm,
  }) {
    final crop = _s(farm?.cropType, 'the');
    final farmName = _s(farm?.name, 'the farm');
    final survey = _s(farm?.surveyNumber, 'N/A');
    final area = (farm?.areaHectares ?? 0).toStringAsFixed(2);
    final tf = _tfliteRollup(event.hotspots);
    final cropAgeStr = event.cropAgeYears != null
        ? ', aged ${event.cropAgeYears} year(s)'
        : '';
    final bearingStr = event.isBearing == null
        ? ''
        : (event.isBearing! ? ' (bearing stage)' : ' (non-bearing stage)');

    final camLine = tf.analysed > 0
        ? 'On-device TFLite analysis covered ${tf.analysed} photo(s) at '
            '${event.hotspots.length} hotspot(s): ${tf.damagedCount} classified DAMAGED, '
            '${tf.healthyCount} HEALTHY, pending ${tf.pending}. '
            'Mean model confidence on damaged plots was ${tf.meanConfDamaged}; '
            'tree loss estimated from hotspots totals ${tf.treesSumFromHotspots} '
            '(event roll-up: ${event.totalTreesLost}).'
        : 'Field photos and TFLite results were not yet available for all hotspots '
            '(${event.hotspots.length} marked).';

    final satLine = event.damageScore > 0 ||
            event.affectedAreaHa > 0 ||
            event.destroyedAreaM2 > 0 ||
            event.satelliteSummary.isNotEmpty
        ? ' Remote/satellite indicators: damage score ${event.damageScore.toStringAsFixed(1)}/100, '
            '${event.affectedAreaHa.toStringAsFixed(2)} ha affected, '
            '${event.destroyedAreaM2.toStringAsFixed(0)} m² canopy loss'
            '${event.satelliteSummary.isNotEmpty ? '; summary: ${event.satelliteSummary}' : ''}.'
        : '';

    final groqLine = event.satelliteGroqOk
        ? ' Groq vision (satellite tiles) reported model confidence '
            '${(event.satelliteGroqConfidence * 100).toStringAsFixed(0)}% '
            'with automated summary aligned to remote sensing.'
        : (event.satelliteGroqError.trim().isNotEmpty
            ? ' Groq satellite analysis did not complete (${event.satelliteGroqError.trim()}).'
            : '');

    final preview =
        'A ${event.disasterType} incident on ${_date(event.occurredAt)} affected '
        '$farmName ($crop plantation$cropAgeStr$bearingStr). '
        '${tf.damagedCount} of ${tf.total} hotspot(s) were classified as DAMAGED '
        'with an estimated loss of ₹${event.estimatedLossInr.toStringAsFixed(0)}.';

    final report =
        'A damage assessment was conducted for the $crop plantation '
        '($farmName, Survey No. $survey, $area ha$cropAgeStr$bearingStr) '
        'following the ${event.disasterType} '
        'incident on ${_date(event.occurredAt)}.\n\n'
        '$camLine$satLine$groqLine\n\n'
        'Farmer statement: "${event.farmerDescription}"\n\n'
        'Estimated economic exposure: ₹${event.estimatedLossInr.toStringAsFixed(0)} INR.';

    return NarrativeResult(preview: preview, report: report);
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
