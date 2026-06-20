import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSessionModel {
  final String sessionId;
  final String userId;
  final String slotId;
  final String ticketNumber;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String entryScannedBy;
  final String? exitScannedBy;
  final DateTime? paymentTime;
  final String paymentStatus;
  final String? markerByAdmin;
  final String qrCodeData;
  final double? totalAmount;

  ParkingSessionModel({
    required this.sessionId,
    required this.userId,
    required this.slotId,
    required this.ticketNumber,
    required this.entryTime,
    this.exitTime,
    required this.entryScannedBy,
    this.exitScannedBy,
    this.paymentTime,
    required this.paymentStatus,
    this.markerByAdmin,
    required this.qrCodeData,
    this.totalAmount,
  });

  factory ParkingSessionModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ParkingSessionModel(
      sessionId: documentId,
      userId: json['userId'] ?? '',
      slotId: json['slotId'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      entryTime: (json['entryTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exitTime: (json['exitTime'] as Timestamp?)?.toDate(),
      entryScannedBy: json['entryScannedBy'] ?? '',
      exitScannedBy: json['exitScannedBy'],
      paymentTime: (json['paymentTime'] as Timestamp?)?.toDate(),
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      markerByAdmin: json['markerByAdmin'],
      qrCodeData: json['qrCodeData'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'slotId': slotId,
      'ticketNumber': ticketNumber,
      'entryTime': Timestamp.fromDate(entryTime),
      'exitTime': exitTime != null ? Timestamp.fromDate(exitTime!) : null,
      'entryScannedBy': entryScannedBy,
      'exitScannedBy': exitScannedBy,
      'paymentTime': paymentTime != null ? Timestamp.fromDate(paymentTime!) : null,
      'paymentStatus': paymentStatus,
      'markerByAdmin': markerByAdmin,
      'qrCodeData': qrCodeData,
      'totalAmount': totalAmount,
    };
  }
}
