import 'dart:io';

/// App-facing API for on-device damage classification.
///
/// The actual TFLite model/runtime wiring is being developed on another branch.
/// This class is intentionally kept dependency-free so the rest of the app can
/// compile and integrate against the final method signatures.
class InferenceService {
  bool _loaded = false;

  /// Load model from assets once at app start.
  Future<void> loadModel() async {
    _loaded = true;
  }

  /// Run inference on a captured image.
  ///
  /// Returns: `{"label": "damaged", "confidence": 0.94}`
  ///
  /// Expected preprocessing (to be implemented with the model integration):
  /// - Resize to 256×256
  /// - Normalize with ImageNet mean/std
  ///
  /// Expected output postprocessing:
  /// - Two logits → softmax → [damaged_prob, non_damaged_prob]
  /// - Label mapping: index 0 = damaged, index 1 = non_damaged
  Future<Map<String, dynamic>> classify(File imageFile) async {
    if (!_loaded) {
      throw StateError('InferenceService.loadModel() must be called first.');
    }

    if (!await imageFile.exists()) {
      throw ArgumentError('Image file does not exist: ${imageFile.path}');
    }

    // Placeholder implementation until the real TFLite pipeline lands.
    // Chosen to be stable and "safe" for UX: default to non_damaged.
    return <String, dynamic>{
      'label': 'non_damaged',
      'confidence': 0.0,
    };
  }

  /// Dispose when app closes.
  void dispose() {
    _loaded = false;
  }
}

