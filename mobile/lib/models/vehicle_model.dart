import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String vehicleId;
  final String userId;
  final String vehicleType;
  final String vehiclePlateNo;
  final bool isPrimary;
  final DateTime registrationDate;
  final bool isActive;

  VehicleModel({
    required this.vehicleId,
    required this.userId,
    required this.vehicleType,
    required this.vehiclePlateNo,
    required this.isPrimary,
    required this.registrationDate,
    required this.isActive,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json, String documentId) {
    return VehicleModel(
      vehicleId: documentId,
      userId: json['userId'] ?? '',
      vehicleType: json['vehicleType'] ?? 'car',
      vehiclePlateNo: json['vehiclePlateNo'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      registrationDate: (json['registrationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'vehicleType': vehicleType,
      'vehiclePlateNo': vehiclePlateNo,
      'isPrimary': isPrimary,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'isActive': isActive,
    };
  }
}
