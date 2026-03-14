import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/hotspot.dart';
import '../theme/app_theme.dart';
import '../widgets/damage_gauge.dart';
import 'claim_screen.dart';

class CameraScreen extends StatefulWidget {
  final Hotspot hotspot;

  const CameraScreen({super.key, required this.hotspot});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _resultController;
  late AnimationController _damageController;
  late Animation<double> _scanLine;
  late Animation<double> _resultFade;
  late Animation<double> _damageAnimation;

  bool _analysisComplete = false;
  double _currentDamage = 0.0;
  static const double _targetDamage = 67.4;
  DateTime _captureTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _captureTime = DateTime.now();

    // Scan line animation (looping)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scanLine = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    // Results fade in
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );

    // Damage counter animation
    _damageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _damageAnimation = Tween<double>(begin: 0.0, end: _targetDamage).animate(
      CurvedAnimation(parent: _damageController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _currentDamage = _damageAnimation.value);
      });

    // After 3 seconds of scanning, show results
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      _scanController.stop();
      setState(() => _analysisComplete = true);
      _resultController.forward();
      _damageController.forward();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _resultController.dispose();
    _damageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  $h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated camera background
          _buildCameraBackground(),

          // Scan overlay
          if (!_analysisComplete) _buildScanOverlay(),

          // Viewfinder frame
          _buildViewfinder(),

          // Results overlay
          if (_analysisComplete)
            FadeTransition(
              opacity: _resultFade,
              child: _buildResultsOverlay(),
            ),

          // Telemetry HUD (always visible)
          _buildTelemetryHUD(),

          // Top bar
          _buildTopBar(),

          // Bottom action bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCameraBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF080D08),
            Color(0xFF0A1A0A),
            Color(0xFF050E05),
            Color(0xFF0D1508),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _FieldTexturePainter(),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: _scanLine,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(progress: _scanLine.value),
        );
      },
    );
  }

  Widget _buildViewfinder() {
    return Center(
      child: SizedBox(
        width: 240,
        height: 200,
        child: CustomPaint(
          painter: _ViewfinderPainter(analysisComplete: _analysisComplete),
        ),
      ),
    );
  }

  Widget _buildResultsOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bounding box label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.alertHigh.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.crop_free, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'DAMAGED ZONE  ${_currentDamage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 160),

          // Damage gauge
          DamageGauge(percentage: _currentDamage, size: 120),
        ],
      ),
    );
  }

  Widget _buildTelemetryHUD() {
    return Positioned(
      left: 16,
      bottom: 110,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _TelemetryItem(
              label: 'GPS',
              value: '${widget.hotspot.latitude.toStringAsFixed(4)}\n${widget.hotspot.longitude.toStringAsFixed(4)}',
              icon: Icons.gps_fixed,
            ),
            _VerticalDivider(),
            _TelemetryItem(
              label: 'TIMESTAMP',
              value: _formatTimestamp(_captureTime),
              icon: Icons.access_time,
            ),
            _VerticalDivider(),
            _TelemetryItem(
              label: 'DAMAGE',
              value: _analysisComplete
                  ? '${_currentDamage.toStringAsFixed(1)}%'
                  : 'SCANNING...',
              icon: Icons.analytics_outlined,
              valueColor: _analysisComplete
                  ? AppColors.alertHigh
                  : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const Spacer(),
              if (!_analysisComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'AI SCANNING...',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_analysisComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 12, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'ANALYSIS COMPLETE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analysisComplete
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClaimScreen(hotspot: widget.hotspot),
                        ),
                      );
                    }
                  : null,
              icon: Icon(
                _analysisComplete
                    ? Icons.description_outlined
                    : Icons.hourglass_top,
                size: 18,
              ),
              label: Text(
                _analysisComplete
                    ? 'Confirm & Generate Claim Dossier'
                    : 'Analysing crop damage...',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: _analysisComplete
                    ? AppColors.accent
                    : Colors.black.withValues(alpha: 0.5),
                foregroundColor: _analysisComplete
                    ? Colors.white
                    : AppColors.textMuted,
                side: _analysisComplete
                    ? null
                    : BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final patches = [
      const Color(0xFF0A1A0A),
      const Color(0xFF0C1E0C),
      const Color(0xFF091508),
      const Color(0xFF0E1E0A),
    ];
    for (int i = 0; i < 20; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final w = 30.0 + rng.nextDouble() * 80;
      final h = 20.0 + rng.nextDouble() * 60;
      final paint = Paint()
        ..color = patches[rng.nextInt(patches.length)];
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }
    // Row lines like crop rows
    final rowPaint = Paint()
      ..color = const Color(0xFF0F200F)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rowPaint);
    }
  }

  @override
  bool shouldRepaint(_FieldTexturePainter old) => false;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;

  _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;

    // Glow line
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.accent.withValues(alpha: 0.6),
          AppColors.accent,
          AppColors.accent.withValues(alpha: 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);

    // Scan area tint above line
    final tintPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.04);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, y), tintPaint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

class _ViewfinderPainter extends CustomPainter {
  final bool analysisComplete;

  _ViewfinderPainter({required this.analysisComplete});

  @override
  void paint(Canvas canvas, Size size) {
    final color =
        analysisComplete ? AppColors.alertHigh : AppColors.accent;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLen = 24.0;
    final w = size.width;
    final h = size.height;

    // Top-left corner
    canvas.drawLine(Offset(0, cornerLen), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerLen, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - cornerLen, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLen), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - cornerLen), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(cornerLen, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - cornerLen, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLen), paint);

    // Center crosshair
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(w / 2 - 15, h / 2),
      Offset(w / 2 + 15, h / 2),
      crossPaint,
    );
    canvas.drawLine(
      Offset(w / 2, h / 2 - 15),
      Offset(w / 2, h / 2 + 15),
      crossPaint,
    );
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      4,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Bounding box if analysis complete
    if (analysisComplete) {
      final boxPaint = Paint()
        ..color = AppColors.alertHigh.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
        Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.55, h * 0.55),
        boxPaint,
      );
      final healthPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
        Rect.fromLTWH(w * 0.62, h * 0.55, w * 0.32, h * 0.30),
        healthPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) =>
      old.analysisComplete != analysisComplete;
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
              Icon(icon, size: 10, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
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
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}
