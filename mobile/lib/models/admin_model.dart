import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String adminId;
  final String adminName;
  final String email;
  final String role;
  final DateTime registrationDate;

  AdminModel({
    required this.adminId,
    required this.adminName,
    required this.email,
    required this.role,
    required this.registrationDate,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json, String documentId) {
    return AdminModel(
      adminId: documentId,
      adminName: json['adminName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      registrationDate: (json['registrationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adminName': adminName,
      'email': email,
      'role': role,
      'registrationDate': Timestamp.fromDate(registrationDate),
    };
  }
}
