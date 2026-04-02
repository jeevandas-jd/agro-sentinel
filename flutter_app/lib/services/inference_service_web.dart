import 'dart:io';

/// Web stub for InferenceService.
///
/// tflite_flutter uses dart:ffi which is incompatible with the web target.
/// This stub exposes the same public API so all import sites compile on web
/// without pulling in any FFI code. The actual model is never run on web —
/// callers must guard with `kIsWeb` before invoking classify().
class InferenceService {
  Future<void> loadModel() async {}

  Future<Map<String, dynamic>> classify(File imageFile) async {
    return <String, dynamic>{
      'label': 'non_damaged',
      'confidence': 0.0,
    };
  }

  void dispose() {}
}
