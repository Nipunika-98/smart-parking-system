import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSlotModel {
  final String slotId;
  final int levelNumber;
  final String slotNumber;
  final String status;
  final DateTime lastUpdated;
  final String? sensorId;
  final String? sensorStatus;
  final DateTime? sensorLastUpdate;

  ParkingSlotModel({
    required this.slotId,
    required this.levelNumber,
    required this.slotNumber,
    required this.status,
    required this.lastUpdated,
    this.sensorId,
    this.sensorStatus,
    this.sensorLastUpdate,
  });

  factory ParkingSlotModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ParkingSlotModel(
      slotId: documentId,
      levelNumber: json['levelNumber'] ?? 1,
      slotNumber: json['slotNumber'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sensorId: json['sensorId'],
      sensorStatus: json['sensorStatus'],
      sensorLastUpdate: (json['sensorLastUpdate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      'slotNumber': slotNumber,
      'status': status,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'sensorId': sensorId,
      'sensorStatus': sensorStatus,
      'sensorLastUpdate': sensorLastUpdate != null ? Timestamp.fromDate(sensorLastUpdate!) : null,
    };
  }

  /// Determines the vehicle type based on the slotNumber string (e.g. "A-01")
  static String getVehicleType(String slotNumber) {
    if (slotNumber.isEmpty) return 'car';
    final parts = slotNumber.split('-');
    if (parts.length < 2) return 'car';
    
    final section = parts.first.toUpperCase();
    final number = int.tryParse(parts.last) ?? 1;

    // Sections B, D, F: 1-5 Car, >5 Bike
    // Sections A, C, E: 1-5 Car, >5 Three-Wheeler
    if (['B', 'D', 'F'].contains(section)) {
      return number <= 5 ? 'car' : 'bike';
    } else {
      return number <= 5 ? 'car' : 'threeWheeler';
    }
  }
}
