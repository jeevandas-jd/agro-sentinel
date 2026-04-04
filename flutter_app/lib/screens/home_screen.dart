import 'dart:async';

import 'package:flutter/material.dart';
import 'package:agrisentinel/l10n/app_localizations.dart';

import '../features/auth/auth_service.dart';
import '../widgets/language_picker_sheet.dart';
import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../services/damage_preview_pdf_service.dart';
import '../services/disaster_event_service.dart';
import '../services/farm_service.dart';
import '../services/report_media_storage.dart';
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tutorial_wrapper.dart';
import 'add_farm_screen.dart';
import 'farm_map_screen.dart';
import 'new_disaster_screen.dart';

class HomeScreen extends StatefulWidget {
  final FarmerModel farmer;
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.farmer,
    required this.authService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _farmService = FarmService();
  final _eventService = DisasterEventService();

  List<FarmModel>? _farms;
  List<DisasterEventModel>? _events;
  String? _farmsError;
  String? _eventsError;

  StreamSubscription<List<FarmModel>>? _farmsSub;
  StreamSubscription<List<DisasterEventModel>>? _eventsSub;

  /// When set, PDF is being built for the event with this id.
  String? _pdfLoadingEventId;

  /// When set, a draft delete is in progress for this event id.
  String? _deletingEventId;

  @override
  void initState() {
    super.initState();
    _subscribeToFarms();
    _subscribeToEvents();
  }

  void _subscribeToFarms() {
    _farmsSub = _farmService.farmsStream(widget.farmer.uid).listen(
      (farms) {
        if (mounted) setState(() { _farms = farms; _farmsError = null; });
      },
      onError: (Object e) {
        if (mounted) setState(() => _farmsError = e.toString());
      },
    );
  }

  void _subscribeToEvents() {
    _eventsSub = _eventService.eventsStream(widget.farmer.uid).listen(
      (events) {
        if (mounted) setState(() { _events = events; _eventsError = null; });
      },
      onError: (Object e) {
        if (mounted) setState(() => _eventsError = e.toString());
      },
    );
  }

  @override
  void dispose() {
    _farmsSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    await widget.authService.signOut();
  }

  void _openAddFarm() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddFarmScreen(farmer: widget.farmer)),
    );
  }

  void _openFarmMap(FarmModel farm) {
    final eventsForFarm = (_events ?? [])
        .where((e) => e.farmId == farm.id)
        .toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmMapScreen(
          farm: farm,
          farmer: widget.farmer,
          event: eventsForFarm.isEmpty ? null : eventsForFarm.first,
        ),
      ),
    );
  }

  void _reportDisaster() {
    final l10n = AppLocalizations.of(context);
    final farms = _farms ?? [];
    if (farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseAddFarmFirst)),
      );
      return;
    }
    if (farms.length == 1) {
      _pushNewDisaster(farms.first);
      return;
    }
    _showFarmPickerSheet();
  }

  void _pushNewDisaster(FarmModel farm) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewDisasterScreen(farmer: widget.farmer, farm: farm),
      ),
    );
  }

  FarmModel? _farmForEvent(DisasterEventModel event) {
    final farms = _farms;
    if (farms == null) return null;
    for (final f in farms) {
      if (f.id == event.farmId) return f;
    }
    return null;
  }

  void _editDraft(DisasterEventModel event) {
    final farm = _farmForEvent(event);
    final l10n = AppLocalizations.of(context);
    if (farm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.farmNotFoundForReport)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewDisasterScreen(
          farmer: widget.farmer,
          farm: farm,
          existingDraft: event,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEvent(
    DisasterEventModel event, {
    required bool isDraft,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isDraft
              ? l10n.confirmDeleteDraftTitle
              : l10n.confirmDeleteSubmittedTitle,
        ),
        content: Text(
          isDraft
              ? l10n.confirmDeleteDraftMessage
              : l10n.confirmDeleteSubmittedMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alertHigh),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingEventId = event.id);
    try {
      await _eventService.deleteEvent(event.id);
      await ReportMediaStorage.deleteMediaForEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotDeleteDraft(e.toString())),
          backgroundColor: AppColors.alertHigh,
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingEventId = null);
    }
  }

  Future<void> _downloadDamageReport(DisasterEventModel event) async {
    final l10n = AppLocalizations.of(context);
    final farms = _farms;
    if (farms == null || farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.farmNotFoundForReport)),
      );
      return;
    }
    FarmModel? farm;
    for (final f in farms) {
      if (f.id == event.farmId) {
        farm = f;
        break;
      }
    }
    if (farm == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.farmNotFoundForReport)),
      );
      return;
    }
    if (_pdfLoadingEventId != null) return;
    setState(() => _pdfLoadingEventId = event.id);
    try {
      await DamagePreviewPdfService.printDamageReport(
        farm: farm,
        farmer: widget.farmer,
        event: event,
        narrativeText: event.aiNarrative ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.damageReportPdfReady)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotBuildPdf(e.toString())),
          backgroundColor: AppColors.alertHigh,
        ),
      );
    } finally {
      if (mounted) setState(() => _pdfLoadingEventId = null);
    }
  }

  void _showFarmPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        final farms = _farms ?? [];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  l10n.selectFarmToReport,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ...farms.map(
                (farm) => ListTile(
                  leading: const Icon(
                    Icons.agriculture_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(farm.name),
                  subtitle: Text(
                    '${farm.cropType} · ${farm.areaHectares.toStringAsFixed(1)} ha',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pushNewDisaster(farm);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final farmer = widget.farmer;
    return TutorialWrapper(
      screenKey: 'home',
      showEmbeddedToggle: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.appTitle,
            style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                  fontSize: 19,
                  letterSpacing: 0,
                ),
          ),
          actions: [
            ListenableBuilder(
              listenable: TutorialService(),
              builder: (context, _) {
                final svc = TutorialService();
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Tooltip(
                    message:
                        svc.isEnabled ? 'Tutorial on' : 'Tutorial off',
                    child: Switch.adaptive(
                      value: svc.isEnabled,
                      onChanged: (v) => svc.setEnabled(v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () => showTutorialVoicePickerSheet(context),
              icon: const Icon(Icons.record_voice_over_outlined),
              tooltip: 'Tutorial voice language',
            ),
            IconButton(
              onPressed: () => showLanguagePickerSheet(context),
              icon: const Icon(Icons.language_outlined),
              tooltip: l10n.language,
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: l10n.signOut,
            ),
          ],
        ),
        body: RefreshIndicator(
        onRefresh: () async {
          await _farmsSub?.cancel();
          await _eventsSub?.cancel();
          _subscribeToFarms();
          _subscribeToEvents();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── Greeting ──────────────────────────────────────────────────
            Text(
              l10n.hello(farmer.name),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (farmer.email.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                farmer.email,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── My Farms ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.myFarms,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAddFarm,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFarmsSection(),

            const SizedBox(height: 24),

            // ── Quick Actions ─────────────────────────────────────────────
            Text(
              l10n.quickActions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              title: l10n.reportDisaster,
              subtitle: l10n.reportDisasterSubtitle,
              icon: Icons.warning_amber_rounded,
              onTap: _reportDisaster,
            ),
            const SizedBox(height: 10),
            _ActionCard(
              title: l10n.addNewFarm,
              subtitle: l10n.addNewFarmSubtitle,
              icon: Icons.add_location_alt_outlined,
              onTap: _openAddFarm,
            ),

            const SizedBox(height: 24),

            // ── Disaster Events ───────────────────────────────────────────
            Text(
              l10n.disasterEvents,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _buildEventsSection(),
          ],
        ),
        ),
        floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFarm,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.addFarm),
        ),
      ),
    );
  }

  // ── Farms section ────────────────────────────────────────────────────────

  Widget _buildFarmsSection() {
    final l10n = AppLocalizations.of(context);
    if (_farmsError != null) {
      return _ErrorCard(
        message: l10n.couldNotLoadFarms,
        detail: _farmsError!,
      );
    }
    if (_farms == null) {
      return _LoadingCard(label: l10n.loadingFarms);
    }
    if (_farms!.isEmpty) {
      return _EmptyFarmsCard(onAddTap: _openAddFarm);
    }
    return Column(
      children: _farms!.map((farm) => _FarmCard(
        farm: farm,
        onTap: () => _openFarmMap(farm),
        onReportDisaster: () => _pushNewDisaster(farm),
      )).toList(),
    );
  }

  // ── Events section ───────────────────────────────────────────────────────

  Widget _buildEventsSection() {
    final l10n = AppLocalizations.of(context);
    if (_eventsError != null) {
      return _ErrorCard(
        message: l10n.couldNotLoadEvents,
        detail: _eventsError!,
      );
    }
    if (_events == null) {
      return _LoadingCard(label: l10n.loadingEvents);
    }
    if (_events!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_outlined,
              size: 42,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noDisasterReportsYet,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return Column(
      children: _events!.map((event) {
        final pdfBusy = _pdfLoadingEventId == event.id;
        final isDraft = event.status.toLowerCase() == 'draft';
        final deleteBusy = _deletingEventId == event.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        _disasterIcon(event.disasterType),
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.disasterType,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(event.occurredAt)} · ${event.farmId.isEmpty ? '' : 'Farm'}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 0,
                  runSpacing: 4,
                  children: [
                    if (isDraft) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: l10n.editDraftReport,
                        onPressed: deleteBusy || _deletingEventId != null
                            ? null
                            : () => _editDraft(event),
                      ),
                      IconButton(
                        icon: deleteBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline),
                        tooltip: l10n.deleteDraftReport,
                        onPressed: deleteBusy || _deletingEventId != null
                            ? null
                            : () => _confirmDeleteEvent(event, isDraft: true),
                      ),
                    ] else ...[
                      IconButton(
                        icon: pdfBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        tooltip: l10n.downloadDamageReport,
                        onPressed: pdfBusy ||
                                _pdfLoadingEventId != null ||
                                _deletingEventId != null
                            ? null
                            : () => _downloadDamageReport(event),
                      ),
                      IconButton(
                        icon: deleteBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline),
                        tooltip: l10n.deleteSubmittedReport,
                        onPressed: deleteBusy || _deletingEventId != null
                            ? null
                            : () => _confirmDeleteEvent(event, isDraft: false),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: _StatusBadge(status: event.status),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  IconData _disasterIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('flood')) return Icons.water_outlined;
    if (t.contains('wildlife') || t.contains('animal')) return Icons.pest_control_outlined;
    if (t.contains('storm') || t.contains('wind')) return Icons.air;
    if (t.contains('drought') || t.contains('fire')) return Icons.local_fire_department_outlined;
    return Icons.warning_amber_rounded;
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _FarmCard extends StatelessWidget {
  final FarmModel farm;
  final VoidCallback onTap;
  final VoidCallback onReportDisaster;

  const _FarmCard({
    required this.farm,
    required this.onTap,
    required this.onReportDisaster,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.l),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.oliveLight,
                      borderRadius: BorderRadius.circular(AppRadii.s),
                    ),
                    child: const Icon(
                      Icons.agriculture_outlined,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          farm.surveyNumber,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _FarmChip(
                    icon: Icons.grass_outlined,
                    label: farm.cropType,
                  ),
                  const SizedBox(width: 8),
                  _FarmChip(
                    icon: Icons.straighten_outlined,
                    label: '${farm.areaHectares.toStringAsFixed(1)} ha',
                  ),
                  const SizedBox(width: 8),
                  _FarmChip(
                    icon: Icons.place_outlined,
                    label: '${farm.boundaries.length} pts',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReportDisaster,
                  icon: const Icon(Icons.warning_amber_outlined, size: 16),
                  label: Text(AppLocalizations.of(context).reportDisaster),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FarmChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFarmsCard extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyFarmsCard({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.add_location_alt_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.noFarmsAdded,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.addFirstFarmDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add),
              label: Text(l10n.addFirstFarm),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String label;
  const _LoadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String detail;
  const _ErrorCard({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.alertHigh),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.alertHigh,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
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
        leading: Icon(icon, color: AppColors.primary),
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
    final l10n = AppLocalizations.of(context);
    final normalized = status.toLowerCase();
    final label = switch (normalized) {
      'submitted' => l10n.statusSubmitted,
      'verified' => l10n.statusVerified,
      _ => l10n.statusDraft,
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
