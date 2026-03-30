import 'package:flutter/material.dart';

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../theme/app_theme.dart';
import 'dossier_submit_screen.dart';

class DossierReviewScreen extends StatefulWidget {
  final FarmModel farm;
  final FarmerModel farmer;
  final DisasterEventModel event;

  const DossierReviewScreen({
    super.key,
    required this.farm,
    required this.farmer,
    required this.event,
  });

  @override
  State<DossierReviewScreen> createState() => _DossierReviewScreenState();
}

class _DossierReviewScreenState extends State<DossierReviewScreen> {
  late String _farmerDescription;

  @override
  void initState() {
    super.initState();
    _farmerDescription = widget.event.farmerDescription;
  }

  Future<void> _editDescription() async {
    final controller = TextEditingController(text: _farmerDescription);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit description'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Describe the damage details',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) {
      return;
    }
    setState(() => _farmerDescription = value);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event.copyWith(farmerDescription: _farmerDescription);
    final hotspots = event.hotspots;
    final damaged = hotspots
        .where((hotspot) => (hotspot.aiResult ?? '').toUpperCase() == 'DAMAGED')
        .length;
    final treesLost = hotspots.fold<int>(0, (sum, hotspot) => sum + hotspot.treesLost);
    final estimatedLoss = treesLost * 2500;

    return Scaffold(
      appBar: AppBar(title: const Text('Damage Report Preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Farm details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.farm.name),
                Text('Crop: ${widget.farm.cropType}'),
                Text('Area: ${widget.farm.areaHectares.toStringAsFixed(1)} ha'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Disaster details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${event.disasterType}'),
                Text('When: ${_formatDate(event.occurredAt)}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Hotspot summary',
            child: Column(
              children: hotspots
                  .map(
                    (hotspot) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(hotspot.id)),
                      title: Text(hotspot.aiResult ?? 'PENDING'),
                      subtitle:
                          Text('Confidence ${(hotspot.aiConfidence ?? 0) * 100}%'),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Total damage summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total hotspots marked: ${hotspots.length}'),
                Text('Damaged areas: $damaged'),
                Text('Estimated trees lost: $treesLost'),
                Text('Estimated loss: \u20B9$estimatedLoss'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'AI narrative',
            child: Text(
              event.aiNarrative ??
                  'AI narrative will be generated once report is submitted.',
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Farmer description',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_farmerDescription),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _editDescription,
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DossierSubmitScreen(),
                ),
              );
            },
            child: const Text('Generate PDF Report'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
