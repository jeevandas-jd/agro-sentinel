import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceToTextResult {
  final String text;
  final bool isFinal;

  const VoiceToTextResult({required this.text, required this.isFinal});
}

class VoiceToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _initialized = false;
  bool _available = false;
  String? _lastError;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;
  String? get lastError => _lastError;

  Future<bool> ensureInitialized() async {
    if (_initialized) return _available;
    _initialized = true;

    if (kIsWeb) {
      _available = false;
      _lastError = 'Voice input is not supported on web.';
      return _available;
    }

    try {
      _available = await _speech.initialize(
        onError: (e) => _lastError = e.errorMsg,
        onStatus: (_) {},
      );
      return _available;
    } catch (e) {
      _available = false;
      _lastError = e.toString();
      return _available;
    }
  }

  Future<void> startListening({
    String? localeId,
    required ValueChanged<VoiceToTextResult> onResult,
  }) async {
    _lastError = null;
    final ok = await ensureInitialized();
    if (!ok) {
      throw StateError(_lastError ?? 'Speech recognition unavailable.');
    }

    await _speech.listen(
      localeId: localeId,
      // keep compatibility with current speech_to_text version
      // ignore: deprecated_member_use
      listenMode: stt.ListenMode.confirmation,
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) {
          onResult(VoiceToTextResult(text: text, isFinal: result.finalResult));
        }
      },
    );
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  void dispose() {
    _speech.cancel();
  }
}

