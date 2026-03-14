import '../models/farmer.dart';
import '../models/hotspot.dart';

class DemoData {
  static const Farmer farmer = Farmer(
    farmerId: 'DEMO-F-001',
    name: 'Rajan Pillai',
    region: 'Palakkad District, Kerala',
    farmPlots: 3,
    totalHectares: 12.4,
    activeAlerts: 2,
    pendingClaims: 1,
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
  };

  static const Map<String, dynamic> claim = {
    'claimId': 'CLM-2024-001',
    'status': 'ready_for_export',
    'createdAt': '12 Mar 2024 • 12:00',
  };
}
