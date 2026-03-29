class Farmer {
  final String farmerId;
  final String name;
  final String region;
  final int farmPlots;
  final double totalHectares;
  final int activeAlerts;
  final int pendingClaims;

  const Farmer({
    required this.farmerId,
    required this.name,
    required this.region,
    required this.farmPlots,
    required this.totalHectares,
    required this.activeAlerts,
    required this.pendingClaims,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
