import 'package:flutter/material.dart';
import '../models/farmer.dart';
import '../models/hotspot.dart';
import '../services/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/hotspot_card.dart';
import '../widgets/satellite_map_widget.dart';
import 'navigation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late List<Animation<double>> _sectionFades;
  late List<Animation<Offset>> _sectionSlides;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // 4 staggered sections
    const n = 4;
    _sectionFades = List.generate(n, (i) {
      final start = (i * 0.18).clamp(0.0, 1.0);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _sectionSlides = List.generate(n, (i) {
      final start = (i * 0.18).clamp(0.0, 1.0);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _openHotspot(Hotspot hotspot) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            NavigationScreen(hotspot: hotspot),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  Widget _section(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, _) => FadeTransition(
        opacity: _sectionFades[index],
        child: SlideTransition(
          position: _sectionSlides[index],
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmer = DemoData.farmer;
    final hotspots = DemoData.hotspots;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _section(0, _buildHeader(farmer)),
            ),

            // Active hotspots horizontal scroll
            SliverToBoxAdapter(
              child: _section(1, _buildHotspotsSection(hotspots)),
            ),

            // Satellite damage map card
            SliverToBoxAdapter(
              child: _section(
                2,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildSatelliteMapCard(hotspots),
                ),
              ),
            ),

            // Pending verifications list header
            SliverToBoxAdapter(
              child: _section(
                3,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      const Text(
                        'PENDING VERIFICATIONS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.alertHigh.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(
                            color: AppColors.alertHigh.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${hotspots.length} ACTIVE',
                          style: const TextStyle(
                            color: AppColors.alertHigh,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Hotspot verification cards
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + index * 100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: HotspotCard(
                      hotspot: hotspots[index],
                      onTap: () => _openHotspot(hotspots[index]),
                    ),
                  ),
                ),
                childCount: hotspots.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Farmer farmer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WELCOME BACK,',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  farmer.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      farmer.region,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quick stats row
                Row(
                  children: [
                    _QuickStat(
                      label: 'Alerts',
                      value: '${farmer.activeAlerts}',
                      color: AppColors.alertHigh,
                    ),
                    const SizedBox(width: 12),
                    _QuickStat(
                      label: 'Claims',
                      value: '${farmer.pendingClaims}',
                      color: AppColors.alertMedium,
                    ),
                    const SizedBox(width: 12),
                    _QuickStat(
                      label: 'Plots',
                      value: '${farmer.farmPlots}',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2.5,
              ),
              boxShadow: AppShadows.raised,
            ),
            child: Center(
              child: Text(
                farmer.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotsSection(List<Hotspot> hotspots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'ACTIVE HOTSPOTS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hotspots.length + 1,
            itemBuilder: (context, index) {
              if (index == hotspots.length) {
                return const SizedBox(width: 8);
              }
              final h = hotspots[index];
              return _HotspotMiniCard(hotspot: h, onTap: () => _openHotspot(h));
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSatelliteMapCard(List<Hotspot> hotspots) {
    return GestureDetector(
      onTap: () => _openHotspot(hotspots.first),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.l),
          boxShadow: AppShadows.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x5),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SATELLITE DAMAGE\nDETECTION MAP',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'NDVI analysis via Planet NICFI — tap to navigate to hotspot.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.raised,
                    ),
                    child: const Icon(
                      Icons.satellite_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Map preview
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadii.l),
                bottomRight: Radius.circular(AppRadii.l),
              ),
              child: SizedBox(
                height: 180,
                child: SatelliteMapWidget(
                  hotspots: hotspots,
                  onHotspotTap: () => _openHotspot(hotspots.first),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Inline quick stat for header
class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' $label',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Horizontal hotspot mini card
class _HotspotMiniCard extends StatelessWidget {
  final Hotspot hotspot;
  final VoidCallback onTap;

  const _HotspotMiniCard({required this.hotspot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.l),
          boxShadow: AppShadows.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aerial image placeholder with severity colour
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadii.l),
                  topRight: Radius.circular(AppRadii.l),
                ),
                child: Container(
                  color: AppColors.accentSoft,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4A7C3F),
                              Color(0xFF6A9B5E),
                              Color(0xFF3D6B32),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      CustomPaint(painter: _FieldPatternPainter()),
                      // Damage patch
                      Positioned(
                        right: 12,
                        top: 14,
                        child: Container(
                          width: 30,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B3B12)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: hotspot.severityColor
                                  .withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Severity badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: hotspot.severityColor
                                .withValues(alpha: 0.9),
                            borderRadius:
                                BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            hotspot.severity.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotspot.cropType,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'NDVI ${hotspot.ndviScore.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.alertHigh,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
