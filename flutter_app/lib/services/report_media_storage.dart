import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/disaster_event_model.dart';
import '../models/hotspot_model.dart';

/// Copies local image files into app documents under `report_media/<eventId>/`
/// so paths remain valid after temp camera files are removed.
class ReportMediaStorage {
  ReportMediaStorage._();

  static bool _isRemoteOrPlaceholder(String? ref) {
    if (ref == null || ref.isEmpty) return true;
    final r = ref.toLowerCase();
    if (r.startsWith('http://') || r.startsWith('https://')) return true;
    if (r.startsWith('local://')) return true;
    return false;
  }

  static Future<String?> _copyIfLocalFile(String? src, String destPath) async {
    if (_isRemoteOrPlaceholder(src)) return src;
    try {
      final f = File(src!);
      if (!await f.exists()) return src;
      await f.copy(destPath);
      return destPath;
    } catch (_) {
      return src;
    }
  }

  static String _safeHotspotId(String id) =>
      id.replaceAll(RegExp(r'[^\w\-]+'), '_');

  /// Returns a new [DisasterEventModel] with durable paths. On web, returns
  /// [event] unchanged.
  static Future<DisasterEventModel> persistMediaForEvent(
    DisasterEventModel event,
  ) async {
    if (kIsWeb) return event;

    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'report_media', event.id));
    await dir.create(recursive: true);

    var newCaptured = event.capturedImagePath;
    if (!_isRemoteOrPlaceholder(newCaptured)) {
      final ext = p.extension(newCaptured!);
      final out = p.join(
        dir.path,
        'event_capture${ext.isEmpty ? '.jpg' : ext}',
      );
      newCaptured = await _copyIfLocalFile(newCaptured, out);
    }

    final updatedHotspots = <HotspotModel>[];
    for (final h in event.hotspots) {
      var photoUrl = h.photoUrl;
      var gradcamUrl = h.gradcamUrl;

      if (!_isRemoteOrPlaceholder(photoUrl)) {
        final ext = p.extension(photoUrl!);
        final name =
            'hotspot_${_safeHotspotId(h.id)}_photo${ext.isEmpty ? '.jpg' : ext}';
        photoUrl = await _copyIfLocalFile(photoUrl, p.join(dir.path, name));
      }
      if (!_isRemoteOrPlaceholder(gradcamUrl)) {
        final ext = p.extension(gradcamUrl!);
        final name =
            'hotspot_${_safeHotspotId(h.id)}_gradcam${ext.isEmpty ? '.png' : ext}';
        gradcamUrl = await _copyIfLocalFile(gradcamUrl, p.join(dir.path, name));
      }

      updatedHotspots.add(
        h.copyWith(photoUrl: photoUrl, gradcamUrl: gradcamUrl),
      );
    }

    return event.copyWith(
      capturedImagePath: newCaptured,
      hotspots: updatedHotspots,
    );
  }

  /// Removes `report_media/<eventId>/` under app documents. No-op on web.
  static Future<void> deleteMediaForEvent(String eventId) async {
    if (kIsWeb || eventId.isEmpty) return;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'report_media', eventId));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
