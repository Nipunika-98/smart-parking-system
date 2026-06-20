import 'package:cloud_firestore/cloud_firestore.dart';

class PricingRateModel {
  final String rateId;
  final String vehicleType;   
  final String type;         
  final String plan;
  final String status;       
  final double firstHour;
  final double subsequentHour;
  final double dailyMax;
  final double lostTicket;
  final DateTime? effectiveDate;
  final String? adminEmail;

  double get hourlyRate => firstHour;

  PricingRateModel({
    required this.rateId,
    required this.vehicleType,
    required this.type,
    required this.plan,
    required this.status,
    required this.firstHour,
    required this.subsequentHour,
    required this.dailyMax,
    required this.lostTicket,
    this.effectiveDate,
    this.adminEmail,
  });

  factory PricingRateModel.fromJson(Map<String, dynamic> json, String documentId) {
    return PricingRateModel(
      rateId: documentId,
      vehicleType: json['vehicleType'] ?? '',
      type: json['type'] ?? '',
      plan: json['plan'] ?? 'Standard Tariff',
      status: json['status'] ?? 'Not Set',
      firstHour: (json['firstHour'] ?? 0.0).toDouble(),
      subsequentHour: (json['subsequentHour'] ?? 0.0).toDouble(),
      dailyMax: (json['dailyMax'] ?? 0.0).toDouble(),
      lostTicket: (json['lostTicket'] ?? 0.0).toDouble(),
      effectiveDate: (json['effectiveDate'] as Timestamp?)?.toDate(),
      adminEmail: json['adminEmail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'type': type,
      'plan': plan,
      'status': status,
      'firstHour': firstHour,
      'subsequentHour': subsequentHour,
      'dailyMax': dailyMax,
      'lostTicket': lostTicket,
      'effectiveDate': effectiveDate != null
          ? Timestamp.fromDate(effectiveDate!)
          : FieldValue.serverTimestamp(),
      'adminEmail': adminEmail,
    };
  }
}
