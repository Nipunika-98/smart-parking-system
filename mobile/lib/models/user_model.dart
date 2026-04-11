import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final DateTime registrationDate;
  final bool isActive;
  final bool isFirstLogin;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.registrationDate,
    required this.isActive,
    this.isFirstLogin = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      userId: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      registrationDate: (json['registrationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      isFirstLogin: json['isFirstLogin'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'isActive': isActive,
      'isFirstLogin': isFirstLogin,
    };
  }
}
