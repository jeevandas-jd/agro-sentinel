// lib/services/satellite_service.dart  ← FINAL VERSION
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // rootBundle
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────────
///  Canopy Constant — average canopy footprint per mature tree (m²)
///
///  Dense tropical / monsoon forest  →  25 – 35 m²
///  Sparse scrub / dryland           →  10 – 18 m²
///  Plantation / orchard             →  12 – 20 m²
///
///  Adjust this one value to calibrate the "Trees Lost" estimate for your region.
/// ─────────────────────────────────────────────────────────────────────────────
const double kCanopyConstant = 25.0; // ← m² per tree  ★ TUNE THIS ★

const String _kGroqFromDefine = String.fromEnvironment('GROQ_API_KEY');

class _GroqOutcome {
  const _GroqOutcome({
    required this.ok,
    required this.payload,
    this.errorMessage,
  });

  final bool ok;
  final Map<String, dynamic> payload;
  final String? errorMessage;
}

class SatelliteService {
  static Future<String> _loadGroqApiKey() async {
    final fromDefine = _kGroqFromDefine.trim();
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    const MethodChannel channel = MethodChannel('com.example.frontend/secrets');
    try {
      final raw = await channel.invokeMethod<dynamic>('getGroqApiKey');
      final key = raw == null ? '' : '$raw'.trim();
      if (key.isEmpty) {
        debugPrint(
          '[SatelliteService] GROQ_API_KEY is empty — add GROQ_API_KEY=... to '
          'android/local.properties (then full rebuild), or pass '
          '--dart-define=GROQ_API_KEY=...',
        );
      }
      return key;
    } catch (e, st) {
      debugPrint(
        '[SatelliteService] MethodChannel getGroqApiKey failed: $e\n$st',
      );
      return '';
    }
  }

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // ── Public API ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> analyze(double lat, double lng) async {
    try {
      final beforeB64 = await _assetBase64('assets/demo/before.png');
      final afterB64 = await _assetBase64('assets/demo/after.png');

      final outcome = await _callGroq(lat, lng, beforeB64, afterB64);
      final raw = outcome.payload;

      final double destroyedM2 =
          (raw['destroyed_area_m2'] as num?)?.toDouble() ?? 0.0;
      final int treesLost = (destroyedM2 / kCanopyConstant).round();

      return {
        'groq_ok': outcome.ok,
        'groq_error': outcome.errorMessage,
        'damage_score': (raw['damage_score'] as num?)?.toDouble() ?? 0.0,
        'confidence': (raw['confidence'] as num?)?.toDouble() ?? 0.0,
        'summary': raw['summary'] as String? ?? '',
        'affected_area_ha':
            (raw['affected_area_ha'] as num?)?.toDouble() ?? 0.0,
        'destroyed_area_m2': destroyedM2,
        'trees_lost': treesLost,
        'canopy_constant': kCanopyConstant,
        'before_image': 'assets/demo/before.png',
        'after_image': 'assets/demo/after.png',
        'groq_response': Map<String, dynamic>.from(raw),
      };
    } catch (e, st) {
      debugPrint('[Satellite] analyze failed: $e\n$st');
      final fb = _fallback();
      return {
        'groq_ok': false,
        'groq_error':
            'Could not load demo images or run analysis. ${e.toString().split('\n').first}',
        'damage_score': (fb['damage_score'] as num).toDouble(),
        'confidence': (fb['confidence'] as num).toDouble(),
        'summary': fb['summary'] as String,
        'affected_area_ha': (fb['affected_area_ha'] as num).toDouble(),
        'destroyed_area_m2': (fb['destroyed_area_m2'] as num).toDouble(),
        'trees_lost': 0,
        'canopy_constant': kCanopyConstant,
        'before_image': 'assets/demo/before.png',
        'after_image': 'assets/demo/after.png',
        'groq_response': fb,
      };
    }
  }

  // ── Groq multimodal call ─────────────────────────────────────────────────────
  static Future<_GroqOutcome> _callGroq(
    double lat,
    double lng,
    String beforeB64,
    String afterB64,
  ) async {
    const system = '''
You are a precision agricultural damage assessment AI.
Compare the two satellite images (before / after a disaster) and return ONLY
a valid JSON object — no markdown fences, no extra text.

Required JSON schema:
{
  "damage_score"      : <float 0-100>,
  "confidence"        : <float 0-1>,
  "affected_area_ha"  : <float, total affected area in hectares>,
  "destroyed_area_m2" : <float, area of complete canopy loss in m²>,
  "summary"           : "<one concise sentence>"
}

Rules:
- Compare green cover in before vs bare/brown in after to find destroyed_area_m2.
- Assume a 500 m × 500 m tile if no scale reference is visible.
- destroyed_area_m2 = complete loss only, not partial browning.
''';

    final payload = jsonEncode({
      'model': _model,
      'temperature': 0.1,
      'max_tokens': 512,
      'messages': [
        {'role': 'system', 'content': system},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'lat=$lat, lng=$lng. Image 1 = BEFORE. Image 2 = AFTER.',
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/png;base64,$beforeB64'},
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/png;base64,$afterB64'},
            },
          ],
        },
      ],
    });

    final key = await _loadGroqApiKey();
    if (key.isEmpty) {
      return _GroqOutcome(
        ok: false,
        payload: _fallback(),
        errorMessage:
            'Missing GROQ_API_KEY. Add it to android/local.properties and rebuild, '
            'or use --dart-define=GROQ_API_KEY=your_key',
      );
    }

    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: payload,
      );

      if (res.statusCode != 200) {
        debugPrint('[Satellite] Groq ${res.statusCode}: ${res.body}');
        final apiMsg = _groqErrorMessageFromBody(res.body);
        return _GroqOutcome(
          ok: false,
          payload: _fallback(),
          errorMessage:
              apiMsg ?? 'Groq request failed (HTTP ${res.statusCode}).',
        );
      }

      final content =
          (jsonDecode(res.body) as Map)['choices'][0]['message']['content']
              as String;
      final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return _GroqOutcome(ok: true, payload: parsed);
    } catch (e) {
      debugPrint('[Satellite] Error: $e');
      return _GroqOutcome(
        ok: false,
        payload: _fallback(),
        errorMessage: e.toString().split('\n').first,
      );
    }
  }

  static String? _groqErrorMessageFromBody(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>?;
      final err = map?['error'];
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static Future<String> _assetBase64(String path) async {
    final data = await rootBundle.load(path);
    return base64Encode(data.buffer.asUint8List());
  }

  static Map<String, dynamic> _fallback() => {
    'damage_score': 0.0,
    'confidence': 0.0,
    'affected_area_ha': 0.0,
    'destroyed_area_m2': 0.0,
    'summary': 'Analysis unavailable.',
  };
}
