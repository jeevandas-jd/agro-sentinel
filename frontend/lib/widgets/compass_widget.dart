import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CompassWidget extends StatefulWidget {
  final double bearing;
  final double distanceMeters;

  const CompassWidget({
    super.key,
    required this.bearing,
    required this.distanceMeters,
  });

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _wobbleAnimation = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wobbleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _CompassPainter(
            bearing: widget.bearing + _wobbleAnimation.value,
            distanceMeters: widget.distanceMeters,
          ),
          size: const Size(220, 220),
        );
      },
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double bearing;
  final double distanceMeters;

  _CompassPainter({required this.bearing, required this.distanceMeters});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Outer glow ring
    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 6, glowPaint);

    // Outer ring
    final outerRingPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerRingPaint);

    // Background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF152015),
          const Color(0xFF0A120A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 1, bgPaint);

    // Tick marks
    for (int i = 0; i < 72; i++) {
      final angle = (i * 5) * math.pi / 180;
      final isMajor = i % 9 == 0;
      final tickLength = isMajor ? 14.0 : 7.0;
      final innerR = radius - tickLength - 4;
      final outerR = radius - 4;

      final tickPaint = Paint()
        ..color = isMajor
            ? AppColors.textSecondary.withValues(alpha: 0.7)
            : AppColors.border
        ..strokeWidth = isMajor ? 1.5 : 0.8;

      canvas.drawLine(
        Offset(
          center.dx + innerR * math.sin(angle),
          center.dy - innerR * math.cos(angle),
        ),
        Offset(
          center.dx + outerR * math.sin(angle),
          center.dy - outerR * math.cos(angle),
        ),
        tickPaint,
      );
    }

    // Cardinal direction labels
    final cardinals = {
      'N': 0.0,
      'E': math.pi / 2,
      'S': math.pi,
      'W': 3 * math.pi / 2,
    };
    for (final entry in cardinals.entries) {
      final labelR = radius - 28;
      final angle = entry.value;
      final pos = Offset(
        center.dx + labelR * math.sin(angle),
        center.dy - labelR * math.cos(angle),
      );
      final isNorth = entry.key == 'N';
      final textSpan = TextSpan(
        text: entry.key,
        style: TextStyle(
          color: isNorth ? AppColors.alertHigh : AppColors.textSecondary,
          fontSize: isNorth ? 14 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // Needle group — rotated to bearing
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(bearing);

    final needleLength = radius - 48;

    // Target-pointing needle (green — toward hotspot)
    final greenNeedle = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(8, 0)
      ..lineTo(0, needleLength * 0.3)
      ..lineTo(-8, 0)
      ..close();
    canvas.drawPath(greenPath, greenNeedle);

    // Tail needle (red)
    final redNeedle = Paint()
      ..color = AppColors.alertHigh.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(0, needleLength * 0.35)
      ..lineTo(5, 0)
      ..lineTo(0, needleLength * 0.3)
      ..lineTo(-5, 0)
      ..close();
    canvas.drawPath(redPath, redNeedle);

    canvas.restore();

    // Center hub
    final hubPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14, hubPaint);
    final hubRingPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 14, hubRingPaint);

    // Target icon in center
    final crossPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx - 6, center.dy),
      Offset(center.dx + 6, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 6),
      Offset(center.dx, center.dy + 6),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) {
    return oldDelegate.bearing != bearing;
  }
}
