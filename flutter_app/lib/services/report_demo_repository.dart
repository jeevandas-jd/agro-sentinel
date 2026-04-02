import '../models/disaster_event_model.dart';
import '../models/farm_model.dart';
import '../models/farmer_model.dart';
import '../models/hotspot_model.dart';
import '../models/lat_lng.dart';

class ReportDemoRepository {
  const ReportDemoRepository._();

  static FarmerModel farmerFor({
    required String uid,
    required String displayName,
    required String email,
  }) {
    return FarmerModel(
      uid: uid,
      name: displayName.isEmpty ? 'Farmer' : displayName,
      phone: '+91 9876543210',
      email: email,
      aadhaarLast4: '2048',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    );
  }

  static FarmModel farmFor(String farmerUid) {
    const center = LatLng(latitude: 10.5231, longitude: 76.2144);
    return const FarmModel(
      id: 'farm-001',
      farmerUid: 'farmer-uid',
      name: 'Sentinel Farm Plot A',
      surveyNumber: 'SY-11-204',
      cropType: 'Coconut',
      areaHectares: 3.2,
      boundaries: <LatLng>[
        LatLng(latitude: 10.5241, longitude: 76.2132),
        LatLng(latitude: 10.5248, longitude: 76.2150),
        LatLng(latitude: 10.5228, longitude: 76.2160),
        LatLng(latitude: 10.5219, longitude: 76.2140),
      ],
      center: center,
      createdAt: null,
    ).copyWithFarmer(farmerUid);
  }

  static List<DisasterEventModel> eventsFor({
    required String farmerUid,
    required String farmId,
  }) {
    final now = DateTime.now();
    return <DisasterEventModel>[
      DisasterEventModel(
        id: 'evt-001',
        farmerUid: farmerUid,
        farmId: farmId,
        disasterType: 'Wildlife Attack',
        farmerDescription: 'Elephants damaged young trees near the canal side.',
        occurredAt: now.subtract(const Duration(days: 3)),
        reportedAt: now.subtract(const Duration(days: 2)),
        status: 'submitted',
        hotspots: <HotspotModel>[
          HotspotModel(
            id: '1',
            latitude: 10.5236,
            longitude: 76.2146,
            photoUrl: 'local://photo1.jpg',
            aiResult: 'DAMAGED',
            aiConfidence: 0.94,
            gradcamUrl: null,
            treesLost: 14,
            capturedAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        aiNarrative: 'The affected region shows clustered canopy loss and trampling.',
        totalTreesLost: 14,
        estimatedLossInr: 68000,
      ),
      DisasterEventModel(
        id: 'evt-002',
        farmerUid: farmerUid,
        farmId: farmId,
        disasterType: 'Storm/Wind',
        farmerDescription: 'Strong winds bent trees in the southern strip.',
        occurredAt: now.subtract(const Duration(days: 12)),
        reportedAt: now.subtract(const Duration(days: 11)),
        status: 'verified',
        hotspots: const <HotspotModel>[],
        aiNarrative: 'Damage is sparse and mostly non-fatal.',
        totalTreesLost: 4,
        estimatedLossInr: 20000,
      ),
      DisasterEventModel(
        id: 'evt-003',
        farmerUid: farmerUid,
        farmId: farmId,
        disasterType: 'Flood',
        farmerDescription: 'Low section remained submerged for 2 days.',
        occurredAt: now.subtract(const Duration(days: 1)),
        reportedAt: now,
        status: 'draft',
        hotspots: const <HotspotModel>[],
        aiNarrative: null,
        totalTreesLost: 0,
        estimatedLossInr: 0,
      ),
    ];
  }
}

extension on FarmModel {
  FarmModel copyWithFarmer(String farmerUid) {
    return FarmModel(
      id: id,
      farmerUid: farmerUid,
      name: name,
      surveyNumber: surveyNumber,
      cropType: cropType,
      areaHectares: areaHectares,
      boundaries: boundaries,
      center: center,
      createdAt: createdAt,
    );
  }
}
