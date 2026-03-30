import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/hotspot_model.dart';
import 'ai_result_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  final HotspotModel hotspot;

  const CameraCaptureScreen({super.key, required this.hotspot});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  bool _ready = false;
  String? _capturedPath;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_controller == null || !_ready || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await _controller!.takePicture();
      if (mounted) {
        setState(() => _capturedPath = file.path);
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _usePhoto() async {
    final path = _capturedPath;
    if (path == null) {
      return;
    }
    final updated = await Navigator.of(context).push<HotspotModel>(
      MaterialPageRoute(
        builder: (_) => AIResultScreen(
          hotspot: widget.hotspot.copyWith(photoUrl: path),
          photoPath: path,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (updated != null) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordText =
        '${widget.hotspot.latitude.toStringAsFixed(4)}\u00B0N, ${widget.hotspot.longitude.toStringAsFixed(4)}\u00B0E';
    final hasPreview = _capturedPath != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Damage Photo')),
      body: Stack(
        children: [
          Positioned.fill(
            child: hasPreview
                ? (kIsWeb
                    ? const ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'Photo preview not available on web demo.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    : Image.file(File(_capturedPath!), fit: BoxFit.cover))
                : _buildCameraView(),
          ),
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Text(
              'Point camera at the damaged area',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                coordText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: hasPreview
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _capturedPath = null),
                          child: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _usePhoto,
                          child: const Text('Use this photo'),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: InkWell(
                      onTap: _capture,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 4),
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(26),
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            : null,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_ready || _controller == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize?.height ?? 1,
          height: _controller!.value.previewSize?.width ?? 1,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }
}
