// lib/models/dashboard_metrics.dart
class DashboardMetrics {
  final int activeShipments;
  final int alertsCount;
  final double avgTemp;
  final double avgHumidity; // Added Humidity
  final bool hasTempData;
  final bool hasHumidityData; // Added Humidity check
  final String overallStatus;

  DashboardMetrics({
    required this.activeShipments,
    required this.alertsCount,
    required this.avgTemp,
    required this.avgHumidity,
    required this.hasTempData,
    required this.hasHumidityData,
    required this.overallStatus,
  });
}