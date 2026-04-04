import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../models/hotspot_model.dart';

/// Builds a multi-page PDF that mirrors the Damage Report Preview: farm and
/// farmer identity, disaster metadata, satellite-derived metrics, hotspot
/// rows with embedded photos where available, totals, AI narrative, and the
/// farmer statement. Satellite pair images default to demo assets used by
/// [SatelliteService].
class DamagePreviewPdfService {
  DamagePreviewPdfService._();

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  static String _formatDateTime(DateTime d) {
    return '${_formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static String _statusDisplayLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Report generated';
      case 'verified':
        return 'Verified';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }

  static Future<pw.MemoryImage?> _loadImageRef(String? ref) async {
    if (ref == null || ref.isEmpty) return null;
    if (ref.startsWith('local://')) return null;
    try {
      if (ref.startsWith('http://') || ref.startsWith('https://')) {
        final r = await http
            .get(Uri.parse(ref))
            .timeout(const Duration(seconds: 20));
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          return pw.MemoryImage(r.bodyBytes);
        }
        return null;
      }
      if (!kIsWeb) {
        final f = File(ref);
        if (await f.exists()) {
          return pw.MemoryImage(await f.readAsBytes());
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<pw.MemoryImage?> _loadAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _section(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _table(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.1),
        1: pw.FlexColumnWidth(2.9),
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

  static pw.Widget _header() {
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
                'agroSentinel',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'Damage report preview — full dossier',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Text(
            'CONFIDENTIAL',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
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
            'agroSentinel • Satellite-guided crop damage verification',
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

  static pw.Widget _bodyText(String text) {
    return pw.Text(
      text.isEmpty ? '—' : text,
      style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.35),
    );
  }

  /// Loads images, composes the document, and returns PDF bytes.
  static Future<Uint8List> buildPdfBytes({
    required FarmModel farm,
    required FarmerModel farmer,
    required DisasterEventModel event,
    required String narrativeText,
    String beforeAssetPath = 'assets/demo/before.png',
    String afterAssetPath = 'assets/demo/after.png',
  }) async {
    final beforeImg = await _loadAsset(beforeAssetPath);
    final afterImg = await _loadAsset(afterAssetPath);

    pw.MemoryImage? captured;
    if (!kIsWeb && (event.capturedImagePath ?? '').isNotEmpty) {
      captured = await _loadImageRef(event.capturedImagePath);
    }

    final hotspotVisuals =
        <({HotspotModel h, pw.MemoryImage? photo, pw.MemoryImage? gradcam})>[];
    for (final h in event.hotspots) {
      final photo = await _loadImageRef(h.photoUrl);
      final gradcam = await _loadImageRef(h.gradcamUrl);
      hotspotVisuals.add((h: h, photo: photo, gradcam: gradcam));
    }

    final hotspots = event.hotspots;
    final damaged = hotspots
        .where((h) => (h.aiResult ?? '').toUpperCase() == 'DAMAGED')
        .length;
    final treesLost = hotspots.fold<int>(0, (sum, h) => sum + h.treesLost);
    final estimatedLoss = treesLost * 2500;
    final narrative = narrativeText.trim().isEmpty
        ? (event.aiNarrative ?? 'Narrative not available.')
        : narrativeText.trim();
    final cropAge = event.cropAgeYears;

    final pdf = pw.Document(
      title: 'agroSentinel Damage Report — ${event.id}',
      author: 'agroSentinel',
    );

    final children = <pw.Widget>[
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.green700),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Event ${event.id}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
                pw.Text(
                  'Status: ${_statusDisplayLabel(event.status)} • Reported ${_formatDateTime(event.reportedAt)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Text(
              'LOSS EST. ₹$estimatedLoss',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 14),
      _section('FARM DETAILS'),
      _table([
        ['Farm name', farm.name],
        ['Survey number', farm.surveyNumber],
        ['Crop', farm.cropType],
        ['Area', '${farm.areaHectares.toStringAsFixed(1)} ha'],
        [
          'Crop age',
          cropAge != null
              ? '${cropAge > 50 ? 50 : cropAge} year(s)'
              : '—',
        ],
        [
          'Bearing stage',
          event.isBearing == null
              ? '—'
              : (event.isBearing! ? 'Yes (bearing)' : 'No (non-bearing)'),
        ],
        ['Farm ID', farm.id],
      ]),
      pw.SizedBox(height: 12),
      _section('FARMER DETAILS'),
      _table([
        ['Name', farmer.name],
        ['Phone', farmer.phone],
        ['Email', farmer.email],
        ['Aadhaar (last 4)', farmer.aadhaarLast4],
        ['Farmer UID', farmer.uid],
      ]),
      pw.SizedBox(height: 12),
      _section('DISASTER DETAILS'),
      _table([
        ['Type', event.disasterType],
        ['Occurred', _formatDate(event.occurredAt)],
        ['Reported', _formatDateTime(event.reportedAt)],
      ]),
      pw.SizedBox(height: 12),
      _section('SATELLITE ANALYSIS'),
      _table([
        ['Damage score', event.damageScore.toStringAsFixed(3)],
        ['Model / camera confidence', event.confidence.toStringAsFixed(3)],
        ['Affected area', '${event.affectedAreaHa.toStringAsFixed(2)} ha'],
        ['Destroyed area', '${event.destroyedAreaM2.toStringAsFixed(1)} m²'],
        ['Groq vision OK', event.satelliteGroqOk ? 'Yes' : 'No'],
        [
          'Groq confidence',
          '${(event.satelliteGroqConfidence * 100).toStringAsFixed(0)}%',
        ],
        if (event.satelliteGroqError.isNotEmpty)
          ['Groq error', event.satelliteGroqError],
        [
          'Summary',
          event.satelliteSummary.isEmpty ? '—' : event.satelliteSummary,
        ],
      ]),
      pw.SizedBox(height: 10),
      if (beforeImg != null && afterImg != null) ...[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Satellite — before',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Image(
                      beforeImg,
                      height: 130,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Satellite — after',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Image(
                      afterImg,
                      height: 130,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
      ],
      _section('HOTSPOT SUMMARY'),
      _table(
        hotspots
            .map(
              (h) => [
                'Hotspot ${h.id}',
                '${h.aiResult ?? 'PENDING'} • '
                    'confidence ${((h.aiConfidence ?? 0) * 100).toStringAsFixed(0)}% • '
                    'trees lost ${h.treesLost} • '
                    '${h.latitude.toStringAsFixed(5)}, ${h.longitude.toStringAsFixed(5)} • '
                    'captured ${_formatDateTime(h.capturedAt)}',
              ],
            )
            .toList(),
      ),
      pw.SizedBox(height: 12),
      _section('TOTAL DAMAGE SUMMARY'),
      _table([
        ['Total hotspots marked', '${hotspots.length}'],
        ['Damaged areas', '$damaged'],
        ['Estimated trees lost', '$treesLost'],
        ['Estimated loss', '₹$estimatedLoss'],
      ]),
      pw.SizedBox(height: 12),
      _section('AI ASSESSMENT REPORT'),
      _bodyText(narrative),
      pw.SizedBox(height: 12),
      _section('FARMER DESCRIPTION / STATEMENT'),
      _bodyText(event.farmerDescription),
    ];

    if (captured != null) {
      children.addAll([
        pw.SizedBox(height: 12),
        _section('ADDITIONAL CAPTURE (EVENT)'),
        pw.Center(
          child: pw.Image(captured, height: 160, fit: pw.BoxFit.contain),
        ),
      ]);
    }

    for (final v in hotspotVisuals) {
      if (v.photo == null && v.gradcam == null) continue;
      children.addAll([
        pw.SizedBox(height: 14),
        pw.NewPage(),
        _section('HOTSPOT ${v.h.id} — PHOTOS'),
        pw.Text(
          'Location ${v.h.latitude.toStringAsFixed(5)}, ${v.h.longitude.toStringAsFixed(5)} • '
          '${v.h.aiResult ?? 'PENDING'}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
      ]);
      if (v.photo != null) {
        children.addAll([
          pw.Text(
            'Ground / inspection photo',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Image(v.photo!, height: 200, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 10),
        ]);
      }
      if (v.gradcam != null) {
        children.addAll([
          pw.Text(
            'Model attention (Grad-CAM)',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Image(v.gradcam!, height: 180, fit: pw.BoxFit.contain),
          ),
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => _header(),
        footer: _footer,
        build: (_) => children,
      ),
    );

    return pdf.save();
  }

  static String fileName(DisasterEventModel event) {
    final safe = event.id.replaceAll(RegExp(r'[^\w\-]+'), '_');
    return 'agroSentinel_Damage_Report_$safe.pdf';
  }

  /// Opens the platform print / share / save-as-PDF sheet.
  static Future<void> printDamageReport({
    required FarmModel farm,
    required FarmerModel farmer,
    required DisasterEventModel event,
    required String narrativeText,
  }) async {
    final bytes = await buildPdfBytes(
      farm: farm,
      farmer: farmer,
      event: event,
      narrativeText: narrativeText,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: fileName(event),
    );
  }
}
