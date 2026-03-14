import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/hotspot.dart';
import '../services/demo_data.dart';
import '../theme/app_theme.dart';
import '../widgets/damage_gauge.dart';

class ClaimScreen extends StatefulWidget {
  final Hotspot hotspot;
  final String? capturedImagePath;

  const ClaimScreen({
    super.key,
    required this.hotspot,
    this.capturedImagePath,
  });

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen>
    with SingleTickerProviderStateMixin {
  bool _isGenerating = false;
  bool _isGenerated = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ─── PDF generation ────────────────────────────────────────────────────────

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final pdfBytes = await _buildPdf();
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _isGenerated = true;
      });
      await Printing.layoutPdf(
        onLayout: (format) async => Uint8List.fromList(pdfBytes),
        name: 'CLM-2024-001_AgriSentinel_Dossier.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed: $e'),
          backgroundColor: AppColors.alertHigh,
        ),
      );
    }
  }

  Future<List<int>> _buildPdf() async {
    final pdf = pw.Document(
      title: 'AgriSentinel Claim Dossier — CLM-2024-001',
      author: 'AgriSentinel AI System',
    );

    final analysis = DemoData.aiAnalysis;
    final claim = DemoData.claim;
    final parcel = widget.hotspot.landParcel;

    // Load captured image bytes if available (native only — no File API on web)
    pw.MemoryImage? capturedImg;
    if (!kIsWeb && widget.capturedImagePath != null) {
      try {
        final bytes = await File(widget.capturedImagePath!).readAsBytes();
        capturedImg = pw.MemoryImage(bytes);
      } catch (_) {
        // ignore if file unreadable
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => _pdfHeader(),
        footer: (ctx) => _pdfFooter(ctx),
        build: (ctx) => [
          _pdfClaimBanner(claim),
          pw.SizedBox(height: 16),
          _pdfSection('FARMER & LAND DETAILS'),
          _pdfTable([
            ['Farmer Name', DemoData.farmer.name],
            ['Farmer ID', DemoData.farmer.farmerId],
            ['Region', DemoData.farmer.region],
            if (parcel != null) ...[
              ['Parcel ID', parcel.parcelId],
              ['Registered Area', '${parcel.registeredAreaHa} ha'],
              ['Crop Type', widget.hotspot.cropType],
              ['Season', parcel.cropSeason],
            ],
          ]),
          pw.SizedBox(height: 16),
          _pdfSection('SATELLITE DETECTION DATA'),
          _pdfTable([
            ['Hotspot ID', widget.hotspot.id],
            ['Detection Date', '10 Mar 2024'],
            ['NDVI Before', '${analysis['ndviBefore']}  (Healthy)'],
            ['NDVI After', '${analysis['ndviAfter']}  (Damaged)'],
            ['NDVI Drop', widget.hotspot.ndviDeltaLabel],
            ['Estimated Damage Area', '${widget.hotspot.estimatedAreaHa} ha'],
            ['Damage Cause', widget.hotspot.damageCause],
            ['Severity', widget.hotspot.severity.toUpperCase()],
          ]),
          pw.SizedBox(height: 16),
          _pdfSection('AI DAMAGE ANALYSIS'),
          _pdfTable([
            ['Evidence ID', analysis['evidenceId'] as String],
            ['Damage Percentage', '${analysis['damagePercentage']}%'],
            ['Healthy Pixel Ratio', '${((analysis['healthyPixelRatio'] as double) * 100).toStringAsFixed(1)}%'],
            ['Damaged Pixel Ratio', '${((analysis['damagedPixelRatio'] as double) * 100).toStringAsFixed(1)}%'],
            ['AI Confidence Score', '${((analysis['confidenceScore'] as double) * 100).toStringAsFixed(0)}%'],
            ['Damage Classification', analysis['damageClass'] as String],
          ]),
          if (capturedImg != null) ...[
            pw.SizedBox(height: 16),
            _pdfSection('GROUND EVIDENCE PHOTO'),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pw.Image(capturedImg, height: 200, fit: pw.BoxFit.cover),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Captured: ${widget.hotspot.latitude.toStringAsFixed(4)}, '
                '${widget.hotspot.longitude.toStringAsFixed(4)}  •  12 Mar 2024',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 16),
          _pdfSection('EVIDENCE CHAIN'),
          _pdfEvidenceChain(),
          pw.SizedBox(height: 24),
          _pdfComplianceBox(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.green800, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AgriSentinel',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'Satellite-Guided Crop Damage Verification System',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'VERIFIED CLAIM DOSSIER',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'AIMS Compliant  •  AI-Verified',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CLM-2024-001  •  Generated by AgriSentinel  •  Palakkad District, Kerala',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfClaimBanner(Map<String, dynamic> claim) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.green700, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                claim['claimId'] as String,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Generated: ${claim['createdAt']}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.green700,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'READY FOR SUBMISSION',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSection(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _pdfTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: pw.Text(
                row[1],
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _pdfEvidenceChain() {
    final steps = [
      ('Satellite Detection', 'NDVI anomaly detected via Planet NICFI • 10 Mar 2024'),
      ('GPS Truth Walk', 'Farmer navigated to hotspot using AgriSentinel • 12 Mar 2024'),
      ('Ground Evidence Captured', 'AI scan: 67.4% damage • Confidence 89% • 12 Mar 2024'),
      ('Claim Dossier Generated', 'CLM-2024-001 • AIMS Compliant PDF • 12 Mar 2024'),
    ];

    return pw.Column(
      children: steps.asMap().entries.map((e) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.green700,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '${e.key + 1}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      e.value.$1,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      e.value.$2,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _pdfComplianceBox() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green800, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AIMS COMPLIANCE DECLARATION',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'This document has been generated by the AgriSentinel AI-Verified Crop Damage Assessment '
            'System and complies with the Agricultural Insurance Management System (AIMS) standards. '
            'The damage assessment has been cross-validated using (1) satellite NDVI analysis via '
            'Planet NICFI imagery, (2) GPS-geotagged ground evidence capture, and (3) on-device '
            'AI semantic segmentation analysis. This dossier is admissible as evidence for crop '
            'insurance claims and government agricultural disaster recovery programmes.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final analysis = DemoData.aiAnalysis;
    final claim = DemoData.claim;
    final parcel = widget.hotspot.landParcel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim Dossier'),
            Text(
              'AI-Verified Evidence Report',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'AIMS',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClaimBanner(claim),
              const SizedBox(height: 16),
              _buildBeforeAfterSection(),
              const SizedBox(height: 16),
              if (parcel != null) ...[
                _buildSectionHeader(Icons.landscape, 'Land Parcel Details'),
                const SizedBox(height: 10),
                _buildParcelCard(parcel),
                const SizedBox(height: 16),
              ],
              _buildSectionHeader(Icons.biotech, 'AI Damage Analysis'),
              const SizedBox(height: 10),
              _buildAIAnalysisCard(analysis),
              const SizedBox(height: 16),
              _buildSectionHeader(Icons.satellite_alt, 'Satellite Detection Data'),
              const SizedBox(height: 10),
              _buildSatelliteCard(),
              const SizedBox(height: 16),
              _buildSectionHeader(Icons.link, 'Evidence Chain'),
              const SizedBox(height: 10),
              _buildEvidenceChain(),
              const SizedBox(height: 28),
              _buildGenerateButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimBanner(Map<String, dynamic> claim) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim['claimId'] as String,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Generated: ${claim['createdAt']}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'READY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.compare, 'Before / After Comparison'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ImageCard(
                label: 'BEFORE',
                sublabel: '10 Mar 2024',
                color: AppColors.accent,
                icon: Icons.satellite_alt,
                ndvi: '0.60',
                ndviLabel: 'NDVI Healthy',
                capturedPath: null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ImageCard(
                label: 'AFTER',
                sublabel: '12 Mar 2024',
                color: AppColors.alertHigh,
                icon: Icons.camera_alt_outlined,
                ndvi: '0.18',
                ndviLabel: 'NDVI Damaged',
                capturedPath: widget.capturedImagePath,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParcelCard(LandParcel parcel) {
    return _InfoCard(
      children: [
        _DetailRow(label: 'Parcel ID', value: parcel.parcelId, mono: true),
        _DetailRow(label: 'Owner', value: parcel.ownerName),
        _DetailRow(
          label: 'Registered Area',
          value: '${parcel.registeredAreaHa} ha',
        ),
        _DetailRow(label: 'Crop Type', value: widget.hotspot.cropType),
        _DetailRow(label: 'Season', value: parcel.cropSeason),
      ],
    );
  }

  Widget _buildAIAnalysisCard(Map<String, dynamic> analysis) {
    final damage = analysis['damagePercentage'] as double;
    final confidence =
        ((analysis['confidenceScore'] as double) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DamageGauge(percentage: damage, size: 100),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SmallDetailRow(
                      label: 'Damage Class',
                      value: analysis['damageClass'] as String,
                      valueColor: AppColors.alertHigh,
                    ),
                    const SizedBox(height: 10),
                    _SmallDetailRow(
                      label: 'AI Confidence',
                      value: '$confidence%',
                      valueColor: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _SmallDetailRow(
                      label: 'Healthy Pixels',
                      value:
                          '${((analysis['healthyPixelRatio'] as double) * 100).toStringAsFixed(1)}%',
                      valueColor: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _SmallDetailRow(
                      label: 'Damaged Pixels',
                      value:
                          '${((analysis['damagedPixelRatio'] as double) * 100).toStringAsFixed(1)}%',
                      valueColor: AppColors.alertHigh,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Evidence ID',
                  value: analysis['evidenceId'] as String,
                  mono: true,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Hotspot',
                  value: widget.hotspot.id,
                  mono: true,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Area Affected',
                  value: '${widget.hotspot.estimatedAreaHa} ha',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteCard() {
    final analysis = DemoData.aiAnalysis;
    return _InfoCard(
      children: [
        _DetailRow(label: 'Detection Date', value: '10 Mar 2024'),
        _DetailRow(
          label: 'NDVI Before',
          value: '${analysis['ndviBefore']}',
          valueColor: AppColors.accent,
        ),
        _DetailRow(
          label: 'NDVI After',
          value: '${analysis['ndviAfter']}',
          valueColor: AppColors.alertHigh,
        ),
        _DetailRow(
          label: 'NDVI Drop',
          value: '${widget.hotspot.ndviDeltaLabel} change',
          valueColor: AppColors.alertHigh,
        ),
        _DetailRow(
          label: 'Source',
          value: 'Planet NICFI / Google Earth Engine',
        ),
      ],
    );
  }

  Widget _buildEvidenceChain() {
    final items = [
      _EvidenceStep(
        icon: Icons.satellite_alt,
        title: 'Satellite Detection',
        subtitle: 'NDVI anomaly detected  •  10 Mar 2024',
        isComplete: true,
      ),
      _EvidenceStep(
        icon: Icons.explore,
        title: 'GPS Truth Walk',
        subtitle: 'Farmer navigated to hotspot  •  12 Mar 2024',
        isComplete: true,
      ),
      _EvidenceStep(
        icon: Icons.camera_alt_outlined,
        title: 'Ground Evidence Captured',
        subtitle: 'AI scan: 67.4% damage  •  Confidence 89%',
        isComplete: true,
      ),
      _EvidenceStep(
        icon: Icons.description_outlined,
        title: 'Claim Dossier Generated',
        subtitle: 'CLM-2024-001  •  AIMS Compliant PDF',
        isComplete: _isGenerated,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isComplete
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.border,
                      border: Border.all(
                        color: item.isComplete
                            ? AppColors.accent
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      item.isComplete ? Icons.check : item.icon,
                      size: 15,
                      color: item.isComplete
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                  if (i < items.length - 1)
                    Container(
                      width: 1.5,
                      height: 28,
                      color: item.isComplete
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < items.length - 1 ? 36 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: item.isComplete
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenerateButton() {
    if (_isGenerated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Shared / Downloaded',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'CLM-2024-001_AgriSentinel_Dossier.pdf',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Reopen'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateReport,
        icon: _isGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf, size: 18),
        label: Text(
          _isGenerating ? 'Generating AIMS Report...' : 'Generate & Download Report PDF',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _ImageCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final String ndvi;
  final String ndviLabel;
  final String? capturedPath;

  const _ImageCard({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.ndvi,
    required this.ndviLabel,
    required this.capturedPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Image area
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(13)),
            child: SizedBox(
              height: 110,
              child: (capturedPath != null && !kIsWeb)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(capturedPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, err, stack) =>
                              _placeholder(color, icon),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _labelChip(color),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        _placeholder(color, icon),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _labelChip(color),
                        ),
                      ],
                    ),
            ),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sublabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'NDVI $ndvi',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ndviLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 36, color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _labelChip(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          return Column(
            children: [
              entry.value,
              if (entry.key < children.length - 1) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _SmallDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SmallDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _MiniStat({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _EvidenceStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComplete;

  const _EvidenceStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isComplete,
  });
}
