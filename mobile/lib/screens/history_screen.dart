import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/models/parking_session_model.dart';
import 'package:mobile/models/pricing_rate_model.dart';
import 'package:mobile/models/parking_slot.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/parking_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/pricing_provider.dart';
import 'package:mobile/providers/parking_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AuthService _authService = AuthService();
  final ParkingService _parkingService = ParkingService();

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please login to view history')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Consumer2<PricingProvider, ParkingProvider>(
          builder: (context, pricingProvider, parkingProvider, _) {
            final rates = pricingProvider.rates;
            final slots = parkingProvider.slots;

            // Map slotId -> slotNumber
            final slotMap = {for (var s in slots) s.slotId: s.slotNumber};

                return StreamBuilder<List<ParkingSessionModel>>(
                  stream: _parkingService.getUserSessionHistory(userId),
                  builder: (context, sessionSnapshot) {
                    if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (sessionSnapshot.hasError) {
                      return Center(child: Text('Error: ${sessionSnapshot.error}'));
                    }

                    final allSessions = sessionSnapshot.data ?? [];
                    final filtered = _applyFilter(allSessions);

                    return Column(
                      children: [
                        _buildHeader(allSessions, rates, slotMap),
                        const SizedBox(height: 16),
                        _buildFilters(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) =>
                                      _buildHistoryCard(filtered[index], rates, slotMap),
                                ),
                        ),
                      ],
                    );
                  },
                );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    List<ParkingSessionModel> sessions,
    Map<String, PricingRateModel?> rates,
    Map<String, String> slotMap,
  ) {
    double totalSpent = 0;
    for (var s in sessions) {
      totalSpent += _calculateAmount(s, rates, slotMap);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parking History',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statBox('Total Spent', 'LKR ${totalSpent.toStringAsFixed(0)}', Icons.payments_outlined),
              const SizedBox(width: 16),
              _statBox('Sessions', sessions.length.toString(), Icons.local_parking),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['All', 'This Week', 'This Month', 'This Year'].map(_buildFilterChip).toList(),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedFilter = label),
        selectedColor: AppColors.primaryColor,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      ),
    );
  }

  List<ParkingSessionModel> _applyFilter(List<ParkingSessionModel> sessions) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return sessions.where((s) => s.entryTime.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day))).toList();
      case 'This Month':
        return sessions.where((s) => s.entryTime.year == now.year && s.entryTime.month == now.month).toList();
      case 'This Year':
        return sessions.where((s) => s.entryTime.year == now.year).toList();
      default:
        return sessions;
    }
  }

  double _calculateAmount(
    ParkingSessionModel session,
    Map<String, PricingRateModel?> rates,
    Map<String, String> slotMap,
  ) {
    if (session.totalAmount != null && session.totalAmount! > 0) {
      return session.totalAmount!;
    }

    final exitTime = session.exitTime ?? DateTime.now();
    final duration = exitTime.difference(session.entryTime);
    final hours = (duration.inMinutes / 60.0).ceil(); // Bill for each chunk

    final slotNumber = slotMap[session.slotId] ?? '';
    final vehicleType = ParkingSlotModel.getVehicleType(slotNumber);
    final rate = rates[vehicleType];

    if (rate == null) return hours * 100.0; // Fallback to mock

    if (hours <= 0) return 0;

    // Logic: firstHour + (additionalHours * subsequentHour)
    double total = rate.firstHour;
    if (hours > 1) {
      total += (hours - 1) * rate.subsequentHour;
    }

    // Apply Daily Max if it exceeds
    if (rate.dailyMax > 0 && total > rate.dailyMax) {
      total = rate.dailyMax;
    }

    return total;
  }

  Widget _buildHistoryCard(ParkingSessionModel session, Map<String, PricingRateModel?> rates, Map<String, String> slotMap) {
    final exitTime = session.exitTime ?? DateTime.now();
    final duration = _formatDuration(session.entryTime, exitTime);
    final amount = _calculateAmount(session, rates, slotMap);
    final slotNumber = slotMap[session.slotId] ?? 'N/A';
    final vehicleType = ParkingSlotModel.getVehicleType(slotNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(slotNumber, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    _buildStatusBadge(session.paymentStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTimeCol('Entry', session.entryTime, Icons.login_rounded),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black12),
                    _buildTimeCol('Exit', exitTime, Icons.logout_rounded),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('LKR ${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                        Text(duration, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
            child: Row(
              children: [
                Icon(_getVehicleIcon(vehicleType), size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  vehicleType.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const Spacer(),
                Text('ID: ${session.ticketNumber.split('-').last}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCol(String label, DateTime time, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black26),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(time),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d').format(time),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isPaid = status == 'PAID';
    final color = isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'bike': return Icons.pedal_bike;
      case 'threeWheeler': return Icons.electric_rickshaw;
      default: return Icons.directions_car;
    }
  }

  String _formatDuration(DateTime entry, DateTime exit) {
    final diff = exit.difference(entry);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No sessions recorded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}

