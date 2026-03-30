import 'package:flutter/material.dart';

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
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

  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  DateTime _occurredAt = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  void _continue() {
    final description = _descriptionController.text.trim();
    if (_selectedType == null || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select disaster type and add description.'),
        ),
      );
      return;
    }
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HotspotMapScreen(
          farm: widget.farm,
          farmer: widget.farmer,
          initialEvent: event,
        ),
      ),
    );
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
                    decoration: const InputDecoration(
                      labelText: 'Describe what happened',
                      hintText:
                          'e.g. Wild elephants destroyed the northern section last night',
                      alignLabelWithHint: true,
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
                  onPressed: _continue,
                  child: const Text('Continue to Map'),
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
