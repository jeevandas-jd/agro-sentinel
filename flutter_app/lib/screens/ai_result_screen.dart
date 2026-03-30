import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/hotspot_model.dart';

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
  late final bool _damaged;
  late final double _confidence;
  late final int _treesAffected;

  @override
  void initState() {
    super.initState();
    _damaged = DateTime.now().millisecond.isEven;
    _confidence = _damaged ? 0.94 : 0.89;
    _treesAffected = _damaged ? 12 : 0;
    unawaited(_simulateAnalysis());
  }

  Future<void> _simulateAnalysis() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _loading = false);
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
    return Scaffold(
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
                    Text('Analysing damage...'),
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
    );
  }
}
