import 'package:flutter/material.dart';

import '../features/auth/auth_service.dart';
import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../theme/app_theme.dart';
import 'farm_map_screen.dart';
import 'new_disaster_screen.dart';

class HomeScreen extends StatelessWidget {
  final FarmerModel farmer;
  final FarmModel farm;
  final List<DisasterEventModel> events;
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.farmer,
    required this.farm,
    required this.events,
    required this.authService,
  });

  Future<void> _logout(BuildContext context) async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agro Sentinel'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            farmer.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            farm.name,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            title: 'View My Farm',
            subtitle: 'Open farm boundary and hotspots',
            icon: Icons.map_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FarmMapScreen(
                    farm: farm,
                    event: events.isEmpty ? null : events.first,
                    farmer: farmer,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: 'Report Disaster',
            subtitle: 'Start a new damage report',
            icon: Icons.warning_amber_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewDisasterScreen(
                    farmer: farmer,
                    farm: farm,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Disaster Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...events.map(
            (event) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(event.disasterType),
                subtitle: Text(_formatDate(event.occurredAt)),
                trailing: _StatusBadge(status: event.status),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NewDisasterScreen(
                farmer: farmer,
                farm: farm,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final label = switch (normalized) {
      'submitted' => 'Submitted',
      'verified' => 'Verified',
      _ => 'Draft',
    };
    final color = switch (normalized) {
      'submitted' => AppColors.alertMedium,
      'verified' => AppColors.alertVerified,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
