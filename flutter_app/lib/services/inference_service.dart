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

  // Cached tensor metadata (populated by loadModel()).
  int _inputHeight = 256;
  int _inputWidth = 256;
  int _inputChannels = 3;
  int _numClasses = 2;
  bool _binaryModel = true;
  int _outputRank = 2;

  /// Load model from assets once at app start.
  Future<void> loadModel() async {
    try {
      // Must match `pubspec.yaml`:
      //   - assets/models/model.tflite
      // => load path is `models/model.tflite`
      _interpreter = await Interpreter.fromAsset('models/model.tflite');

      // Debug (optional but VERY useful)
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      final inputShape = inputTensor.shape; // e.g. [1, 256, 256, 3]
      final outputShape = outputTensor.shape; // e.g. [1, 2]

      print("✅ Model loaded");
      print("📥 Input shape: $inputShape");
      print("📤 Output shape: $outputShape");

      // Infer expected dimensions from model tensors.
      // Note: this implementation currently supports float input models with 3 channels.
      if (inputShape.length == 4) {
        // [batch, height, width, channels]
        _inputHeight = inputShape[1];
        _inputWidth = inputShape[2];
        _inputChannels = inputShape[3];
      }

      if (outputShape.isNotEmpty) {
        _outputRank = outputShape.length;
        if (outputShape.length == 2) {
          // [batch, classes]
          _numClasses = outputShape[1];
        } else if (outputShape.length == 1) {
          // [classes]
          _numClasses = outputShape[0];
        } else {
          // Fallback: flatten to last dimension-ish.
          _numClasses = outputShape.last;
        }
      }

      _binaryModel = _numClasses == 2;

      print("🧮 Using input: ${_inputHeight}x${_inputWidth}x$_inputChannels");
      print("🧮 Using classes: $_numClasses");

      // Guardrails: if the model expects something else, you'll get clearer errors later.
      if (_inputChannels != 3) {
        throw UnsupportedError(
          'Unsupported input channels $_inputChannels. Only 3-channel RGB models are supported by this classifier.',
        );
      }

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

    final resized = img.copyResize(image, width: _inputWidth, height: _inputHeight);

    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    return [
      List.generate(_inputHeight, (y) {
        return List.generate(_inputWidth, (x) {
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

      // Prepare output based on model output rank.
      dynamic output;
      if (_outputRank == 2) {
        // [batch, classes]
        output = List.generate(1, (_) => List.filled(_numClasses, 0.0));
      } else if (_outputRank == 1) {
        // [classes]
        output = List.filled(_numClasses, 0.0);
      } else {
        // Best-effort fallback: treat as flattened [classes].
        output = List.filled(_numClasses, 0.0);
      }

      // Run model
      _interpreter!.run(input, output);

      // Postprocess
      final logits = _outputRank == 2
          ? (output as List<List<double>>)[0]
          : (output as List<double>);

      final probs = _softmax(logits);
      final topProb = probs.reduce(math.max);
      final topIndex = probs.indexOf(topProb);

      final result = _binaryModel
          ? (() {
              final damagedProb = probs[0];
              final nonDamagedProb = probs[1];
              return damagedProb > nonDamagedProb
                  ? {"label": "damaged", "confidence": damagedProb}
                  : {"label": "non_damaged", "confidence": nonDamagedProb};
            })()
          : {"label": "class_$topIndex", "confidence": topProb};

      print("🧠 Inference result: $result");

      return {
        ...result,
        'probs': probs,
        'numClasses': _numClasses,
      };
    } catch (e) {
      print("❌ Inference failed: $e");

      // Fallback (your original safe behavior)
      return <String, dynamic>{
        'label': 'non_damaged',
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Dispose when app closes.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loaded = false;
  }
}
