import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/dart_define_config.dart';
import '../models/disaster_event_model.dart';
import 'ai_narrative_service.dart';
import 'gemini_narrative_client.dart';
import 'satellite_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ReportContent — structured output handed to the PDF / Dossier screen.
//  Access every field directly; no more raw maps.
// ═══════════════════════════════════════════════════════════════════════════════
class ReportContent {
  // Narrative
  final String narrative;

  // Identity
  final String farmId;
  final String farmerUid;
  final String disasterType;
  final String farmerStatement;
  final DateTime occurredAt;
  final DateTime reportedAt;
  final String status;

  // Satellite
  final double damageScore;
  final double affectedAreaHa;
  final double destroyedAreaM2;
  final double canopyConstant;
  final int treesLost;
  final double estimatedLossInr;
  final String satelliteSummary;
  final String beforeImageAsset;
  final String afterImageAsset;

  // Camera / TFLite
  final double cameraConfidence;
  final int totalLocations;
  final int damagedLocations;
  final String? capturedImagePath;

  const ReportContent({
    required this.narrative,
    required this.farmId,
    required this.farmerUid,
    required this.disasterType,
    required this.farmerStatement,
    required this.occurredAt,
    required this.reportedAt,
    required this.status,
    required this.damageScore,
    required this.affectedAreaHa,
    required this.destroyedAreaM2,
    required this.canopyConstant,
    required this.treesLost,
    required this.estimatedLossInr,
    required this.satelliteSummary,
    required this.cameraConfidence,
    required this.totalLocations,
    required this.damagedLocations,
    this.capturedImagePath,
    this.beforeImageAsset = 'assets/demo/before.png',
    this.afterImageAsset = 'assets/demo/after.png',
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ReportService
// ═══════════════════════════════════════════════════════════════════════════════
class ReportService {
  ReportService({String? geminiApiKey, FirebaseFirestore? firestore})
    : _geminiApiKeyOverride = geminiApiKey,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final String? _geminiApiKeyOverride;
  final FirebaseFirestore _firestore;

  /// Orchestrates all three service outputs → AI narrative → ReportContent.
  ///
  /// [satellite]       — from SatelliteService.analyze()
  /// [camera]          — from InferenceService.classify()
  /// [existingEvent]   — the DisasterEventModel already built by your flow
  ///                     (fromFirestore or freshly constructed)
  /// [capturedImagePath] — optional on-device photo path from CameraScreen
  Future<ReportContent> generateReport({
    required Map<String, dynamic> satellite,
    required Map<String, dynamic> camera,
    required DisasterEventModel existingEvent,
    String? capturedImagePath,
  }) async {
    // ── 1. Compute Trees Lost (formula lives here, not in SatelliteService) ──
    // ══════════════════════════════════════════════════════════════════════════
    //  Trees Lost = Destroyed Area (m²) ÷ Canopy Constant
    // ══════════════════════════════════════════════════════════════════════════
    final double destroyedM2 =
        (satellite['destroyed_area_m2'] as num?)?.toDouble() ?? 0.0;
    final double canopyConstant =
        (satellite['canopy_constant'] as num?)?.toDouble() ?? 25.0;
    final int treesLost = (destroyedM2 / canopyConstant).round();

    // ── 2. Enrich the existing event with live service data via copyWith ──────
    final enrichedEvent = existingEvent.copyWith(
      totalTreesLost: treesLost,
      damageScore: (satellite['damage_score'] as num?)?.toDouble() ?? 0.0,
      confidence: (camera['confidence'] as num?)?.toDouble() ?? 0.0,
      destroyedAreaM2: destroyedM2,
      affectedAreaHa:
          (satellite['affected_area_ha'] as num?)?.toDouble() ?? 0.0,
      satelliteSummary: (satellite['summary'] as String?) ?? '',
      capturedImagePath: capturedImagePath,
      satelliteGroqOk: satellite['groq_ok'] as bool? ?? false,
      satelliteGroqError: (satellite['groq_error'] as String?)?.trim() ?? '',
      satelliteGroqConfidence: SatelliteService.groqModelConfidence(satellite),
      satelliteGroqDetailsJson:
          SatelliteService.groqResponseJsonForNarrative(satellite),
    );

    // ── 3. Generate the AI narrative via AINarrativeService ──────────────────
    final narrativeService = AINarrativeService(
      firestore: _firestore,
      caller: (prompt) async {
        final key = _geminiApiKeyOverride ?? await loadGeminiApiKey();
        if (key.isEmpty) return '';
        return GeminiNarrativeClient.complete(apiKey: key, prompt: prompt);
      },
    );
    final narrativeResult = await narrativeService.generateNarrative(enrichedEvent);

    // ── 4. Return fully structured ReportContent for the PDF renderer ─────────
    return ReportContent(
      narrative: narrativeResult.report,
      farmId: enrichedEvent.farmId,
      farmerUid: enrichedEvent.farmerUid,
      disasterType: enrichedEvent.disasterType,
      farmerStatement: enrichedEvent.farmerDescription,
      occurredAt: enrichedEvent.occurredAt,
      reportedAt: enrichedEvent.reportedAt,
      status: enrichedEvent.status,
      damageScore: enrichedEvent.damageScore,
      affectedAreaHa: enrichedEvent.affectedAreaHa,
      destroyedAreaM2: destroyedM2,
      canopyConstant: canopyConstant,
      treesLost: treesLost,
      estimatedLossInr: enrichedEvent.estimatedLossInr,
      satelliteSummary: enrichedEvent.satelliteSummary,
      cameraConfidence: enrichedEvent.confidence,
      totalLocations: enrichedEvent.hotspots.length,
      damagedLocations: enrichedEvent.damagedHotspotsCount,
      capturedImagePath: capturedImagePath,
      beforeImageAsset:
          (satellite['before_image'] as String?) ?? 'assets/demo/before.png',
      afterImageAsset:
          (satellite['after_image'] as String?) ?? 'assets/demo/after.png',
    );
  }
}
