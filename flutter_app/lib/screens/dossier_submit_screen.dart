import 'package:flutter/material.dart';

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../services/damage_preview_pdf_service.dart';
import '../theme/app_theme.dart';

class DossierSubmitScreen extends StatefulWidget {
  final FarmModel farm;
  final FarmerModel farmer;
  final DisasterEventModel event;
  /// Narrative text as shown on the damage preview (may differ from [event.aiNarrative]).
  final String narrativeText;

  const DossierSubmitScreen({
    super.key,
    required this.farm,
    required this.farmer,
    required this.event,
    required this.narrativeText,
  });

  @override
  State<DossierSubmitScreen> createState() => _DossierSubmitScreenState();
}

class _DossierSubmitScreenState extends State<DossierSubmitScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    if (_pdfLoading) return;
    setState(() => _pdfLoading = true);
    try {
      await DamagePreviewPdfService.printDamageReport(
        farm: widget.farm,
        farmer: widget.farmer,
        event: widget.event,
        narrativeText: widget.narrativeText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF ready — use Save or Share from the preview.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not build PDF: $e'),
          backgroundColor: AppColors.alertHigh,
        ),
      );
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 92),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report submitted successfully',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'AGS-2026-001',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pdfLoading ? null : _downloadPdf,
                icon: _pdfLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_pdfLoading ? 'Building PDF…' : 'PDF download'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
