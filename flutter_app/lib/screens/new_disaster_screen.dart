import 'package:flutter/material.dart';

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../services/disaster_event_service.dart';
import '../services/voice_to_text_service.dart';
import 'hotspot_map_screen.dart';

class NewDisasterScreen extends StatefulWidget {
  final FarmerModel farmer;
  final FarmModel farm;

  const NewDisasterScreen({
    super.key,
    required this.farmer,
    required this.farm,
  });

  @override
  State<NewDisasterScreen> createState() => _NewDisasterScreenState();
}

class _NewDisasterScreenState extends State<NewDisasterScreen> {
  static const _types = <String>[
    'Wildlife Attack',
    'Flood',
    'Storm/Wind',
    'Drought',
    'Other',
  ];

  final _eventService = DisasterEventService();
  final _voiceService = VoiceToTextService();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  DateTime _occurredAt = DateTime.now();
  bool _saving = false;
  bool _listening = false;
  String _lastFinalVoiceText = '';

  @override
  void dispose() {
    _voiceService.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceToText() async {
    if (_listening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }

    try {
      await _voiceService.startListening(
        onResult: (result) {
          if (!mounted) return;
          // Speech recognition fires partial results repeatedly. Only append the
          // finalized transcript once to avoid duplicated phrases.
          if (!result.isFinal) return;

          final text = result.text;
          if (text == _lastFinalVoiceText) return;
          _lastFinalVoiceText = text;

          final existing = _descriptionController.text.trimRight();
          final next = existing.isEmpty ? text : '$existing $text';
          _descriptionController.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
          setState(() {});
        },
      );
      if (mounted) setState(() => _listening = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _listening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice input unavailable: $e')),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDate: _occurredAt,
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _continue() async {
    final description = _descriptionController.text.trim();
    if (_selectedType == null || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select disaster type and add description.'),
        ),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final event = DisasterEventModel(
      id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
      farmerUid: widget.farmer.uid,
      farmId: widget.farm.id,
      disasterType: _selectedType!,
      farmerDescription: description,
      occurredAt: _occurredAt,
      reportedAt: DateTime.now(),
      status: 'draft',
      hotspots: const [],
      aiNarrative: null,
      totalTreesLost: 0,
      estimatedLossInr: 0,
    );

    try {
      final savedId = await _eventService.saveEvent(event);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HotspotMapScreen(
            farm: widget.farm,
            farmer: widget.farmer,
            initialEvent: event.copyWith(id: savedId),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report draft: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = _descriptionController.text;
    return Scaffold(
      appBar: AppBar(title: const Text('Report Damage')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Disaster type',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _types.map((type) {
                        final selected = _selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedType = type),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('When did it happen?'),
                    subtitle: Text(_formatDateTime(_occurredAt)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Describe what happened',
                      hintText:
                          'e.g. Wild elephants destroyed the northern section last night',
                      alignLabelWithHint: true,
                      suffixIcon: IconButton(
                        tooltip: _listening ? 'Stop voice input' : 'Voice to text',
                        onPressed: _toggleVoiceToText,
                        icon: Icon(
                          _listening ? Icons.mic : Icons.mic_none,
                          color: _listening ? Colors.red : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${description.length} characters'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _continue,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue to Map'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year} $hh:$min';
  }
}
