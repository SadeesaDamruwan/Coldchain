import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

class AlertsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. Stream Alerts in Real-Time ---
  Stream<List<AlertModel>> get alertsStream {
    return _db
        .collection('alerts')
        .orderBy('timestamp', descending: true) // Newest at the top
        .limit(50) // Only load the 50 most recent to save data
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList();
    });
  }

  // --- 2. Push a Test Alert ---
  Future<void> addTestAlert() async {
    await _db.collection('alerts').add({
      'title': '🚨 Door Opened!',
      'description': 'Test container door was opened unexpectedly.',
      'type': 'critical',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}