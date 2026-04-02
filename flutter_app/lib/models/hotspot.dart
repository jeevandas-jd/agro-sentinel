import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LandParcel {
  final String parcelId;
  final String ownerName;
  final double registeredAreaHa;
  final String cropSeason;

  const LandParcel({
    required this.parcelId,
    required this.ownerName,
    required this.registeredAreaHa,
    required this.cropSeason,
  });
}

class Hotspot {
  final String id;
  final String status;
  final String cropType;
  final double ndviScore;
  final double ndviDelta;
  final String severity;
  final double estimatedAreaHa;
  final String damageCause;
  final String detectedAt;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final LandParcel? landParcel;

  const Hotspot({
    required this.id,
    required this.status,
    required this.cropType,
    required this.ndviScore,
    required this.ndviDelta,
    required this.severity,
    required this.estimatedAreaHa,
    required this.damageCause,
    required this.detectedAt,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.landParcel,
  });

  Color get severityColor {
    switch (severity) {
      case 'high':
        return AppColors.alertHigh;
      case 'medium':
        return AppColors.alertMedium;
      default:
        return AppColors.alertLow;
    }
  }

  String get severityLabel {
    switch (severity) {
      case 'high':
        return 'HIGH RISK';
      case 'medium':
        return 'MEDIUM RISK';
      default:
        return 'LOW RISK';
    }
  }

  String get ndviDeltaLabel {
    final pct = (ndviDelta * 100).toStringAsFixed(0);
    return '$pct%';
  }

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toInt()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
