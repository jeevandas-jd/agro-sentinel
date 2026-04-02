import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:http/http.dart' as http;

import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../models/lat_lng.dart' as app;
import '../services/farm_service.dart';
import '../theme/app_theme.dart';

// The same key that is injected into AndroidManifest.xml via local.properties.
// It is already embedded in the APK binary, so referencing it here is safe.
const _kMapsApiKey = String.fromEnvironment(
  'MAPS_API_KEY',
  defaultValue: 'AIzaSyDhofLfV9rZpUp5sULYvgzda55sePMryNc',
);

class AddFarmScreen extends StatefulWidget {
  final FarmerModel farmer;

  const AddFarmScreen({super.key, required this.farmer});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  static const _cropTypes = <String>[
    'Coconut',
    'Paddy',
    'Wheat',
    'Sugarcane',
    'Cotton',
    'Banana',
    'Mango',
    'Vegetables',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surveyCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  String? _cropType;
  final List<gmaps.LatLng> _boundaryPoints = [];
  gmaps.LatLng _mapCenter = const gmaps.LatLng(20.5937, 78.9629);

  // Tracks where the map camera is pointing right now (crosshair position)
  gmaps.LatLng _crosshairPosition = const gmaps.LatLng(20.5937, 78.9629);

  bool _onMapStep = false;
  bool _isSaving = false;
  bool _locationFetched = false;
  bool _fetchingLocation = false;
  bool _cameraMoving = false; // true while the user is panning

  // Search
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  String? _searchError;

  // My-location button
  bool _goingToLocation = false;

  gmaps.GoogleMapController? _mapController;

  final _farmService = FarmService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surveyCtrl.dispose();
    _areaCtrl.dispose();
    _searchCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Called once the GoogleMap widget is ready. Pans to the user's location
  /// immediately if we already have it, or waits for [_fetchDeviceLocation].
  void _onMapCreated(gmaps.GoogleMapController controller) {
    _mapController = controller;
    if (_locationFetched) {
      _animateCameraTo(_mapCenter);
    }
  }

  void _animateCameraTo(gmaps.LatLng target, {double zoom = 17}) {
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  Future<void> _fetchDeviceLocation() async {
    if (_locationFetched) return;
    if (mounted) setState(() => _fetchingLocation = true);

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        final newCenter = gmaps.LatLng(pos.latitude, pos.longitude);
        setState(() {
          _mapCenter = newCenter;
          _crosshairPosition = newCenter;
          _locationFetched = true;
          _fetchingLocation = false;
        });
        // Move the live map camera to the real GPS position
        _animateCameraTo(newCenter);
      } catch (_) {
        if (mounted) setState(() => _fetchingLocation = false);
      }
    } else {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  /// Geocodes the search text using the Google Geocoding REST API and flies
  /// the camera to the first result. Uses the same Maps API key that is
  /// already bundled in AndroidManifest.xml.
  Future<void> _searchLocation() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() { _isSearching = true; _searchError = null; });

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {'address': query, 'key': _kMapsApiKey},
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (!mounted) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';

      if (status == 'OK') {
        final results = body['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final geo = results.first['geometry']['location']
              as Map<String, dynamic>;
          final target = gmaps.LatLng(
            (geo['lat'] as num).toDouble(),
            (geo['lng'] as num).toDouble(),
          );
          setState(() { _isSearching = false; _searchError = null; });
          _animateCameraTo(target, zoom: 16);
          return;
        }
      }

      // ZERO_RESULTS or unexpected status
      setState(() {
        _isSearching = false;
        _searchError = status == 'ZERO_RESULTS'
            ? 'No location found for "$query". Try adding district or state.'
            : 'Search error: $status. Check your internet connection.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = 'Search failed. Check your internet connection.';
        });
      }
    }
  }

  /// Flies the camera to the device's current GPS position.
  Future<void> _goToMyLocation() async {
    if (_goingToLocation) return;
    setState(() => _goingToLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          _animateCameraTo(gmaps.LatLng(pos.latitude, pos.longitude), zoom: 18);
        }
      }
    } finally {
      if (mounted) setState(() => _goingToLocation = false);
    }
  }

  void _goToMapStep() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_cropType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop type.')),
      );
      return;
    }
    setState(() => _onMapStep = true);
    _fetchDeviceLocation();
  }

  /// Pins the current crosshair position as the next boundary point.
  void _addCrosshairPoint() {
    setState(() => _boundaryPoints.add(_crosshairPosition));
  }

  void _onCameraMoveStarted() {
    if (!_cameraMoving) setState(() => _cameraMoving = true);
  }

  void _onCameraMove(gmaps.CameraPosition pos) {
    _crosshairPosition = pos.target;
  }

  void _onCameraIdle() {
    if (_cameraMoving) setState(() => _cameraMoving = false);
  }

  void _undoLastPoint() {
    if (_boundaryPoints.isEmpty) return;
    setState(() => _boundaryPoints.removeLast());
  }

  void _clearPoints() {
    setState(() => _boundaryPoints.clear());
  }

  app.LatLng _centroid(List<gmaps.LatLng> points) {
    final lat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final lng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    return app.LatLng(latitude: lat, longitude: lng);
  }

  Future<void> _saveFarm() async {
    if (_boundaryPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mark at least 3 boundary points on the map.'),
        ),
      );
      return;
    }

    final center = _centroid(_boundaryPoints);
    final boundaries = _boundaryPoints
        .map((p) => app.LatLng(latitude: p.latitude, longitude: p.longitude))
        .toList(growable: false);

    final farm = FarmModel(
      id: '',
      farmerUid: widget.farmer.uid,
      name: _nameCtrl.text.trim(),
      surveyNumber: _surveyCtrl.text.trim(),
      cropType: _cropType!,
      areaHectares: double.tryParse(_areaCtrl.text.trim()) ?? 0,
      boundaries: boundaries,
      center: center,
      createdAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    try {
      await _farmService.addFarm(farm);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm added successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save farm: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_onMapStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _onMapStep) {
          setState(() => _onMapStep = false);
        }
      },
      child: _onMapStep ? _buildMapStep() : _buildFormStep(),
    );
  }

  // ── Step 1: Farm details form ───────────────────────────────────────────────

  Widget _buildFormStep() {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Farm')),
      body: SafeArea(
        child: Column(
          children: [
            _StepIndicator(step: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  children: [
                    _SectionLabel('Farm Identity'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Farm Name *',
                        hintText: "e.g. Ravi's Coconut Plot",
                        prefixIcon: Icon(Icons.agriculture_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter a farm name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _surveyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Survey / Plot Number *',
                        hintText: 'e.g. SY-11-204',
                        prefixIcon: Icon(Icons.tag_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter the survey number'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _areaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Area (hectares) *',
                        hintText: 'e.g. 2.5',
                        prefixIcon: Icon(Icons.square_foot_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter the farm area';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a valid decimal number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('Crop Type *'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _cropTypes.map((type) {
                        final selected = _cropType == type;
                        return FilterChip(
                          label: Text(type),
                          selected: selected,
                          showCheckmark: true,
                          onSelected: (_) =>
                              setState(() => _cropType = type),
                          selectedColor: AppColors.accentSoft,
                          checkmarkColor: AppColors.primaryDark,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.oliveLight,
                        borderRadius:
                            BorderRadius.circular(AppRadii.m),
                        border: Border.all(
                          color: AppColors.borderStrong,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'On the next step, long-press on the map to mark each boundary corner of your farm. At least 3 points are required.',
                              style:
                                  Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goToMapStep,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Continue — Mark Boundary on Map'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Map boundary drawing ────────────────────────────────────────────

  Widget _buildMapStep() {
    final polygon = _boundaryPoints.length >= 3
        ? gmaps.Polygon(
            polygonId: const gmaps.PolygonId('new-farm-boundary'),
            points: _boundaryPoints,
            strokeColor: AppColors.farmBoundaryColor,
            fillColor: AppColors.farmBoundaryColor.withValues(alpha: 0.25),
            strokeWidth: 2,
          )
        : null;

    // Lines connecting placed points so the user can see the partial boundary
    final polyline = _boundaryPoints.length >= 2
        ? gmaps.Polyline(
            polylineId: const gmaps.PolylineId('boundary-preview'),
            points: [
              ..._boundaryPoints,
              if (_boundaryPoints.length >= 3) _boundaryPoints.first,
            ],
            color: AppColors.farmBoundaryColor,
            width: 2,
          )
        : null;

    final markers = _boundaryPoints.asMap().entries.map((e) {
      final isFirst = e.key == 0;
      return gmaps.Marker(
        markerId: gmaps.MarkerId('boundary-pt-${e.key}'),
        position: e.value,
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          isFirst
              ? gmaps.BitmapDescriptor.hueGreen
              : gmaps.BitmapDescriptor.hueCyan,
        ),
        infoWindow: gmaps.InfoWindow(
          title: isFirst ? 'Start point' : 'Point ${e.key + 1}',
        ),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Farm Boundary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _onMapStep = false),
          tooltip: 'Back to form',
        ),
        actions: [
          if (_boundaryPoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoLastPoint,
              tooltip: 'Undo last point',
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Google Map ─────────────────────────────────────────────────
          Positioned.fill(
            child: gmaps.GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: gmaps.CameraPosition(
                target: _mapCenter,
                zoom: 16,
              ),
              // No onTap / onLongPress — points are added via the pin button
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              polygons: polygon != null ? {polygon} : const {},
              polylines: polyline != null ? {polyline} : const {},
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: gmaps.MapType.satellite,
            ),
          ),

          // ── Crosshair ─────────────────────────────────────────────────
          // Positioned exactly at the centre of the screen. IgnorePointer so
          // it never intercepts drags or taps on the map underneath.
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: _Crosshair()),
            ),
          ),

          // ── Initial location-fetching overlay ─────────────────────────
          if (_fetchingLocation)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.m),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 14),
                          Text(
                            'Finding your location…',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Please allow location access if prompted.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Top overlay: search bar + instruction hint ─────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search bar
                Card(
                  elevation: 3,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.m),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Search location or village…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            onSubmitted: (_) => _searchLocation(),
                            onChanged: (_) {
                              if (_searchError != null) {
                                setState(() => _searchError = null);
                              }
                            },
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() {
                              _searchCtrl.clear();
                              _searchError = null;
                            }),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        const SizedBox(width: 4),
                        _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : GestureDetector(
                                onTap: _searchLocation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.s),
                                  ),
                                  child: const Text(
                                    'Go',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                // Search error chip
                if (_searchError != null) ...[
                  const SizedBox(height: 6),
                  Card(
                    color: AppColors.alertHigh.withValues(alpha: 0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.s),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchError!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Instruction hint
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_location_alt_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _boundaryPoints.isEmpty
                                ? 'Pan to a corner, then tap  ＋  to pin it'
                                : _boundaryPoints.length < 3
                                    ? 'Need ${3 - _boundaryPoints.length} more corner(s) — keep pinning'
                                    : 'Boundary set! Add more corners or save.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _boundaryPoints.length >= 3
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius:
                                BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            '${_boundaryPoints.length} pts',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _boundaryPoints.length >= 3
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right-side floating buttons ────────────────────────────────
          Positioned(
            right: 14,
            bottom: 190,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ＋ Pin button — adds current crosshair position as a point
                _PinButton(
                  onTap: _addCrosshairPoint,
                  isMoving: _cameraMoving,
                  pointCount: _boundaryPoints.length,
                ),
                const SizedBox(height: 12),
                // My Location
                _MyLocationButton(
                  isLoading: _goingToLocation,
                  onTap: _goToMyLocation,
                ),
              ],
            ),
          ),

          // ── Bottom sheet: clear / save ─────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.18,
            minChildSize: 0.12,
            maxChildSize: 0.28,
            builder: (context, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius:
                              BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                    Text(
                      '${_nameCtrl.text}  •  ${_cropType ?? ''}  •  ${_areaCtrl.text} ha',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _boundaryPoints.isEmpty ? null : _clearPoints,
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveFarm,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Farm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Crosshair overlay ───────────────────────────────────────────────────────

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(painter: _CrosshairPainter()),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const gap = 6.0;
    const arm = 12.0;

    // Shadow pass
    for (final p in [shadowPaint, linePaint]) {
      canvas
        ..drawLine(Offset(cx - arm - gap, cy), Offset(cx - gap, cy), p)
        ..drawLine(Offset(cx + gap, cy), Offset(cx + arm + gap, cy), p)
        ..drawLine(Offset(cx, cy - arm - gap), Offset(cx, cy - gap), p)
        ..drawLine(Offset(cx, cy + gap), Offset(cx, cy + arm + gap), p);
    }

    // Centre dot
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pin (Add Point) button ───────────────────────────────────────────────────

class _PinButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isMoving;
  final int pointCount;

  const _PinButton({
    required this.onTap,
    required this.isMoving,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isMoving ? null : onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isMoving ? Colors.white70 : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_location_alt,
          color: isMoving ? AppColors.textMuted : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ── My Location button ───────────────────────────────────────────────────────

class _MyLocationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _MyLocationButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            : const Icon(
                Icons.my_location,
                color: Color(0xFF1A73E8),
                size: 24,
              ),
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: step == 1 ? 0.5 : 1.0,
          minHeight: 3,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            step == 1 ? 'Step 1 of 2 — Farm Details' : 'Step 2 of 2 — Draw Boundary',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}
