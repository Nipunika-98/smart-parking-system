import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/models/notification_model.dart';
import 'package:mobile/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  DateTime? _userCreatedAt;

  List<NotificationModel> get notifications {
    return _notifications.where((n) {
      if (n.userId == 'ALL') {
        if (_userCreatedAt == null) return false;
        return n.timestamp.isAfter(_userCreatedAt!.toLocal());
      }
      return true;
    }).toList();
  }

  bool get isLoading => _isLoading;
  int get unreadCount => notifications.where((n) => n.isUnread).length;

  void updateUserId(String? userId, DateTime? userCreatedAt) {
    _userCreatedAt = userCreatedAt;
    _subscription?.cancel();
    if (userId == null) {
      _notifications = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _notificationService.getUserNotifications(userId).listen((data) {
      _notifications = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
