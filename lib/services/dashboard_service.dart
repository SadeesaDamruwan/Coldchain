// lib/services/dashboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_metrics.dart';

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. Filtered Stream for KPI Metrics ---
  Stream<DashboardMetrics> getMetricsStream(String? containerId) {
    Query query = _db.collection('containers');

    // Only fetch the selected container if one is pinned!
    if (containerId != null) {
      query = query.where('id', isEqualTo: containerId);
    }

    return query.snapshots().map((snapshot) {
      int activeShipments = snapshot.docs.length;
      int alertsCount = 0;
      double totalTemp = 0.0;
      int tempCount = 0;
      double totalHumidity = 0.0;
      int humidityCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['status'] == 'Critical' || data['status'] == 'Warning') alertsCount++;

        if (data.containsKey('temperature')) {
          totalTemp += (data['temperature'] as num).toDouble();
          tempCount++;
        }
        if (data.containsKey('humidity')) {
          totalHumidity += (data['humidity'] as num).toDouble();
          humidityCount++;
        }
      }

      return DashboardMetrics(
        activeShipments: activeShipments,
        alertsCount: alertsCount,
        avgTemp: tempCount > 0 ? totalTemp / tempCount : 0.0,
        avgHumidity: humidityCount > 0 ? totalHumidity / humidityCount : 0.0,
        hasTempData: tempCount > 0,
        hasHumidityData: humidityCount > 0,
        overallStatus: alertsCount > 0 ? 'Action Needed' : 'Optimal',
      );
    });
  }

  // --- 2. Filtered Stream for Telemetry Chart ---
  Stream<List<FlSpot>> getChartStream(String? containerId) {
    Query query = _db.collection('telemetry');

    // Only plot points for the pinned container!
    if (containerId != null) {
      query = query.where('containerId', isEqualTo: containerId);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(6)
        .snapshots()
        .map((snapshot) {

      final docs = snapshot.docs.reversed.toList();
      List<FlSpot> spots = [];

      for (int i = 0; i < docs.length; i++) {
        final data = docs[i].data() as Map<String, dynamic>;
        double temp = data.containsKey('temperature') ? (data['temperature'] as num).toDouble() : 0.0;
        spots.add(FlSpot((i * 4).toDouble(), temp));
      }

      return spots;
    });
  }
}