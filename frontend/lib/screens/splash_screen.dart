import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool standaloneMode;

  const SplashScreen({super.key, this.standaloneMode = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _topoController;
  late AnimationController _lineController;
  late AnimationController _textController;
  late AnimationController _btnController;

  late Animation<double> _topoFade;
  late Animation<double> _greenGlowScale;

  // Per-line slide-in animations
  late List<Animation<Offset>> _lineSlides;
  late List<Animation<double>> _lineFades;

  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();

    _topoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _topoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _topoController, curve: Curves.easeOut),
    );
    _greenGlowScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _topoController, curve: Curves.easeOut),
    );

    // 5 text lines with staggered intervals
    final lineCount = 5;
    _lineSlides = List.generate(lineCount, (i) {
      final start = (i * 0.15).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _lineController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
    _lineFades = List.generate(lineCount, (i) {
      final start = (i * 0.15).clamp(0.0, 1.0);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _lineController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _btnFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOut),
    );
    _btnSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _btnController, curve: Curves.easeOut));

    // Sequence: topo → lines → button → navigate
    _topoController.forward().then((_) {
      _lineController.forward().then((_) {
        _btnController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && !widget.standaloneMode) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, _) =>
                      const DashboardScreen(),
                  transitionsBuilder: (context, animation, _, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 700),
                ),
              );
            }
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _topoController.dispose();
    _lineController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Topographic contour background
          AnimatedBuilder(
            animation: _topoFade,
            builder: (context, child) => Opacity(
              opacity: _topoFade.value,
              child: CustomPaint(
                painter: _TopoPainter(),
                size: Size(size.width, size.height * 0.65),
              ),
            ),
          ),

          // Green glow blob top right
          AnimatedBuilder(
            animation: _greenGlowScale,
            builder: (context, child) => Positioned(
              top: size.height * 0.08,
              right: -size.width * 0.12,
              child: Transform.scale(
                scale: _greenGlowScale.value,
                child: Container(
                  width: size.width * 0.55,
                  height: size.width * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryLight.withValues(alpha: 0.50),
                        AppColors.primaryLight.withValues(alpha: 0.20),
                        AppColors.primaryLight.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x6,
                vertical: AppSpacing.x4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),

                  // Stacked bold headline lines
                  _animatedLine(
                    0,
                    Text(
                      'VERIFY',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _animatedLine(
                    1,
                    _SatelliteBadge(),
                  ),
                  const SizedBox(height: 4),
                  _animatedLine(
                    2,
                    Text(
                      'DAMAGE',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _animatedLine(
                    3,
                    Text(
                      'WITH',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _animatedLine(
                    4,
                    Row(
                      children: [
                        Text(
                          '——',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SATELLITE AI',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // CTA Button row
                  AnimatedBuilder(
                    animation: _btnController,
                    builder: (context, child) => FadeTransition(
                      opacity: _btnFade,
                      child: SlideTransition(
                        position: _btnSlide,
                        child: child,
                      ),
                    ),
                    child: _buildCtaRow(),
                  ),

                  const SizedBox(height: AppSpacing.x6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedLine(int index, Widget child) {
    return AnimatedBuilder(
      animation: _lineController,
      builder: (context, _) => FadeTransition(
        opacity: _lineFades[index],
        child: SlideTransition(
          position: _lineSlides[index],
          child: child,
        ),
      ),
    );
  }

  Widget _buildCtaRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!widget.standaloneMode) {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, _) =>
                        const DashboardScreen(),
                    transitionsBuilder: (context, animation, _, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                );
              }
            },
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: AppShadows.raised,
              ),
              child: const Center(
                child: Text(
                  'START VERIFICATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.base,
          ),
          child: const Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }
}

// "SATELLITE" badge widget
class _SatelliteBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      child: const Text(
        'SATELLITE',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          height: 1.0,
        ),
      ),
    );
  }
}

// Topographic contour lines painter
class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderStrong.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final greenPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw topographic contour-like curved lines
    final random = math.Random(42);
    final curves = 18;

    for (int i = 0; i < curves; i++) {
      final path = Path();
      final yBase = size.height * (i / curves);
      final amplitude = 20.0 + random.nextDouble() * 30;
      final freq = 0.6 + random.nextDouble() * 0.8;

      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 4) {
        final y = yBase +
            amplitude * math.sin((x / size.width) * math.pi * freq * 2 +
                i * 0.3);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    // Draw an oval "lake" shape with green fill (top right area)
    final center = Offset(size.width * 0.72, size.height * 0.30);
    final ovalPath = Path();
    for (int ring = 3; ring >= 0; ring--) {
      final rx = 55.0 + ring * 22;
      final ry = 38.0 + ring * 16;
      ovalPath.addOval(Rect.fromCenter(
        center: center,
        width: rx * 2,
        height: ry * 2,
      ));
    }
    canvas.drawPath(ovalPath, greenPaint);

    // Oval borders
    for (int ring = 0; ring < 4; ring++) {
      final rx = 55.0 + ring * 22;
      final ry = 38.0 + ring * 16;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
        paint
          ..color =
              AppColors.primary.withValues(alpha: 0.2 - ring * 0.04),
      );
    }

    // Reset paint color
    paint.color = AppColors.borderStrong.withValues(alpha: 0.4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
