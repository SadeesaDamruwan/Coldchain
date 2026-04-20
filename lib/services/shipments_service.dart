// lib/services/shipments_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/container_model.dart';

class ShipmentsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream for the shipments list
  Stream<List<ContainerModel>> get containersStream {
    return _db.collection('containers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ContainerModel.fromFirestore(doc)).toList();
    });
  }

  // Method to add a new container
  Future<void> addContainer({
    required String id,
    required String location,
    required double initialTemp,
    required double initialHumidity,
  }) async {
    await _db.collection('containers').doc(id).set({
      'id': id,
      'location': location,
      'temperature': initialTemp,
      'humidity': initialHumidity,
      'status': 'Safe',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}