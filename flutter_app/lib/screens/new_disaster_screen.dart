import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:agrisentinel/l10n/app_localizations.dart';

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../services/disaster_event_service.dart';
import '../services/voice_to_text_service.dart';
import '../widgets/tutorial_wrapper.dart';
import 'hotspot_map_screen.dart';
import 'dart:math' as math;

class NewDisasterScreen extends StatefulWidget {
  final FarmerModel farmer;
  final FarmModel farm;
  /// When set, form is pre-filled and save updates this draft (same id, hotspots kept).
  final DisasterEventModel? existingDraft;

  const NewDisasterScreen({
    super.key,
    required this.farmer,
    required this.farm,
    this.existingDraft,
  });

  @override
  State<NewDisasterScreen> createState() => _NewDisasterScreenState();
}

class _NewDisasterScreenState extends State<NewDisasterScreen> {
  /// Incidents may only be reported for the rolling window ending now.
  static const _occurredWindow = Duration(days: 7);

  static const _baseTypes = <String>[
    'Wildlife Attack',
    'Flood',
    'Storm/Wind',
    'Drought',
    'Other',
  ];

  List<String> get _disasterTypeOptions {
    final t = widget.existingDraft?.disasterType;
    if (t != null && t.isNotEmpty && !_baseTypes.contains(t)) {
      return [..._baseTypes, t];
    }
    return _baseTypes;
  }

  final _eventService = DisasterEventService();
  final _voiceService = VoiceToTextService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _otherDisasterController =
      TextEditingController();
  final TextEditingController _cropAgeController = TextEditingController();
  String? _selectedType;
  DateTime _occurredAt = DateTime.now();
  bool? _isBearing;
  bool _saving = false;
  bool _listening = false;
  String _lastFinalVoiceText = '';

  @override
  void initState() {
    super.initState();
    final d = widget.existingDraft;
    if (d != null) {
      _descriptionController.text = d.farmerDescription;
      if (d.cropAgeYears != null) {
        _cropAgeController.text = d.cropAgeYears.toString();
      }
      _selectedType =
          d.disasterType.isNotEmpty ? d.disasterType : null;
      if ((d.otherDisasterDetail ?? '').isNotEmpty) {
        _otherDisasterController.text = d.otherDisasterDetail!;
      }
      _occurredAt = _clampOccurredAt(d.occurredAt);
      _isBearing = d.isBearing;
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _descriptionController.dispose();
    _otherDisasterController.dispose();
    _cropAgeController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceToText() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voice input works in the Android/iOS app. On web, type your description.',
          ),
        ),
      );
      return;
    }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice input unavailable: $e')));
    }
  }

  DateTime get _occurredMin => DateTime.now().subtract(_occurredWindow);
  DateTime get _occurredMax => DateTime.now();

  /// Keeps [t] inside [_occurredMin] … [_occurredMax] (past 7 days through now).
  DateTime _clampOccurredAt(DateTime t) {
    final min = _occurredMin;
    final max = _occurredMax;
    if (t.isBefore(min)) return min;
    if (t.isAfter(max)) return max;
    return t;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final minInstant = now.subtract(_occurredWindow);
    final firstDate = DateTime(minInstant.year, minInstant.month, minInstant.day);
    final lastDate = DateTime(now.year, now.month, now.day);

    var initialCal = DateTime(_occurredAt.year, _occurredAt.month, _occurredAt.day);
    if (initialCal.isBefore(firstDate)) initialCal = firstDate;
    if (initialCal.isAfter(lastDate)) initialCal = lastDate;

    final date = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialCal,
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
    if (!mounted) return;
    setState(() {
      _occurredAt = _clampOccurredAt(
        DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
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
    final otherDetail = _otherDisasterController.text.trim();
    if (_selectedType == 'Other' && otherDetail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please briefly describe what kind of disaster "Other" refers to.',
          ),
        ),
      );
      return;
    }
    if (_saving) return;
    final occurredAt = _clampOccurredAt(_occurredAt);
    setState(() {
      _occurredAt = occurredAt;
      _saving = true;
    });
    final cropAgeRaw = _cropAgeController.text.trim();
    final cropAge = cropAgeRaw.isEmpty ? null : int.tryParse(cropAgeRaw);
    final existing = widget.existingDraft;
    final DisasterEventModel event;
    final otherDisasterDetail =
        _selectedType == 'Other' ? otherDetail : null;
    if (existing != null) {
      event = existing.copyWith(
        disasterType: _selectedType!,
        otherDisasterDetail: otherDisasterDetail,
        farmerDescription: description,
        occurredAt: occurredAt,
        reportedAt: DateTime.now(),
        status: 'draft',
        cropAgeYears: cropAge,
        isBearing: _isBearing,
      );
    } else {
      event = DisasterEventModel(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        farmerUid: widget.farmer.uid,
        farmId: widget.farm.id,
        disasterType: _selectedType!,
        otherDisasterDetail: otherDisasterDetail,
        farmerDescription: description,
        occurredAt: occurredAt,
        reportedAt: DateTime.now(),
        status: 'draft',
        hotspots: const [],
        aiNarrative: null,
        totalTreesLost: 0,
        estimatedLossInr: 0,
        cropAgeYears: cropAge,
        isBearing: _isBearing,
      );
    }

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
    return TutorialWrapper(
      screenKey: 'new_disaster',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingDraft == null
                ? 'Report Damage'
                : AppLocalizations.of(context).editDraftReportTitle,
          ),
        ),
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
                        children: _disasterTypeOptions.map((type) {
                          final selected = _selectedType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: selected,
                              onSelected: (_) => setState(() {
                                if (_selectedType == type) return;
                                _selectedType = type;
                                if (type != 'Other') {
                                  _otherDisasterController.clear();
                                }
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedType == 'Other') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _otherDisasterController,
                        maxLines: 2,
                        maxLength: 160,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Describe the disaster type',
                          hintText: 'e.g. Hail, pest outbreak, machinery damage',
                          alignLabelWithHint: true,
                          counterText: '',
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('When did it happen?'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDateTime(_occurredAt)),
                          const SizedBox(height: 4),
                          Text(
                            'Past 7 days only (up to now).',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
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
                          tooltip: kIsWeb
                              ? 'Voice to text (mobile app only)'
                              : (_listening
                                  ? 'Stop voice input'
                                  : 'Voice to text'),
                          onPressed: _toggleVoiceToText,
                          icon: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.elasticOut,
                            builder: (context, double value, Widget? child) {
                              return Transform.rotate(
                                angle: value < 1.0
                                    ? 0.25 *
                                        (1 - value) *
                                        math.sin(value * 15)
                                    : 0,
                                child: child,
                              );
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOutBack,
                                  ),
                                  child: child,
                                );
                              },
                              child: Icon(
                                kIsWeb
                                    ? Icons.mic_none_outlined
                                    : (_listening
                                        ? Icons.mic
                                        : Icons.mic_none),
                                key: ValueKey<Object>(
                                  '${kIsWeb}_$_listening',
                                ),
                                color: kIsWeb
                                    ? Theme.of(context).disabledColor
                                    : (_listening
                                        ? Colors.red
                                        : Colors.green[700]),
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('${description.length} characters'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Crop details',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cropAgeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age of crop (years)',
                        hintText: 'e.g. 5',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Is the crop in bearing stage?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _BearingChip(
                          label: 'Bearing',
                          selected: _isBearing == true,
                          onTap: () => setState(
                            () => _isBearing = _isBearing == true ? null : true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _BearingChip(
                          label: 'Non-bearing',
                          selected: _isBearing == false,
                          onTap: () => setState(
                            () =>
                                _isBearing = _isBearing == false ? null : false,
                          ),
                        ),
                      ],
                    ),
                    if (_isBearing == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Tap one to select (optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
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

class _BearingChip extends StatelessWidget {
  const _BearingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
