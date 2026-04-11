import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/models/notification_model.dart';
import 'package:mobile/screens/global_screens/notification_state.dart' show unreadCountNotifier;
import 'package:mobile/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/user_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _currentNotifications = [];

  @override
  void initState() {
    super.initState();
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} d ago';
    if (diff.inHours > 0) return '${diff.inHours} hr ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} m ago';
    return 'Just now';
  }

  void _markAllRead() async {
    for (var notification in _currentNotifications) {
      if (notification.isUnread) {
        await _notificationService.markAsRead(notification.notificationId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer2<NotificationProvider, UserProvider>(
                builder: (context, notifProvider, userProvider, child) {
                  if (notifProvider.isLoading || userProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final user = userProvider.user;
                  if (user == null) {
                    return const Center(child: Text('Not logged in'));
                  }

                  final registrationDate = user.registrationDate;

                  var filteredList = notifProvider.notifications;
                  
                  filteredList = filteredList.where((n) {
                    return n.timestamp.isAfter(registrationDate) || 
                           n.timestamp.isAtSameMomentAs(registrationDate);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('No notifications yet.'));
                  }

                  _currentNotifications = filteredList;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    unreadCountNotifier.value = _currentNotifications.where((n) => n.isUnread).length;
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _currentNotifications[index];
                      return Dismissible(
                        key: ValueKey(notification.notificationId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          final deletedNotification = notification;
                          _notificationService.deleteNotification(notification.notificationId);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Notification deleted'),
                                behavior: SnackBarBehavior.fixed,
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: Colors.amber,
                                  onPressed: () {
                                    _notificationService.restoreNotification(deletedNotification);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: _notificationCard(notification),
                      );
                    },
                  );
                },
              ),
            ),
            _markAllReadButton(),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Stay updated with your parking activities',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
              ValueListenableBuilder<int>(
                valueListenable: unreadCountNotifier,
                builder: (context, val, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '$val new',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                }
              ),
        ],
      ),
    );
  }

  // ---------------- NOTIFICATION CARD ----------------
  Widget _notificationCard(NotificationModel notification) {
    // Determine icon and colors from dashboard data with sensible fallbacks
    IconData iconData = Icons.notifications;
    if (notification.icon != null) {
      iconData = _getMaterialIcon(notification.icon!);
    } else {
      // Legacy fallback
      switch (notification.type) {
        case NotificationType.payment: iconData = Icons.check_circle; break;
        case NotificationType.parking: iconData = Icons.directions_car; break;
        case NotificationType.warning: iconData = Icons.warning; break;
        case NotificationType.info: iconData = Icons.info; break;
      }
    }

    final Color iconColor = notification.iconColor != null 
        ? _parseHexColor(notification.iconColor!) 
        : (notification.type == NotificationType.payment ? Colors.green : AppColors.primaryColor);
        
    final Color iconBg = notification.iconBg != null 
        ? _parseHexColor(notification.iconBg!) 
        : iconColor.withValues(alpha: 0.12);

    final bool isGlobal = notification.userId == 'ALL';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isUnread ? Colors.white : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (notification.isUnread)
            BoxShadow(
              color: iconColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
        border: Border.all(
          color: notification.isUnread ? iconColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
          width: notification.isUnread ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              if (notification.isUnread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    if (isGlobal)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'GLOBAL',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: notification.isUnread ? Colors.black87 : Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatTime(notification.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getMaterialIcon(String name) {
    switch (name) {
      case 'check_circle': return Icons.check_circle;
      case 'warning': return Icons.warning;
      case 'build': return Icons.build;
      case 'stars': return Icons.stars;
      case 'info': return Icons.info;
      case 'directions_car': return Icons.directions_car;
      case 'notifications': return Icons.notifications;
      default: return Icons.notifications;
    }
  }

  // ---------------- FOOTER BUTTON ----------------
  Widget _markAllReadButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: _markAllRead,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('Mark All as Read'),
        ),
      ),
    );
  }
}
