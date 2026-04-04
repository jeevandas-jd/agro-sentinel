import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/dart_define_config.dart';
import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../services/ai_narrative_service.dart';
import '../theme/app_theme.dart';
import 'dossier_submit_screen.dart';
import '../widgets/tutorial_wrapper.dart';

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
  /// Short 2-3 sentence summary shown in the preview card.
  String? _previewNarrative;
  /// Full report narrative sent to the PDF.
  String? _reportNarrative;
  bool _narrativeLoading = false;
  bool _geminiKeyAvailable = false;

  @override
  void initState() {
    super.initState();
    _farmerDescription = widget.event.farmerDescription;
    _previewNarrative = widget.event.aiNarrativeShort;
    _reportNarrative = widget.event.aiNarrative;
    // Avoid flashing the map-step template: we resolve the key first, then either
    // always call Gemini (key present) or keep/show template (no key).
    _narrativeLoading = true;

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final key = await loadGeminiApiKey();
      if (!mounted) return;
      setState(() => _geminiKeyAvailable = key.isNotEmpty);

      if (key.isNotEmpty) {
        // Event may already carry a fallback template from HotspotMapScreen; refresh.
        await _loadPreviewNarrative();
      } else {
        final missing =
            _previewNarrative == null || _previewNarrative!.trim().isEmpty;
        if (missing) {
          await _loadPreviewNarrative();
        } else if (mounted) {
          setState(() => _narrativeLoading = false);
        }
      }
    });
  }

  Future<void> _loadPreviewNarrative() async {
    if (!mounted) return;
    setState(() => _narrativeLoading = true);
    final event =
        widget.event.copyWith(farmerDescription: _farmerDescription);
    final result =
        await narrativeServiceWithOptionalGemini().generateNarrative(event);
    if (!mounted) return;
    setState(() {
      _previewNarrative = result.preview;
      _reportNarrative = result.report;
      _narrativeLoading = false;
    });
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
    unawaited(_loadPreviewNarrative());
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event.copyWith(farmerDescription: _farmerDescription);
    final hotspots = event.hotspots;
    final damaged = hotspots
        .where((hotspot) => (hotspot.aiResult ?? '').toUpperCase() == 'DAMAGED')
        .length;
    final treesLost = hotspots.fold<int>(
      0,
      (sum, hotspot) => sum + hotspot.treesLost,
    );
    final estimatedLoss = treesLost * 2500;

    return TutorialWrapper(
      screenKey: 'dossiers_review',
      child: Scaffold(
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
                if (event.cropAgeYears != null)
                  Text('Crop age: ${event.cropAgeYears} year(s)'),
                if (event.isBearing != null)
                  Text(
                    'Bearing: ${event.isBearing! ? 'Yes (bearing)' : 'No (non-bearing)'}',
                  ),
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
                      subtitle: Text(
                        'Confidence ${(hotspot.aiConfidence ?? 0) * 100}%',
                      ),
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
            title: 'AI Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_narrativeLoading)
                  const LinearProgressIndicator()
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      _previewNarrative ??
                          event.aiNarrativeShort ??
                          event.aiNarrative ??
                          'Summary not available.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                            fontSize: 15,
                          ),
                    ),
                  ),
                if (!_narrativeLoading) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Full assessment report will be included in the PDF.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (!_geminiKeyAvailable)
                    Text(
                      'Template summary only. Add GEMINI_API_KEY to '
                      'android/local.properties and rebuild the app.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => unawaited(_loadPreviewNarrative()),
                      child: const Text('Regenerate'),
                    ),
                  ),
                ],
              ],
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
              // Pass the full report narrative to the PDF; fall back through
              // short preview → persisted aiNarrative if report not yet loaded.
              final narrativeForPdf = _reportNarrative?.isNotEmpty == true
                  ? _reportNarrative!
                  : (_previewNarrative ?? event.aiNarrative ?? '');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DossierSubmitScreen(
                    farm: widget.farm,
                    farmer: widget.farmer,
                    event: event,
                    narrativeText: narrativeForPdf,
                  ),
                ),
              );
            },
            child: const Text('Generate PDF Report'),
          ),
        ],
        ),
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
