import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/screens/active_parking_session_screen.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/notifications_screen.dart';
import 'package:mobile/screens/history_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/qr_scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/notification_provider.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  final List<Widget> _pages = const [
    HomeScreen(),
    ActiveParkingSessionScreen(),
    NotificationsScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;
  bool _showFab = true;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _showFab = index == 0;
    });
  }

  Widget? _buildFab() {
    return AnimatedScale(
      scale: _showFab ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrScanScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: const Text('Scan QR', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onTabTapped,

        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Ticket'),
          BottomNavigationBarItem(
            icon: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                final count = notificationProvider.unreadCount;
                return Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Alerts',
          ),

          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
