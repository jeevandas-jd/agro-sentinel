import 'package:flutter/material.dart';

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
    if (editedUser == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final savedUser = await widget.profileService.updateProfile(
        user: widget.user,
        name: editedUser.name,
        region: editedUser.region,
      );
      await widget.onUserUpdated(savedUser);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        widget.user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.region,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FeatureCard(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Update your name and region',
                onTap: _editProfile,
              ),
              const SizedBox(height: 8),
              FeatureCard(
                icon: Icons.history,
                title: 'Recent activity',
                subtitle: 'Last verification synced 2 hours ago',
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
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
