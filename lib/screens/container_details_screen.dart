// lib/screens/container_details_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/container_model.dart';

class ContainerDetailsScreen extends StatelessWidget {
  final ContainerModel container;
  final VoidCallback onTrackPressed;

  const ContainerDetailsScreen({super.key, required this.container, required this.onTrackPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Container ${container.id}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Hero Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(Icons.inventory_2, size: 80, color: Colors.blue.shade600),
              ),
            ),
            const SizedBox(height: 40),

            const Text('Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on, color: Colors.grey.shade600),
              title: const Text('Current Location'),
              subtitle: Text(container.location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.thermostat, color: Colors.grey.shade600),
              title: const Text('Temperature'),
              subtitle: Text('${container.temperature}°C', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle, color: Colors.grey.shade600),
              title: const Text('Status'),
              subtitle: Text(container.status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: container.status == 'Safe' ? Colors.green : Colors.red)),
            ),

            const Spacer(),

            // --- 1. The Track Button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onTrackPressed,
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text('Track on Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- 2. THE NEW SELECT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Save the ID to the phone's permanent memory
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selected_container_id', container.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${container.id} pinned to Dashboard!'),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                        )
                    );
                  }
                },
                icon: const Icon(Icons.dashboard_customize),
                label: const Text('Pin to Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  side: BorderSide(color: Colors.blue.shade200, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}