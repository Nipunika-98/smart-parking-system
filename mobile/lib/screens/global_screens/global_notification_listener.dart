import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/models/notification_model.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/services/auth_service.dart';

class GlobalNotificationListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  const GlobalNotificationListener({
    super.key, 
    required this.child, 
    required this.navigatorKey
  });

  @override
  State<GlobalNotificationListener> createState() => _GlobalNotificationListenerState();
}

class _GlobalNotificationListenerState extends State<GlobalNotificationListener> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  StreamSubscription? _subscription;
  String? _lastShownId;
  DateTime? _appStartTime;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _appStartTime = DateTime.now();
    _setupListener();
  }

  void _setupListener() {
    _authService.authStateChanges.listen((user) {
      _subscription?.cancel();
      if (user != null) {
        _subscription = _notificationService
            .getLatestNotificationStream(user.uid)
            .listen((notification) {
          if (notification != null) {
            if (notification.timestamp.isAfter(_appStartTime!) && 
                notification.notificationId != _lastShownId) {
              _lastShownId = notification.notificationId;
              _showBanner(notification);
            }
          }
        });
      }
    });
  }

  void _showBanner(NotificationModel notification) {
    _dismissTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: _BannerWidget(
            notification: notification,
            onTap: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
              widget.navigatorKey.currentState?.pushNamed('/notifications');
            },
            onDismiss: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
            },
          ),
        ),
      ),
    );

    final overlayState = widget.navigatorKey.currentState?.overlay;
    if (overlayState != null) {
      overlayState.insert(_overlayEntry!);
    }

    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _BannerWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) {
        if (details.delta.dy < -5) onDismiss();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active, color: AppColors.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
