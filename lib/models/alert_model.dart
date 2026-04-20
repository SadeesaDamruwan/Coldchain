import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { critical, warning, info }

class AlertModel {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final DateTime timestamp;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });

  // Helper to convert Firebase data into our clean Flutter object
  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse the string back into our Enum
    final typeString = data['type'] ?? 'info';
    AlertType alertType = AlertType.info;
    if (typeString == 'critical') alertType = AlertType.critical;
    if (typeString == 'warning') alertType = AlertType.warning;

    return AlertModel(
      id: doc.id,
      title: data['title'] ?? 'System Alert',
      description: data['description'] ?? '',
      type: alertType,
      // Fallback to now if the server timestamp hasn't synced yet
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}