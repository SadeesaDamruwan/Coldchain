import 'package:flutter/material.dart';
import '../models/container_model.dart';
import 'dashboard_screen.dart';
import 'shipments_screen.dart';
import 'alerts_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 1. Removed _activelyTrackedContainer and _navigateToTrackTab logic

  @override
  Widget build(BuildContext context) {
    // 2. Updated pages list (Removed TrackScreen)
    final List<Widget> pages = [
      const DashboardScreen(),
      ShipmentsScreen(
        onTrackContainer: (container) {
          // Since we removed tracking, we can just navigate to the Alerts screen
          // or stay on Shipments. For now, let's just stay here.
          debugPrint("Track clicked for ${container.id}, but tracking is disabled.");
        },
      ),
      const AlertsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 16, top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'Home', Icons.home_filled, Icons.home_outlined),
            _buildNavItem(1, 'Shipments', Icons.inventory_2, Icons.inventory_2_outlined),
            _buildNavItem(2, 'Alerts', Icons.notifications, Icons.notifications_none),
            // 3. Removed the Track Nav Item from here
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade500,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}