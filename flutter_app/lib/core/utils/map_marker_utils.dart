import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

Future<gmaps.BitmapDescriptor> bitmapDescriptorFromIcon(
  IconData icon,
  Color color, {
  double size = 64,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
  )..layout();

  textPainter.paint(canvas, Offset.zero);

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    textPainter.width.ceil(),
    textPainter.height.ceil(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);
  return gmaps.BitmapDescriptor.bytes(bytes);
}

