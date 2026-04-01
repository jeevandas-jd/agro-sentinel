import 'dart:io';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// App-facing API for on-device damage classification.
///
/// Now fully wired with TFLite while preserving original API.
class InferenceService {
  Interpreter? _interpreter;
  bool _loaded = false;

  /// Load model from assets once at app start.
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('models/your_model.tflite');

      // Debug (optional but VERY useful)
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print("✅ Model loaded");
      print("📥 Input shape: $inputShape");
      print("📤 Output shape: $outputShape");

      _loaded = true;
    } catch (e) {
      print("❌ Model load failed: $e");
      rethrow;
    }
  }

  /// Preprocess image
  ///
  /// Expected:
  /// - Resize to 256×256
  /// - Normalize (ImageNet)
  List<List<List<List<double>>>> _preprocess(File file) {
    final bytes = file.readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("Failed to decode image");
    }

    final resized = img.copyResize(image, width: 256, height: 256);

    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    return [
      List.generate(256, (y) {
        return List.generate(256, (x) {
          final pixel = resized.getPixel(x, y);

          return [
            ((pixel.r / 255.0) - mean[0]) / std[0],
            ((pixel.g / 255.0) - mean[1]) / std[1],
            ((pixel.b / 255.0) - mean[2]) / std[2],
          ];
        });
      }),
    ];
  }

  /// Softmax helper
  List<double> _softmax(List<double> logits) {
    final exps = logits.map((e) => math.exp(e)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  /// Run inference on a captured image.
  ///
  /// Returns: `{"label": "damaged", "confidence": 0.94}`
  Future<Map<String, dynamic>> classify(File imageFile) async {
    if (!_loaded || _interpreter == null) {
      throw StateError('InferenceService.loadModel() must be called first.');
    }

    if (!await imageFile.exists()) {
      throw ArgumentError('Image file does not exist: ${imageFile.path}');
    }

    try {
      // Preprocess
      final input = _preprocess(imageFile);

      // Prepare output (assuming [1,2])
      final output = List.generate(1, (_) => List.filled(2, 0.0));

      // Run model
      _interpreter!.run(input, output);

      // Postprocess
      final probs = _softmax(output[0]);

      final damagedProb = probs[0];
      final nonDamagedProb = probs[1];

      final result = damagedProb > nonDamagedProb
          ? {"label": "damaged", "confidence": damagedProb}
          : {"label": "non_damaged", "confidence": nonDamagedProb};

      print("🧠 Inference result: $result");

      return result;
    } catch (e) {
      print("❌ Inference failed: $e");

      // Fallback (your original safe behavior)
      return <String, dynamic>{'label': 'non_damaged', 'confidence': 0.0};
    }
  }

  /// Dispose when app closes.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loaded = false;
  }
}
