import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream user notifications (User-specific + Broadcast)
  Stream<List<NotificationModel>> getUserNotifications(String userId, {DateTime? minTimestamp}) {
    return _firestore
        .collection('notifications')
        .where('userId', whereIn: [userId, 'ALL'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
              .toList();
          
          if (minTimestamp != null) {
            // Filter out notifications older than minTimestamp
            list = list.where((n) => n.timestamp.isAfter(minTimestamp) || n.timestamp.isAtSameMomentAs(minTimestamp)).toList();
          }
          return list;
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update both 'read' (dashboard) and 'isUnread' (legacy) for full compatibility
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'isUnread': false,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Admin/System: Send notification
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Restore notification (Undo)
  Future<void> restoreNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to restore notification: $e');
    }
  }

  // Stream ONLY the latest notification (for in-app banner)
  Stream<NotificationModel?> getLatestNotificationStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', whereIn: [userId, 'ALL'])
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return NotificationModel.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id);
        });
  }

  // Send Initial Welcome Notification
  Future<void> sendWelcomeNotification(String userId) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Welcome to SmartPark! 🚗',
        'message': 'We are glad to have you here. You can now start managing your parking sessions seamlessly.',
        'type': 'info',
        'timestamp': Timestamp.now(),
        'read': false,
        'isUnread': true,
        'icon': 'stars',
        'iconColor': '#4F46E5',
        'iconBg': '#EEF2FF',
      });
    } catch (e) {
      throw Exception('Failed to send welcome notification: $e');
    }
  }
}
