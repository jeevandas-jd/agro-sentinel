import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DamageGauge extends StatelessWidget {
  final double percentage;
  final double size;
  final bool showLabel;

  const DamageGauge({
    super.key,
    required this.percentage,
    this.size = 140,
    this.showLabel = true,
  });

  Color get _gaugeColor {
    if (percentage < 30) return AppColors.accent;
    if (percentage < 60) return AppColors.alertMedium;
    return AppColors.alertHigh;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DamageGaugePainter(
          percentage: percentage,
          gaugeColor: _gaugeColor,
        ),
        child: showLabel
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _gaugeColor,
                        fontSize: size * 0.18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'DAMAGE',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: size * 0.09,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _DamageGaugePainter extends CustomPainter {
  final double percentage;
  final Color gaugeColor;

  _DamageGaugePainter({required this.percentage, required this.gaugeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 3 * math.pi / 4;
    const sweepAngle = 3 * math.pi / 2;

    // Track (background arc)
    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Filled arc
    final filledSweep = sweepAngle * (percentage / 100);
    final gaugePaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          AppColors.accent,
          AppColors.alertMedium,
          AppColors.alertHigh,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      filledSweep,
      false,
      gaugePaint,
    );

    // Glow at tip
    final tipAngle = startAngle + filledSweep;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    final glowPaint = Paint()
      ..color = gaugeColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(tipX, tipY), 8, glowPaint);
  }

  @override
  bool shouldRepaint(_DamageGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
