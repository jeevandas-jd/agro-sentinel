import 'package:flutter/material.dart';
import '../models/hotspot.dart';
import '../theme/app_theme.dart';

class SatelliteMapWidget extends StatefulWidget {
  final List<Hotspot> hotspots;
  final VoidCallback? onHotspotTap;

  const SatelliteMapWidget({
    super.key,
    required this.hotspots,
    this.onHotspotTap,
  });

  @override
  State<SatelliteMapWidget> createState() => _SatelliteMapWidgetState();
}

class _SatelliteMapWidgetState extends State<SatelliteMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SatelliteMapPainter(
                    pulseValue: _pulseAnimation.value,
                    hotspots: widget.hotspots,
                  ),
                  child: const SizedBox(width: double.infinity, height: 220),
                );
              },
            ),
            Positioned(
              bottom: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkOverlay,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NDVI SATELLITE VIEW  •  PALAKKAD, KERALA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkOverlay,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SatelliteMapPainter extends CustomPainter {
  final double pulseValue;
  final List<Hotspot> hotspots;

  _SatelliteMapPainter({required this.pulseValue, required this.hotspots});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base: rich dark satellite terrain
    final bgPaint = Paint()..color = const Color(0xFF1A2E15);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Terrain gradient overlay
    final terrainGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1E3A18),
        const Color(0xFF243D1C),
        const Color(0xFF1A3414),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = terrainGradient,
    );

    // Farm field patches (varying health) — richer greens
    final fieldColors = [
      const Color(0xFF2A5224),
      const Color(0xFF2E6030),
      const Color(0xFF3A5A22),
      const Color(0xFF1E4018),
      const Color(0xFF324A28),
      const Color(0xFF264038),
      const Color(0xFF3E5A2C),
      const Color(0xFF224216),
    ];

    final fieldRects = [
      Rect.fromLTWH(w * 0.02, h * 0.05, w * 0.22, h * 0.28),
      Rect.fromLTWH(w * 0.26, h * 0.04, w * 0.18, h * 0.32),
      Rect.fromLTWH(w * 0.46, h * 0.06, w * 0.20, h * 0.24),
      Rect.fromLTWH(w * 0.68, h * 0.03, w * 0.28, h * 0.30),
      Rect.fromLTWH(w * 0.03, h * 0.38, w * 0.20, h * 0.26),
      Rect.fromLTWH(w * 0.25, h * 0.40, w * 0.24, h * 0.22),
      Rect.fromLTWH(w * 0.51, h * 0.36, w * 0.18, h * 0.30),
      Rect.fromLTWH(w * 0.71, h * 0.36, w * 0.26, h * 0.28),
      Rect.fromLTWH(w * 0.04, h * 0.68, w * 0.26, h * 0.28),
      Rect.fromLTWH(w * 0.32, h * 0.66, w * 0.22, h * 0.30),
      Rect.fromLTWH(w * 0.56, h * 0.70, w * 0.20, h * 0.26),
      Rect.fromLTWH(w * 0.78, h * 0.68, w * 0.18, h * 0.28),
    ];

    for (int i = 0; i < fieldRects.length; i++) {
      final color = fieldColors[i % fieldColors.length];
      final fieldPaint = Paint()..color = color;
      canvas.drawRect(fieldRects[i], fieldPaint);

      // Add crop rows texture
      final rowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;
      final rect = fieldRects[i];
      for (double y = rect.top + 6; y < rect.bottom; y += 6) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), rowPaint);
      }
    }

    // Damaged/brown patch near HS-001 position
    final damagedPaint = Paint()..color = const Color(0xFF3A2010);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.55, h * 0.38, w * 0.12, h * 0.18),
      damagedPaint,
    );

    // Water/stream feature
    final waterPaint = Paint()
      ..color = const Color(0xFF0D2030)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final waterPath = Path()
      ..moveTo(w * 0.0, h * 0.60)
      ..quadraticBezierTo(w * 0.3, h * 0.55, w * 0.5, h * 0.62)
      ..quadraticBezierTo(w * 0.7, h * 0.70, w * 1.0, h * 0.65);
    canvas.drawPath(waterPath, waterPaint);

    // Roads
    final roadPaint = Paint()
      ..color = const Color(0xFF1E2A1A)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, h * 0.35), Offset(w, h * 0.37), roadPaint);
    canvas.drawLine(Offset(w * 0.48, 0), Offset(w * 0.49, h), roadPaint);

    // Grid lines (like satellite image grid)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < w; x += w / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += h / 5) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // HS-001 — high severity (red), position at ~60%, 42%
    final hs1Center = Offset(w * 0.61, h * 0.42);
    _drawHotspot(
      canvas,
      hs1Center,
      AppColors.alertHigh,
      pulseValue,
      'HS-001',
      'HIGH',
    );

    // HS-002 — medium severity (orange), position at ~73%, 26%
    final hs2Center = Offset(w * 0.73, h * 0.26);
    _drawHotspot(
      canvas,
      hs2Center,
      AppColors.alertMedium,
      1.0 - pulseValue * 0.3,
      'HS-002',
      'MED',
    );

    // HS-003 — medium severity (orange), wind damage, position at ~20%, 70%
    final hs3Center = Offset(w * 0.20, h * 0.70);
    _drawHotspot(
      canvas,
      hs3Center,
      AppColors.alertMedium,
      0.7 + pulseValue * 0.2,
      'HS-003',
      'MED',
    );
    // Farmer location (blue pulsing dot)
    final farmerPos = Offset(w * 0.30, h * 0.60);
    _drawFarmerDot(canvas, farmerPos, pulseValue);

    // Compass rose (bottom-right corner)
    _drawCompassRose(canvas, Offset(w - 28, h - 28));
  }

  void _drawHotspot(
    Canvas canvas,
    Offset center,
    Color color,
    double pulse,
    String label,
    String severity,
  ) {
    // Outer pulse ring
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: 0.15 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 28 * pulse, pulsePaint);

    // Middle ring
    final midPaint = Paint()
      ..color = color.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 18, midPaint);

    // Core circle
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, corePaint);

    // Inner icon (!)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, iconPaint);

    // Label
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 14));
  }

  void _drawFarmerDot(Canvas canvas, Offset center, double pulse) {
    final outerPaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.2 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20 * pulse, outerPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8, ringPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, dotPaint);

    final innerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, innerDot);

    final textSpan = TextSpan(
      text: 'YOU',
      style: const TextStyle(
        color: Color(0xFF42A5F5),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 11));
  }

  void _drawCompassRose(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 14, paint);

    final nPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, Offset(center.dx, center.dy - 12), nPaint);

    final textSpan = TextSpan(
      text: 'N',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 7,
        fontWeight: FontWeight.w700,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - 22));
  }

  @override
  bool shouldRepaint(_SatelliteMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
