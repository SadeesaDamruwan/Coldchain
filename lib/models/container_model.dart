import 'package:cloud_firestore/cloud_firestore.dart';
class ContainerModel {
  final String id;
  final String location;
  final double temperature;
  final double humidity;
  final String status;
  final String eta;
  final String distance;

  ContainerModel({
    required this.id,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.status,
    required this.eta,
    required this.distance,
  });

  factory ContainerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ContainerModel(
      id: data['id'] ?? '',
      location: data['location'] ?? 'Unknown',
      temperature: (data['temperature'] ?? 0.0).toDouble(),
      humidity: (data['humidity'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Safe',
      eta: data['eta'] ?? 'N/A',
      distance: data['distance'] ?? '0 km',
    );
  }
}