import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

/// Set via `--dart-define=GEMINI_API_KEY=...` or Android [BuildConfig] from
/// `android/local.properties` (`GEMINI_API_KEY=...`).
const kGeminiApiKeyCompileTime = String.fromEnvironment('GEMINI_API_KEY');

Future<String> loadGeminiApiKey() async {
  if (kGeminiApiKeyCompileTime.isNotEmpty) {
    return kGeminiApiKeyCompileTime;
  }
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    debugPrint(
      '[Gemini] No compile-time GEMINI_API_KEY; narrative API only wired on Android.',
    );
    return '';
  }
  try {
    const channel = MethodChannel('com.example.frontend/secrets');
    final raw = await channel.invokeMethod<dynamic>('getGeminiApiKey');
    final key = raw == null ? '' : '$raw'.trim();
    if (key.isEmpty) {
      debugPrint(
        '[Gemini] BuildConfig.GEMINI_API_KEY is empty — set GEMINI_API_KEY in '
        'android/local.properties and run a full rebuild (not hot reload).',
      );
    }
    return key;
  } catch (e, st) {
    debugPrint('[Gemini] MethodChannel getGeminiApiKey failed: $e\n$st');
    return '';
  }
}
