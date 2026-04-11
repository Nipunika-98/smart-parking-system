
import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/screens/level_detail.dart';
import 'package:mobile/screens/qr_scan_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/user_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/models/parking_slot.dart';
import 'package:mobile/utils/ui_utils.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/parking_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndLoadProfile();
    });
  }

  Future<void> _initAndLoadProfile() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) {
        await userProvider.loadUser(uid);
      }
      
      final profile = userProvider.user;
      if (profile != null && profile.isFirstLogin) {
        await _handleFirstLogin(uid);
        await userProvider.loadUser(uid); // Refresh profile after update
      }
    } catch (_) {}
  }

  Future<void> _handleFirstLogin(String uid) async {
    try {
      // 1. Send Welcome Notification
      await _notificationService.sendWelcomeNotification(uid);
      
      // 2. Update user profile to mark first login as complete
      await _userService.updateUserProfile(uid, {'isFirstLogin': false});
      
      // 3. Show a welcome SnackBar
      if (mounted) {
        UIUtils.showSnackBar(
          context, 
          'Welcome to SmartPark! 🚗 We are glad to have you here.',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Error handling first login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F7FB),
      child: SafeArea(
        child: Consumer<ParkingProvider>(
          builder: (context, parkingProvider, _) {
            final slots = parkingProvider.slots;
            final isLive = !parkingProvider.isLoadingSlots;

            // Group by section letter — matches dashboard logic exactly:
            // A/B → Level 1, C/D → Level 2, E/F → Level 3
            final Map<int, List<ParkingSlotModel>> byLevel = {1: [], 2: [], 3: []};
            for (final s in slots) {
              final section = s.slotNumber.split('-').first.toUpperCase();
              if (['A', 'B'].contains(section)) {
                byLevel[1]!.add(s);
              } else if (['C', 'D'].contains(section)) {
                byLevel[2]!.add(s);
              } else if (['E', 'F'].contains(section)) {
                byLevel[3]!.add(s);
              }
            }

            final levels = [1, 2, 3].map((l) {
              final levelSlots = byLevel[l]!;
              final available =
                  levelSlots.where((s) => s.status == 'AVAILABLE').length;
              return {
                'level': 'Level $l',
                'available': available,
                'total': levelSlots.isEmpty ? 0 : levelSlots.length,
              };
            }).toList();

            final totalAvailable = levels.fold<int>(
                0, (sum, l) => sum + (l['available'] as int));

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(totalAvailable.toString(), isLive: isLive),
                  const SizedBox(height: 24),
                  const Text(
                    'Parking Levels',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...levels.map(_buildParkingLevelCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- UI Components ----------------

  Widget _buildHeaderCard(String totalAvailable, {bool isLive = false}) {
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.user;

    final displayName = userProfile?.name ?? 
        (_authService.currentUser?.uid != null
            ? 'USR-${_authService.currentUser!.uid.substring(0, 8)}'
            : 'Loading...');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                const Text(
                  'Available Parking Slots',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  totalAvailable,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFF4ADE80) // green when live
                            : Colors.white38,
                        shape: BoxShape.circle,
                        boxShadow: isLive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'Live · Updates automatically' : 'Connecting...',
                      style: TextStyle(
                        color: isLive ? const Color(0xFF4ADE80) : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildParkingLevelCard(Map<String, dynamic> level) {
    final int total = level['total'] as int;
    final int available = level['available'] as int;
    final int occupied = total - available;
    // progress = how full (occupied / total), so bar fills as spaces get taken
    final double progress = total > 0 ? occupied / total : 0;

    // Color based on availability
    Color availColor;
    if (total == 0) {
      availColor = Colors.grey;
    } else if (available == 0) {
      availColor = const Color(0xFFEF4444); // red — full
    } else if (available / total < 0.3) {
      availColor = const Color(0xFFF59E0B); // amber — almost full
    } else {
      availColor = const Color(0xFF10B981); // green — plenty available
    }

    // Progress bar color matches availability
    Color barColor;
    if (total == 0) {
      barColor = Colors.grey.shade300;
    } else if (available == 0) {
      barColor = const Color(0xFFEF4444);
    } else if (available / total < 0.3) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = AppColors.primaryColor;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LevelDetailScreen(levelName: level['level']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: availColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_parking, color: availColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['level'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        total == 0
                            ? 'No data yet'
                            : '$occupied of $total slots occupied',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: availColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    total == 0 ? '—' : '$available free',
                    style: TextStyle(
                      color: availColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E1E6),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
