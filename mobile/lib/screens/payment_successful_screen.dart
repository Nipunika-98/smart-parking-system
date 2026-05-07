import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/models/parking_session_model.dart';
import 'package:mobile/models/parking_slot.dart';
import 'package:mobile/models/pricing_rate_model.dart';
import 'package:mobile/screens/bottom_navigation.dart';
import 'package:intl/intl.dart';
import 'package:mobile/services/parking_service.dart';

class PaymentSuccessfulScreen extends StatelessWidget {
  final ParkingSessionModel session;
  final List<PricingRateModel>? rates;
  final Map<String, String>? slotMap;

  const PaymentSuccessfulScreen({
    super.key,
    required this.session,
    this.rates,
    this.slotMap,
  });

  // Calculate parking duration string
  String getDurationString(ParkingSessionModel currentSession) {
    final exit = currentSession.exitTime ?? DateTime.now();
    final diff = exit.difference(currentSession.entryTime);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '$h hour${h != 1 ? 's' : ''} $m minute${m != 1 ? 's' : ''}';
    return '$m minute${m != 1 ? 's' : ''}';
  }

  // Calculate billing amount based on vehicle type
  double getCalculatedAmount(ParkingSessionModel currentSession) {
    if (currentSession.totalAmount != null && currentSession.totalAmount! > 0) {
      return currentSession.totalAmount!;
    }

    if (rates == null || rates!.isEmpty) return 0.0;

    final slotNumber = slotMap?[currentSession.slotId] ?? 'A-01';
    final vehicleType = ParkingSlotModel.getVehicleType(slotNumber);

    final rate = rates!.firstWhere(
      (r) => r.vehicleType == vehicleType,
      orElse: () => rates!.first,
    );

    final exit = currentSession.exitTime ?? DateTime.now();
    final duration = exit.difference(currentSession.entryTime);
    final hours = (duration.inMinutes / 60.0).ceil();

    if (hours <= 0) return 0.0;

    double amount = rate.firstHour;
    if (hours > 1) {
      amount += (hours - 1) * rate.subsequentHour;
    }

    if (amount > rate.dailyMax && rate.dailyMax > 0) {
      amount = rate.dailyMax;
    }

    return amount;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ParkingSessionModel?>(
      stream: ParkingService().getSessionStream(session.sessionId),
      initialData: session,
      builder: (context, snapshot) {
        final currentSession = snapshot.data ?? session;
        final exitTime = currentSession.exitTime ?? DateTime.now();
        final amount = getCalculatedAmount(currentSession);

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildReceiptHeader(currentSession),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildTicketInfoCard(currentSession),
                      const SizedBox(height: 16),
                      _buildExitInfoCard(currentSession, exitTime),
                      const SizedBox(height: 16),
                      _buildDurationCard(currentSession),
                      const SizedBox(height: 16),
                      _buildPaymentSummaryCard(currentSession, amount),
                      const SizedBox(height: 16),
                      _buildPaymentStatusCard(currentSession),
                      const SizedBox(height: 24),
                      _buildDoneButton(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptHeader(ParkingSessionModel currentSession) {
    final isPaid = currentSession.paymentStatus == 'PAID';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPaid 
              ? [const Color(0xFF065F46), const Color(0xFF064E3B)] // Green for paid
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)], // Slate for pending
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isPaid ? Icons.check_circle : Icons.receipt_long, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            isPaid ? 'Payment Confirmed' : 'Digital Receipt',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isPaid ? 'Thank you for your visit!' : 'Session ended successfully',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoCard(ParkingSessionModel currentSession) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.confirmation_number_outlined, size: 18, color: Colors.teal),
                SizedBox(width: 10),
                Text('Ticket Reference', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentSession.ticketNumber,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExitInfoCard(ParkingSessionModel currentSession, DateTime exitTime) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildRowItem(
              Icons.login,
              'Entry Time',
              DateFormat('MMM d, h:mm a').format(currentSession.entryTime),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildRowItem(
              Icons.logout,
              'Exit Time',
              DateFormat('MMM d, h:mm a').format(exitTime),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.black45),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDurationCard(ParkingSessionModel currentSession) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: Colors.orange),
                SizedBox(width: 10),
                Text('Total Duration', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              ],
            ),
            Text(
              getDurationString(currentSession),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(ParkingSessionModel currentSession, double amount) {
    final slotNumber = slotMap?[currentSession.slotId] ?? 'A-01';
    final vehicleType = ParkingSlotModel.getVehicleType(slotNumber);
    final isPaid = currentSession.paymentStatus == 'PAID';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Vehicle Type: ${vehicleType.toUpperCase()}',
            style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'TOTAL AMOUNT DUE',
            style: TextStyle(color: Colors.black87, fontSize: 13, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 4),
                child: Text('LKR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
              Text(
                amount.toStringAsFixed(2),
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (isPaid ? Colors.green : Colors.amber).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isPaid ? Icons.check : Icons.info_outline, size: 14, color: isPaid ? Colors.green : Colors.amber),
                const SizedBox(width: 8),
                Text(
                  isPaid ? 'Payment Confirmed' : 'Pay manually at the counter',
                  style: TextStyle(color: isPaid ? Colors.green : Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusCard(ParkingSessionModel currentSession) {
    final isPaid = currentSession.paymentStatus == 'PAID';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Status', style: TextStyle(color: Colors.black54, fontSize: 14)),
                  Text(
                    isPaid ? 'Confirmed by Admin' : 'Awaiting Confirmation',
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Text(
            isPaid ? 'PAID' : 'PENDING',
            style: TextStyle(
              color: isPaid ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BottomNavigation()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
