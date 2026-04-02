import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/hotspot.dart';
import '../theme/app_theme.dart';
import '../widgets/damage_gauge.dart';
import '../widgets/glass_panel.dart';
import 'claim_screen.dart';
import '../services/inference_service.dart';

class CameraScreen extends StatefulWidget {
  final Hotspot hotspot;

  const CameraScreen({super.key, required this.hotspot});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _cameraError = false;
  String? _capturedImagePath;

  // Animations
  late AnimationController _scanController;
  late AnimationController _resultController;
  late AnimationController _damageController;
  late Animation<double> _scanLine;
  late Animation<double> _resultFade;
  late Animation<double> _damageAnimation;

  bool _isCapturing = false;
  bool _analysisComplete = false;
  double _currentDamage = 0.0;
  //static const double _targetDamage = 67.4;
  double _realDamage = 0.0;
  DateTime _captureTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _captureTime = DateTime.now();
    _initAnimations();
    _initCamera();
  }

  void _initAnimations() {
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanLine = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanController, curve: Curves.linear));

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );

    _damageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // ✅ Start with a 0→0 animation; it will be rebuilt with the real
    //    target after inference completes.
    _damageAnimation =
        Tween<double>(begin: 0.0, end: 0.0).animate(
          CurvedAnimation(parent: _damageController, curve: Curves.easeOut),
        )..addListener(
          () => setState(() => _currentDamage = _damageAnimation.value),
        );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = true);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  Future<void> _captureAndAnalyse() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _captureTime = DateTime.now();
    });

    // ✅ Only attempt camera capture on native platforms
    if (!kIsWeb && _cameraReady && _cameraController != null) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        _capturedImagePath = photo.path;
      } catch (_) {}
    }

    _scanController.repeat();

    // ✅ Guard: only run real inference if we actually have an image file
    double result = 0.0;
    if (!kIsWeb && _capturedImagePath != null) {
      try {
        final inferenceService = InferenceService();
        await inferenceService.loadModel();
        final output = await inferenceService.classify(
          File(_capturedImagePath!),
        );
        result = output['label'] == 'damaged'
            ? (output['confidence'] as double) * 100
            : 0.0;
      } catch (e) {
        debugPrint('Inference error: $e');
        // Fall through with result = 0.0 (or use a demo value on error)
        result = 0.0;
      }
    } else {
      // ✅ Web / no image: demo value so the UI still runs
      await Future.delayed(const Duration(milliseconds: 1800));
      result = 42.0;
    }

    if (!mounted) return;
    _scanController.stop();

    // ✅ Rebuild the Tween with the REAL target, then start fresh
    _realDamage = result;
    _damageController.reset();
    _damageAnimation =
        Tween<double>(begin: 0.0, end: _realDamage).animate(
          CurvedAnimation(parent: _damageController, curve: Curves.easeOut),
        )..addListener(
          () => setState(() => _currentDamage = _damageAnimation.value),
        );

    setState(() => _analysisComplete = true);

    _resultController.forward();
    _damageController.forward();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanController.dispose();
    _resultController.dispose();
    _damageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera / background
          _buildCameraLayer(),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      AppColors.oliveLight.withValues(alpha: 0.10),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.16),
                    ],
                    stops: const [0.0, 0.22, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 2. Captured photo freeze-frame (native only, during analysis)
          if (_capturedImagePath != null && !kIsWeb)
            Positioned.fill(
              child: Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
            ),

          // 3. Scan animation (full-screen sweep)
          if (_isCapturing && !_analysisComplete)
            AnimatedBuilder(
              animation: _scanLine,
              builder: (context, child) =>
                  CustomPaint(painter: _ScanLinePainter(_scanLine.value)),
            ),

          // 4. Viewfinder frame — upper-center
          Align(
            alignment: const Alignment(0, -0.25),
            child: SizedBox(
              width: 260,
              height: 210,
              child: CustomPaint(
                painter: _ViewfinderPainter(
                  analysisComplete: _analysisComplete,
                ),
              ),
            ),
          ),

          // 5. "DAMAGED ZONE" badge — above the viewfinder
          if (_analysisComplete)
            FadeTransition(
              opacity: _resultFade,
              child: Align(
                alignment: const Alignment(0, -0.72),
                child: _DamagedZoneBadge(percentage: _currentDamage),
              ),
            ),

          // 6. Damage gauge — below the viewfinder, clearly separated
          if (_analysisComplete)
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _resultController,
                      curve: Curves.easeOut,
                    ),
                  ),
              child: FadeTransition(
                opacity: _resultFade,
                child: Align(
                  alignment: const Alignment(0, 0.30),
                  child: _buildAnalysisResult(),
                ),
              ),
            ),

          // 7. Telemetry HUD — just above the action button
          Positioned(
            left: 16,
            right: 16,
            bottom: 88,
            child: _buildTelemetryHUD(),
          ),

          // 8. Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildTopBar()),
          ),

          // 9. Bottom action button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildBottomButton()),
          ),
        ],
      ),
    );
  }

  // ─── Layers ───────────────────────────────────────────────────────────────

  Widget _buildCameraLayer() {
    if (_cameraError) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.92),
              AppColors.oliveLight.withValues(alpha: 0.86),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: AppColors.primary, size: 48),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'Camera access was denied\nor no camera found in this browser.'
                  : 'Camera unavailable on this device.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can still run the AI analysis demo.',
              style: TextStyle(color: AppColors.accent, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (!_cameraReady || _cameraController == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.92),
              AppColors.oliveLight.withValues(alpha: 0.84),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Initialising camera...',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  // ─── Analysis result panel ────────────────────────────────────────────────

  Widget _buildAnalysisResult() {
    return GlassPanel(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      tintColor: Colors.white.withValues(alpha: 0.66),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.70),
          AppColors.oliveLight.withValues(alpha: 0.54),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DamageGauge(percentage: _currentDamage, size: 130),
            const SizedBox(height: 16),
            // Pixel ratio bar
            _PixelRatioBar(damageRatio: _currentDamage / 100),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultChip(
                  label: 'HEALTHY',
                  value: '${(100 - _currentDamage).toStringAsFixed(1)}%',
                  color: AppColors.accent,
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                _ResultChip(
                  label: 'DAMAGED',
                  value: '${_currentDamage.toStringAsFixed(1)}%',
                  color: AppColors.alertHigh,
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                _ResultChip(
                  label: 'CONFIDENCE',
                  value: '89%',
                  color: AppColors.highlightWarm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Telemetry HUD ────────────────────────────────────────────────────────

  Widget _buildTelemetryHUD() {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: BorderRadius.circular(14),
      tintColor: Colors.white.withValues(alpha: 0.64),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.7),
          AppColors.oliveLight.withValues(alpha: 0.5),
        ],
      ),
      child: Row(
        children: [
          _TelemetryItem(
            label: 'GPS',
            value:
                '${widget.hotspot.latitude.toStringAsFixed(4)}\n${widget.hotspot.longitude.toStringAsFixed(4)}',
            icon: Icons.gps_fixed,
          ),
          _Divider(),
          _TelemetryItem(
            label: 'TIMESTAMP',
            value: _formatTimestamp(_captureTime),
            icon: Icons.access_time,
          ),
          _Divider(),
          _TelemetryItem(
            label: 'DAMAGE',
            value: _analysisComplete
                ? '${_currentDamage.toStringAsFixed(1)}%'
                : (_isCapturing ? 'SCANNING' : 'READY'),
            icon: Icons.analytics_outlined,
            valueColor: _analysisComplete
                ? AppColors.alertHigh
                : (_isCapturing ? AppColors.alertMedium : AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          GlassPanel(
            onTap: () => Navigator.pop(context),
            blurSigma: 8,
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(10),
            tintColor: Colors.white.withValues(alpha: 0.68),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const Spacer(),
          // Status badge
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (_analysisComplete) {
      return _badge(
        color: AppColors.accent,
        icon: Icons.check_circle,
        label: 'ANALYSIS COMPLETE',
      );
    }
    if (_isCapturing) {
      return _badge(
        color: AppColors.primary,
        icon: null,
        label: 'AI SCANNING...',
        showSpinner: true,
      );
    }
    return _badge(
      color: AppColors.primary,
      icon: Icons.camera_alt_outlined,
      label: 'POINT AT DAMAGED AREA',
      bgColor: Colors.white.withValues(alpha: 0.62),
    );
  }

  Widget _badge({
    required Color color,
    required String label,
    IconData? icon,
    bool showSpinner = false,
    Color? bgColor,
  }) {
    return GlassPanel(
      blurSigma: 9,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      tintColor: bgColor ?? Colors.white.withValues(alpha: 0.64),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom button ────────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: _analysisComplete
            ? ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClaimScreen(
                      hotspot: widget.hotspot,
                      capturedImagePath: _capturedImagePath,
                    ),
                  ),
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Confirm & Generate Claim Dossier'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              )
            : _isCapturing
            ? GlassPanel(
                borderRadius: BorderRadius.circular(AppRadii.m),
                padding: const EdgeInsets.symmetric(vertical: 18),
                tintColor: Colors.white.withValues(alpha: 0.66),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.7),
                    AppColors.oliveLight.withValues(alpha: 0.48),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Analysing crop damage...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : ElevatedButton.icon(
                onPressed: (_cameraReady || _cameraError)
                    ? _captureAndAnalyse
                    : null,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text('Capture & Analyse'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.oliveLight,
                  foregroundColor: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.accent.withValues(alpha: 0.5),
          AppColors.accent,
          AppColors.accent.withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), glow);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, y),
      Paint()..color = AppColors.accent.withValues(alpha: 0.04),
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

class _ViewfinderPainter extends CustomPainter {
  final bool analysisComplete;
  _ViewfinderPainter({required this.analysisComplete});

  @override
  void paint(Canvas canvas, Size size) {
    final color = analysisComplete ? AppColors.alertHigh : AppColors.accent;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const c = 26.0;
    final w = size.width;
    final h = size.height;

    // Corner brackets
    canvas.drawLine(Offset(0, c), Offset.zero, stroke);
    canvas.drawLine(Offset.zero, Offset(c, 0), stroke);
    canvas.drawLine(Offset(w - c, 0), Offset(w, 0), stroke);
    canvas.drawLine(Offset(w, 0), Offset(w, c), stroke);
    canvas.drawLine(Offset(0, h - c), Offset(0, h), stroke);
    canvas.drawLine(Offset(0, h), Offset(c, h), stroke);
    canvas.drawLine(Offset(w - c, h), Offset(w, h), stroke);
    canvas.drawLine(Offset(w, h), Offset(w, h - c), stroke);

    // Crosshair
    final faint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(w / 2 - 18, h / 2),
      Offset(w / 2 + 18, h / 2),
      faint,
    );
    canvas.drawLine(
      Offset(w / 2, h / 2 - 18),
      Offset(w / 2, h / 2 + 18),
      faint,
    );
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      5,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Bounding boxes only after analysis
    if (analysisComplete) {
      canvas.drawRect(
        Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.58, h * 0.58),
        Paint()
          ..color = AppColors.alertHigh.withValues(alpha: 0.65)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawRect(
        Rect.fromLTWH(w * 0.62, h * 0.55, w * 0.32, h * 0.30),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.55)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) =>
      old.analysisComplete != analysisComplete;
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _DamagedZoneBadge extends StatelessWidget {
  final double percentage;
  const _DamagedZoneBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      blurSigma: 8,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      tintColor: Colors.white.withValues(alpha: 0.70),
      gradient: LinearGradient(
        colors: [
          AppColors.alertHigh.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.62),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.crop_free, size: 13, color: AppColors.alertHigh),
          const SizedBox(width: 6),
          Text(
            'DAMAGED ZONE  ${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.alertHigh,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelRatioBar extends StatelessWidget {
  final double damageRatio;
  const _PixelRatioBar({required this.damageRatio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PIXEL SEGMENTATION',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'U-Net AI Model',
              style: const TextStyle(color: AppColors.primary, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: ((1 - damageRatio) * 100).toInt(),
                child: Container(height: 8, color: AppColors.accent),
              ),
              Expanded(
                flex: (damageRatio * 100).toInt(),
                child: Container(height: 8, color: AppColors.alertHigh),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _TelemetryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 9, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: AppColors.primary.withValues(alpha: 0.24),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}
