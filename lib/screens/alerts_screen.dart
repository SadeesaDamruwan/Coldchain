import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../models/alert_model.dart';
import '../services/alerts_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with TickerProviderStateMixin {
  String _selectedFilter = 'All';
  late Timer _timer;
  late AnimationController _animationController;

  // Instantiate our clean backend service
  final AlertsService _alertsService = AlertsService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    // Rebuilds the UI every minute so the "Time Ago" text updates automatically
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // --- Initialize System Notifications ---
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // --- Trigger a Real System Notification & Firebase Push ---
  Future<void> _simulateIncomingAlert() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'cold_chain_alerts', 'Critical Alerts',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    // 1. Show the local phone pop-up
    await flutterLocalNotificationsPlugin.show(
      0,
      '🚨 Door Opened!',
      'Test container door was opened unexpectedly.',
      platformChannelSpecifics,
    );

    // 2. Push it to Firebase (The StreamBuilder will automatically catch this and animate it in!)
    await _alertsService.addTestAlert();

    // Reset animation so the new item slides in
    _animationController.reset();
    _animationController.forward();
  }

  // --- Helper to convert DateTime ---
  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hour(s) ago';
    return '${difference.inDays} day(s) ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _simulateIncomingAlert,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.notification_add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- App Bar ---
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 20, right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cold Chain',
                  style: TextStyle(color: Color(0xFF1F2937), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.settings_outlined), color: const Color(0xFF4B5563), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.person_outline), color: const Color(0xFF4B5563), iconSize: 28, onPressed: () {}),
                  ],
                )
              ],
            ),
          ),

          // --- Real-Time Content Area ---
          Expanded(
            child: StreamBuilder<List<AlertModel>>(
                stream: _alertsService.alertsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading alerts.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allAlerts = snapshot.data!;

                  // Calculate dynamic counts based on the live database
                  final int allCount = allAlerts.length;
                  final int criticalCount = allAlerts.where((a) => a.type == AlertType.critical).length;
                  final int warningCount = allAlerts.where((a) => a.type == AlertType.warning).length;
                  final int infoCount = allAlerts.where((a) => a.type == AlertType.info).length;

                  // Apply Local Filtering
                  List<AlertModel> filteredAlerts;
                  if (_selectedFilter == 'Critical') {
                    filteredAlerts = allAlerts.where((a) => a.type == AlertType.critical).toList();
                  } else if (_selectedFilter == 'Warning') {
                    filteredAlerts = allAlerts.where((a) => a.type == AlertType.warning).toList();
                  } else if (_selectedFilter == 'Info') {
                    filteredAlerts = allAlerts.where((a) => a.type == AlertType.info).toList();
                  } else {
                    filteredAlerts = allAlerts;
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alerts',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 20),

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('All', allCount),
                                    _buildFilterChip('Critical', criticalCount),
                                    _buildFilterChip('Warning', warningCount),
                                    _buildFilterChip('Info', infoCount),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // --- Empty State ---
                      if (filteredAlerts.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                'No alerts found.',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ),
                          ),
                        ),

                      // --- Animated Alert Cards List ---
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return _buildAnimatedAlertCard(filteredAlerts[index], index);
                            },
                            childCount: filteredAlerts.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  // --- Dynamic Chip Builder ---
  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    final displayText = '$label ($count)';

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() => _selectedFilter = label);
          _animationController.reset();
          _animationController.forward();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              color: isSelected ? Colors.blue.shade700 : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // --- Animated Alert Card Builder ---
  Widget _buildAnimatedAlertCard(AlertModel alert, int index) {
    final double delay = (index * 0.1).clamp(0.0, 1.0);

    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(delay, (delay + 0.6).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    ));

    final Animation<double> fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, (delay + 0.6).clamp(0.0, 1.0), curve: Curves.easeIn),
        )
    );

    Color cardBorderColor;
    Color iconBgColor;
    Color iconColor;
    IconData iconData;
    String badgeText;

    switch (alert.type) {
      case AlertType.critical:
        cardBorderColor = Colors.red.shade200;
        iconBgColor = Colors.red.shade50;
        iconColor = Colors.red;
        iconData = Icons.warning_amber_rounded;
        badgeText = 'Critical';
        break;
      case AlertType.warning:
        cardBorderColor = Colors.grey.shade100;
        iconBgColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        iconData = Icons.error_outline;
        badgeText = 'Warning';
        break;
      case AlertType.info:
      default:
        cardBorderColor = Colors.grey.shade100;
        iconBgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade700;
        iconData = Icons.info_outline;
        badgeText = 'Info';
        break;
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor, width: alert.type == AlertType.critical ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(alert.timestamp),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}