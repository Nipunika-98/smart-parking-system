import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String adminId;
  final String reportType;
  final String reportPeriod;
  final DateTime generatedTime;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String reportData;

  ReportModel({
    required this.reportId,
    required this.adminId,
    required this.reportType,
    required this.reportPeriod,
    required this.generatedTime,
    required this.dateFrom,
    required this.dateTo,
    required this.reportData,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ReportModel(
      reportId: documentId,
      adminId: json['adminId'] ?? '',
      reportType: json['reportType'] ?? '',
      reportPeriod: json['reportPeriod'] ?? '',
      generatedTime: (json['generatedTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFrom: (json['dateFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateTo: (json['dateTo'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportData: json['reportData'] ?? '{}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adminId': adminId,
      'reportType': reportType,
      'reportPeriod': reportPeriod,
      'generatedTime': Timestamp.fromDate(generatedTime),
      'dateFrom': Timestamp.fromDate(dateFrom),
      'dateTo': Timestamp.fromDate(dateTo),
      'reportData': reportData,
    };
  }
}
