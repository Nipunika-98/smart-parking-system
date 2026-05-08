import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/screens/bottom_navigation.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/models/parking_session_model.dart';
import 'package:intl/intl.dart';
import 'package:mobile/screens/qr_scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/parking_provider.dart';

class ActiveParkingSessionScreen extends StatefulWidget {
  const ActiveParkingSessionScreen({super.key});

  @override
  State<ActiveParkingSessionScreen> createState() => _ActiveParkingSessionScreenState();
}

class _ActiveParkingSessionScreenState extends State<ActiveParkingSessionScreen> {
  final AuthService _authService = AuthService();

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _entryTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime entryTime) {
    if (_entryTime == entryTime && _timer != null) return;
    _entryTime = entryTime;
    _elapsed = DateTime.now().difference(entryTime);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(entryTime));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: _authService.currentUser == null
            ? const Center(child: Text('Not logged in'))
            : Consumer<ParkingProvider>(
                builder: (context, provider, _) {
                  if (provider.activeSessions.isEmpty) {
                    return ListView(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 60),
                        const Center(
                          child: Text(
                            'No active parking session found.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }
                  final session = provider.activeSessions.first;
                  if (_entryTime == null || _entryTime != session.entryTime) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _startTimer(session.entryTime);
                    });
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        _buildTicketCard(session),
                        const SizedBox(height: 16),
                        _buildDurationCard(),
                        const SizedBox(height: 20),
                        _buildExitButton(context, session),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const BottomNavigation()),
                (route) => false,
              );
            },
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white),
                SizedBox(width: 6),
                Text('Back', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Active Parking Session',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Keep this ticket for exit', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ---------------- TICKET CARD ----------------
  Widget _buildTicketCard(ParkingSessionModel session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User ID', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    session.userId.length > 8
                        ? 'USR-${session.userId.substring(0, 8)}'
                        : session.userId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _infoRow(
              icon: Icons.calendar_today,
              title: 'Entry Date',
              value: DateFormat('MMM d, yyyy').format(session.entryTime),
              icon2: Icons.access_time,
              title2: 'Entry Time',
              value2: DateFormat('h:mm a').format(session.entryTime),
            ),
            const Divider(height: 1),
            _singleInfo(
              icon: Icons.confirmation_number,
              title: 'Ticket Number',
              value: session.ticketNumber,
            ),
            const Divider(height: 1),
            // Removed QR code section here
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please scan the QR code displayed at the exit gate to finish your session.',
                            style: TextStyle(color: Colors.blue, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    required IconData icon2,
    required String title2,
    required String value2,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _infoItem(icon, title, value)),
          Expanded(child: _infoItem(icon2, title2, value2)),
        ],
      ),
    );
  }

  static Widget _singleInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _infoItem(icon, title, value),
    );
  }

  static Widget _infoItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // ---------------- LIVE DURATION CARD ----------------
  Widget _buildDurationCard() {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              'Parking Duration',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimeBox(hours, 'Hours'),
                _TimeBox(minutes, 'Minutes'),
                _TimeBox(seconds, 'Seconds'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- EXIT BUTTON ----------------
  Widget _buildExitButton(BuildContext context, ParkingSessionModel session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScanScreen()),
            );
          },
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          label: const Text(
            'Scan Exit QR at Gate',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ---------------- TIME BOX ----------------
class _TimeBox extends StatelessWidget {
  final String value;
  final String label;

  const _TimeBox(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
