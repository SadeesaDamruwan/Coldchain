// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_metrics.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _cardsController;
  late AnimationController _chartController;
  final DashboardService _dashboardService = DashboardService();

  // Local Memory State
  String? _pinnedContainerId;
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedContainer(); // Load from memory on startup

    _cardsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _chartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _cardsController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _chartController.forward();
    });
  }

  // --- Read Phone Memory ---
  Future<void> _loadPinnedContainer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinnedContainerId = prefs.getString('selected_container_id');
      _isLoadingPrefs = false;
    });
  }

  // --- Clear Memory ---
  Future<void> _clearPinnedContainer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_container_id');
    setState(() {
      _pinnedContainerId = null;
    });
  }

  @override
  void dispose() {
    _cardsController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- Static App Bar ---
          SliverAppBar(
            pinned: true, backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0,
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.shade200, height: 1)),
            title: const Text('Cold Chain', style: TextStyle(color: Color(0xFF1F2937), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            actions: [
              IconButton(icon: const Icon(Icons.settings_outlined), color: const Color(0xFF4B5563), onPressed: () {}),
              IconButton(icon: const Icon(Icons.person_outline), color: const Color(0xFF4B5563), iconSize: 28, onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Dynamic Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(
                            _pinnedContainerId != null ? 'Tracking: $_pinnedContainerId' : 'Tracking: All Fleet',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                      if (_pinnedContainerId != null)
                        TextButton(
                          onPressed: _clearPinnedContainer,
                          child: const Text('View All', style: TextStyle(color: Colors.grey)),
                        )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- REAL-TIME KPI CARDS ---
                  StreamBuilder<DashboardMetrics>(
                    // Pass the pinned ID into the stream!
                      stream: _dashboardService.getMetricsStream(_pinnedContainerId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Center(child: Text('Error loading data'));
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final metrics = snapshot.data!;
                        String avgTempString = metrics.hasTempData ? metrics.avgTemp.toStringAsFixed(1) : '--';
                        String avgHumidityString = metrics.hasHumidityData ? metrics.avgHumidity.toStringAsFixed(0) : '--';
                        Color overallColor = metrics.alertsCount > 0 ? Colors.orange : Colors.green;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildAnimatedCard(index: 0, child: _buildMetricCard(title: 'Temperature', value: avgTempString, unit: '°C', status: metrics.overallStatus, statusColor: overallColor, icon: Icons.thermostat, iconBgColor: overallColor.withOpacity(0.1)))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildAnimatedCard(index: 1, child: _buildMetricCard(title: 'Humidity', value: avgHumidityString, unit: '%', status: 'Tracking', statusColor: Colors.blue, icon: Icons.water_drop_outlined, iconBgColor: Colors.blue.shade50))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildAnimatedCard(index: 2, child: _buildMetricCard(title: 'Alerts', value: metrics.alertsCount.toString(), unit: '', status: metrics.alertsCount > 0 ? 'Check Active' : 'All Clear', statusColor: metrics.alertsCount > 0 ? Colors.red : Colors.green, icon: Icons.warning_amber_rounded, iconBgColor: metrics.alertsCount > 0 ? Colors.red.shade50 : Colors.green.shade50))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildAnimatedCard(index: 3, child: _buildMetricCard(title: 'Active', value: metrics.activeShipments.toString(), unit: '', status: 'Containers', statusColor: Colors.grey.shade600, icon: Icons.inventory_2_outlined, iconBgColor: Colors.blue.shade50, iconColor: Colors.blue))),
                              ],
                            ),
                          ],
                        );
                      }
                  ),
                  const SizedBox(height: 24),

                  // --- REAL-TIME CHART ---
                  StreamBuilder<List<FlSpot>>(
                    // Pass the pinned ID into the stream!
                      stream: _dashboardService.getChartStream(_pinnedContainerId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox(height: 200, child: Center(child: Text("Waiting for sensor data...")));
                        }

                        final realtimeSpots = snapshot.data!;

                        return AnimatedBuilder(
                            animation: _chartController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: (_chartController.value * 2).clamp(0.0, 1.0),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Live Telemetry Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                          height: 180,
                                          child: ClipRect(
                                              clipper: ChartDrawingClipper(_chartController.value),
                                              child: LineChart(_mainData(realtimeSpots))
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                        );
                      }
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    final double delay = index * 0.15;
    final Animation<double> animation = CurvedAnimation(parent: _cardsController, curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutBack));
    return AnimatedBuilder(
      animation: animation,
      builder: (context, widget) => Transform.translate(offset: Offset(0, 40 * (1 - animation.value)), child: Opacity(opacity: animation.value.clamp(0.0, 1.0), child: widget)),
      child: child,
    );
  }

  Widget _buildMetricCard({required String title, required String value, required String unit, required String status, required Color statusColor, required IconData icon, required Color iconBgColor, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor ?? statusColor, size: 20)), const SizedBox(width: 8), Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500))]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)), if (unit.isNotEmpty) ...[const SizedBox(width: 4), Text(unit, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade500))]]),
          const SizedBox(height: 4),
          Row(children: [Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500))]),
        ],
      ),
    );
  }

  LineChartData _mainData(List<FlSpot> realtimeSpots) {
    double minY = realtimeSpots.isEmpty ? 0 : realtimeSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    double maxY = realtimeSpots.isEmpty ? 10 : realtimeSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.white,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fitInsideHorizontally: true, fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final tempString = spot.y.toStringAsFixed(1);
              return LineTooltipItem('Reading\n', const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15, height: 1.5), children: [TextSpan(text: 'temp : $tempString', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 14))]);
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) => TouchedSpotIndicatorData(FlLine(color: Colors.grey.shade400, strokeWidth: 1.5), FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: Colors.blue, strokeWidth: 3, strokeColor: Colors.white)))).toList();
        },
      ),
      gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 3, verticalInterval: 4, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5]), getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5])),
      titlesData: FlTitlesData(
        show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 3, reservedSize: 30, getTitlesWidget: (value, meta) => SideTitleWidget(axisSide: meta.axisSide, child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12))))),
      ),
      borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade300), left: BorderSide(color: Colors.grey.shade300))),
      minX: 0, maxX: 20,
      minY: minY, maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: realtimeSpots,
          isCurved: true, color: Colors.blue, barWidth: 3, isStrokeCapRound: true,
          dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
            final double spotFraction = spot.x / 20.0;
            double dotScale = 0.0;
            if (_chartController.value >= spotFraction) {
              dotScale = Curves.easeOutBack.transform(((_chartController.value - spotFraction) * 10).clamp(0.0, 1.0));
            }
            return FlDotCirclePainter(radius: 4 * dotScale, color: Colors.blue, strokeWidth: 2 * dotScale, strokeColor: Colors.white);
          }),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}

class ChartDrawingClipper extends CustomClipper<Rect> {
  final double fraction;
  ChartDrawingClipper(this.fraction);
  @override
  Rect getClip(Size size) => Rect.fromLTRB(-10, -10, size.width * fraction + 10, size.height + 10);
  @override
  bool shouldReclip(ChartDrawingClipper oldClipper) => oldClipper.fraction != fraction;
}