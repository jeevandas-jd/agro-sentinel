class LossCalculator {
  /// Canopy constants from the referenced paper (sq.m per tree canopy).
  static const Map<String, double> canopyConstants = {
    'Coconut': 38.5,
    'Rubber': 25.0,
    'Plantain': 12.0,
  };

  /// Market rates per tree (INR) — approximate 2026 values.
  static const Map<String, double> treeValueInr = {
    'Coconut': 7000.0,
    'Rubber': 5000.0,
    'Plantain': 2000.0,
  };

  static int estimateTreesLost(double damagedAreaSqM, String cropType) {
    final constant = canopyConstants[cropType] ?? canopyConstants['Coconut']!;
    if (damagedAreaSqM <= 0) return 0;
    return (damagedAreaSqM / constant).round().clamp(0, 1 << 30);
  }

  static double estimateLossInr(int treesLost, String cropType) {
    final rate = treeValueInr[cropType] ?? treeValueInr['Coconut']!;
    if (treesLost <= 0) return 0;
    return treesLost * rate;
  }
}

