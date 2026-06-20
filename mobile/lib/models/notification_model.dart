import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { payment, parking, warning, info }

class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? icon;
  final String? iconColor;
  final String? iconBg;
  final DateTime timestamp;
  final bool isUnread;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    this.iconColor,
    this.iconBg,
    required this.timestamp,
    this.isUnread = true,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String documentId) {
    NotificationType parsedType = NotificationType.info;

    // Support both 'notificationType' (legacy) and 'type' (dashboard)
    final typeStr = (json['type'] ?? json['notificationType'] ?? '').toString().toLowerCase();
    if (typeStr.contains('payment')) {
      parsedType = NotificationType.payment;
    } else if (typeStr.contains('parking')) {
      parsedType = NotificationType.parking;
    } else if (typeStr.contains('warning') || typeStr.contains('overdue')) {
      parsedType = NotificationType.warning;
    }

    // Support both 'isUnread' (legacy) and 'read' (dashboard)
    // Note: Dashboard sends 'read: false' for unread notifications
    bool unread = true;
    if (json.containsKey('read')) {
      unread = !(json['read'] as bool);
    } else if (json.containsKey('isUnread')) {
      unread = json['isUnread'] as bool;
    }

    return NotificationModel(
      notificationId: documentId,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: parsedType,
      icon: json['icon'],
      iconColor: json['iconColor'],
      iconBg: json['iconBg'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUnread: unread,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'icon': icon,
      'iconColor': iconColor,
      'iconBg': iconBg,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': !isUnread,
    };
  }
}
