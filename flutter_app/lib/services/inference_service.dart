/// Conditional export: on web (dart.library.html available) the stub is used
/// so tflite_flutter / dart:ffi are never compiled for the web target.
/// On native targets (Android, iOS, desktop) the real TFLite implementation
/// is used.
export 'inference_service_web.dart'
    if (dart.library.io) 'inference_service_io.dart';
