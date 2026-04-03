import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Google Gemini `generateContent` (Google AI Studio API key, `AIza…`).
///
/// https://ai.google.dev/api/rest/v1beta/models.generateContent
class GeminiNarrativeClient {
  GeminiNarrativeClient._();

  /// See https://ai.google.dev/gemini-api/docs/models/gemini — adjust if Google deprecates it.
  static const _model = 'gemini-2.5-flash';
  static String get _url =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const _requestTimeout = Duration(seconds: 60);

  static const _system =
      'You are a certified agricultural insurance assessment officer.';

  static Future<String> complete({
    required String apiKey,
    required String prompt,
  }) async {
    if (apiKey.isEmpty) return '';
    // Single user turn avoids systemInstruction / role quirks across API versions.
    final combined = '$_system\n\n$prompt';
    try {
      final res = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': combined},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 1024,
              },
            }),
          )
          .timeout(_requestTimeout);

      final map = jsonDecode(res.body) as Map<String, dynamic>;

      if (map.containsKey('error')) {
        debugPrint('[GeminiNarrativeClient] error object: ${map['error']}');
        return '';
      }

      if (res.statusCode != 200) {
        debugPrint(
          '[GeminiNarrativeClient] HTTP ${res.statusCode}: '
          '${res.body.length > 800 ? '${res.body.substring(0, 800)}…' : res.body}',
        );
        return '';
      }

      final text = _extractText(map);
      if (text == null || text.isEmpty) {
        debugPrint(
          '[GeminiNarrativeClient] Empty candidates. Body (truncated): '
          '${res.body.length > 600 ? '${res.body.substring(0, 600)}…' : res.body}',
        );
        return '';
      }
      return text;
    } catch (e, st) {
      debugPrint('[GeminiNarrativeClient] exception: $e\n$st');
      return '';
    }
  }

  static String? _extractText(Map<String, dynamic> map) {
    final candidates = map['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map<String, dynamic>) return null;

    final finish = first['finishReason'] as String?;
    if (finish != null && finish != 'STOP' && finish != 'MAX_TOKENS') {
      debugPrint('[GeminiNarrativeClient] finishReason=$finish');
    }

    final content = first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;
    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map<String, dynamic> && p['text'] is String) {
        buf.write(p['text'] as String);
      }
    }
    final s = buf.toString().trim();
    return s.isEmpty ? null : s;
  }
}
