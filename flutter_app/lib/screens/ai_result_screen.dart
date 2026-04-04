import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/hotspot_model.dart';
import '../services/inference_service.dart';
import '../services/satellite_service.dart';
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

  bool _satelliteLoading = false;
  Map<String, dynamic>? _satelliteData;
  String? _satelliteError;

  @override
  void initState() {
    super.initState();
    unawaited(_runAnalysis());
  }

  Future<void> _runSatelliteAnalysis() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _satelliteLoading = true;
      _satelliteError = null;
    });
    try {
      final data = await SatelliteService.analyze(
        widget.hotspot.latitude,
        widget.hotspot.longitude,
      );
      if (mounted) {
        setState(() {
          _satelliteData = data;
          _satelliteLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _satelliteError = e.toString().split('\n').first;
          _satelliteLoading = false;
        });
      }
    }
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
      await _runSatelliteAnalysis();
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
    await _runSatelliteAnalysis();
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
          if (!_loading) ...[
            const SizedBox(height: 20),
            Text(
              'Satellite (before / after)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SatelliteThumb(
                    label: 'Before',
                    assetPath: _satelliteData?['before_image'] as String? ??
                        'assets/demo/before.png',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SatelliteThumb(
                    label: 'After',
                    assetPath: _satelliteData?['after_image'] as String? ??
                        'assets/demo/after.png',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_satelliteLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Calling Groq vision model…'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_satelliteError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _satelliteError!,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              )
            else if (_satelliteData != null) ...[
              if (!(_satelliteData!['groq_ok'] as bool? ?? false))
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber.shade900),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _satelliteData!['groq_error'] as String? ??
                                'Groq did not return a live result. Values below are placeholders.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!(_satelliteData!['groq_ok'] as bool? ?? false))
                const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satellite assessment',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _SatelliteMetric(
                        label: 'Damage score',
                        value:
                            '${(_satelliteData!['damage_score'] as num?)?.toStringAsFixed(1) ?? '—'} / 100',
                      ),
                      _SatelliteMetric(
                        label: 'Model confidence',
                        value: _satelliteData!['confidence'] != null
                            ? '${((_satelliteData!['confidence'] as num) * 100).toStringAsFixed(0)}%'
                            : '—',
                      ),
                      _SatelliteMetric(
                        label: 'Affected area',
                        value:
                            '${(_satelliteData!['affected_area_ha'] as num?)?.toStringAsFixed(2) ?? '—'} ha',
                      ),
                      _SatelliteMetric(
                        label: 'Destroyed canopy',
                        value:
                            '${(_satelliteData!['destroyed_area_m2'] as num?)?.toStringAsFixed(0) ?? '—'} m²',
                      ),
                      _SatelliteMetric(
                        label: 'Trees lost (est.)',
                        value:
                            '${_satelliteData!['trees_lost'] ?? '—'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _satelliteData!['summary'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
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

class _SatelliteThumb extends StatelessWidget {
  const _SatelliteThumb({required this.label, required this.assetPath});

  final String label;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: Colors.grey.shade800,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Missing $assetPath\nAdd file under assets/demo/',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SatelliteMetric extends StatelessWidget {
  const _SatelliteMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
