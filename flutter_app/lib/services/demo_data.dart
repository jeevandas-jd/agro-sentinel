import '../models/farmer.dart';
import '../models/hotspot.dart';

class DemoData {
  static const Farmer farmer = Farmer(
    farmerId: 'DEMO-F-001',
    name: 'Rajan Pillai',
    region: 'Palakkad District, Kerala',
    farmPlots: 3,
    totalHectares: 12.4,
    activeAlerts: 3,
    pendingClaims: 2,
  );

  static const List<Hotspot> hotspots = [
    Hotspot(
      id: 'HS-001',
      status: 'pending',
      cropType: 'Paddy (Rice)',
      ndviScore: 0.18,
      ndviDelta: -0.42,
      severity: 'high',
      estimatedAreaHa: 3.2,
      damageCause: 'Elephant raid',
      detectedAt: '10 Mar 2024 • 08:30',
      latitude: 10.7867,
      longitude: 76.6548,
      distanceKm: 1.4,
      landParcel: LandParcel(
        parcelId: 'LND-KL-011-2201',
        ownerName: 'Rajan Pillai',
        registeredAreaHa: 4.0,
        cropSeason: 'Virippu 2024',
      ),
    ),
    Hotspot(
      id: 'HS-002',
      status: 'pending',
      cropType: 'Banana',
      ndviScore: 0.22,
      ndviDelta: -0.31,
      severity: 'medium',
      estimatedAreaHa: 1.8,
      damageCause: 'Flood damage',
      detectedAt: '11 Mar 2024 • 14:15',
      latitude: 10.7901,
      longitude: 76.6610,
      distanceKm: 2.1,
      landParcel: LandParcel(
        parcelId: 'LND-KL-011-2205',
        ownerName: 'Rajan Pillai',
        registeredAreaHa: 2.5,
        cropSeason: 'Mundakan 2024',
      ),
    ),
    Hotspot(
      id: 'HS-003',
      status: 'verified',
      cropType: 'Coconut',
      ndviScore: 0.29,
      ndviDelta: -0.24,
      severity: 'medium',
      estimatedAreaHa: 2.8,
      damageCause: 'Wind damage',
      detectedAt: '09 Mar 2024 • 11:45',
      latitude: 10.7843,
      longitude: 76.6481,
      distanceKm: 0.8,
      landParcel: LandParcel(
        parcelId: 'LND-KL-011-2209',
        ownerName: 'Rajan Pillai',
        registeredAreaHa: 3.5,
        cropSeason: 'Annual 2024',
      ),
    ),
  ];

  static const Map<String, dynamic> aiAnalysis = {
    'evidenceId': 'EVD-001-A',
    'damagePercentage': 67.4,
    'healthyPixelRatio': 0.326,
    'damagedPixelRatio': 0.674,
    'confidenceScore': 0.89,
    'damageClass': 'Crop destruction — Elephant raid',
    'ndviBefore': 0.60,
    'ndviAfter': 0.18,
    'satelliteSource': 'Planet NICFI',
    'detectionMethod': 'Delta NDVI Analysis',
  };

  static const Map<String, dynamic> claim = {
    'claimId': 'CLM-2024-001',
    'status': 'ready_for_export',
    'createdAt': '12 Mar 2024 • 12:00',
    'hotspotId': 'HS-001',
    'submittedTo': 'AIMS Portal',
  };

  static const Map<String, dynamic> claim2 = {
    'claimId': 'CLM-2024-002',
    'status': 'under_review',
    'createdAt': '11 Mar 2024 • 18:30',
    'hotspotId': 'HS-002',
    'submittedTo': 'AIMS Portal',
  };

  /// The 4 evidence chain steps for the pipeline
  static const List<Map<String, String>> evidenceChain = [
    {
      'step': '1',
      'title': 'Satellite Detection',
      'subtitle': 'NDVI anomaly detected via Planet NICFI • 10 Mar 2024',
      'icon': 'satellite',
    },
    {
      'step': '2',
      'title': 'GPS Truth Walk',
      'subtitle': 'Farmer navigated to hotspot using AgriSentinel • 12 Mar 2024',
      'icon': 'gps',
    },
    {
      'step': '3',
      'title': 'AI Ground Evidence',
      'subtitle':
          'U-Net scan: 67.4% damage • Confidence 89% • 12 Mar 2024',
      'icon': 'ai',
    },
    {
      'step': '4',
      'title': 'Claim Dossier Generated',
      'subtitle': 'CLM-2024-001 • AIMS Compliant PDF • 12 Mar 2024',
      'icon': 'doc',
    },
  ];
}
