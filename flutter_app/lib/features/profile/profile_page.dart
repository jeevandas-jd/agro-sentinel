import 'package:flutter/material.dart';

import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feature_card.dart';
import '../auth/auth_models.dart';
import 'edit_profile_page.dart';
import 'profile_service.dart';

class ProfilePage extends StatefulWidget {
  final DemoUser user;
  final ProfileService profileService;
  final Future<void> Function(DemoUser user) onUserUpdated;
  final Future<void> Function() onLogout;

  const ProfilePage({
    super.key,
    required this.user,
    required this.profileService,
    required this.onUserUpdated,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSaving = false;

  Future<void> _editProfile() async {
    final editedUser = await Navigator.of(context).push<DemoUser>(
      MaterialPageRoute(builder: (_) => EditProfilePage(user: widget.user)),
    );
    if (editedUser == null) return;

    setState(() => _isSaving = true);
    try {
      final savedUser = await widget.profileService.updateProfile(
        user: widget.user,
        name: editedUser.name,
        region: editedUser.region,
      );
      await widget.onUserUpdated(savedUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmer = DemoData.farmer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Farmer Profile')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.l),
                  boxShadow: AppShadows.raised,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.user.region,
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${farmer.farmerId}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Farm stats
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'FARM STATISTICS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  _FarmStat(
                    icon: Icons.landscape_outlined,
                    label: 'Farm Plots',
                    value: '${farmer.farmPlots}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  _FarmStat(
                    icon: Icons.crop_free,
                    label: 'Total Area',
                    value: '${farmer.totalHectares} ha',
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _FarmStat(
                    icon: Icons.satellite_alt,
                    label: 'Active Alerts',
                    value: '${farmer.activeAlerts}',
                    color: AppColors.alertHigh,
                  ),
                  const SizedBox(width: 10),
                  _FarmStat(
                    icon: Icons.assignment_outlined,
                    label: 'Pending Claims',
                    value: '${farmer.pendingClaims}',
                    color: AppColors.alertMedium,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Actions
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'ACCOUNT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              FeatureCard(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your name and region',
                onTap: _editProfile,
              ),
              const SizedBox(height: 8),
              FeatureCard(
                icon: Icons.check_circle_outline,
                title: 'Verification History',
                subtitle:
                    '${farmer.activeAlerts} active alerts  •  ${farmer.pendingClaims} pending claims',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.alertHigh,
                    side: const BorderSide(color: AppColors.alertHigh),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (_isSaving)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55080E08),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _FarmStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FarmStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
