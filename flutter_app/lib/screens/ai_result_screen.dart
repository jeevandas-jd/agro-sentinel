import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/hotspot_model.dart';
import '../services/inference_service.dart';
import '../widgets/tutorial_wrapper.dart';

class AIResultScreen extends StatefulWidget {
  final HotspotModel hotspot;
  final String photoPath;

  const AIResultScreen({
    super.key,
    required this.hotspot,
    required this.photoPath,
  });

  @override
  State<AIResultScreen> createState() => _AIResultScreenState();
}

class _AIResultScreenState extends State<AIResultScreen> {
  bool _loading = true;
  bool _damaged = false;
  double _confidence = 0.0;
  int _treesAffected = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_runAnalysis());
  }

  Future<void> _runAnalysis() async {
    if (kIsWeb) {
      // Web platform has no file access — keep a reasonable demo value.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _damaged = true;
          _confidence = 0.87;
          _treesAffected = 8;
          _loading = false;
        });
      }
      return;
    }

    try {
      final service = InferenceService();
      await service.loadModel();
      final result = await service.classify(File(widget.photoPath));
      service.dispose();

      if (mounted) {
        final isDamaged = (result['label'] as String) == 'damaged';
        final confidence = result['confidence'] as double;
        setState(() {
          _damaged = isDamaged;
          _confidence = confidence;
          // Estimate affected trees from confidence × a base count of 20 trees/hotspot.
          _treesAffected = isDamaged ? math.max(1, (confidence * 20).round()) : 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Analysis failed: ${e.toString().split('\n').first}';
          _loading = false;
        });
      }
    }
  }

  void _confirm() {
    final updated = widget.hotspot.copyWith(
      aiResult: _damaged ? 'DAMAGED' : 'HEALTHY',
      aiConfidence: _confidence,
      treesLost: _treesAffected,
      gradcamUrl: 'generated://gradcam',
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = _damaged ? Colors.red : Colors.green;
    final resultLabel = _damaged ? 'DAMAGED' : 'HEALTHY';
    return TutorialWrapper(
      screenKey: 'ai_result',
      child: Scaffold(
        appBar: AppBar(title: const Text('AI Result')),
        body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (kIsWeb)
                    const ColoredBox(color: Colors.black12)
                  else
                    Image.file(File(widget.photoPath), fit: BoxFit.cover),
                  if (!_loading && _damaged)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [Color(0x66FF0000), Color(0x00FF0000)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 12),
                    Text('Running AI damage analysis…'),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.orange),
                      )
                    else ...[
                      Text(
                        resultLabel,
                        style: TextStyle(
                          color: resultColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${(_confidence * 100).toStringAsFixed(0)}% confidence'),
                      const SizedBox(height: 6),
                      if (_damaged) Text('Estimated trees affected: $_treesAffected'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _confirm,
            child: const Text('Confirm and Continue'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retake Photo'),
          ),
        ],
        ),
      ),
    );
  }
}
