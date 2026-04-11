import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/models/pricing_rate_model.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/pricing_provider.dart';

class ViewRatesScreen extends StatelessWidget {
  const ViewRatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Consumer<PricingProvider>(
          builder: (context, provider, _) {
            final isConnected = !provider.isLoading;
            final rates = provider.rates;
            final isLoading = provider.isLoading;

            return Column(
              children: [
                // ── Header ──
                _buildHeader(context, isConnected),

                // ── Body ──
                Expanded(
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            children: [
                              // Info banner
                              _infoBanner(isConnected),
                              const SizedBox(height: 16),

                              // Vehicle rate cards
                              _VehicleRateCard(
                                vehicleType: 'car',
                                label: 'Car',
                                icon: Icons.directions_car,
                                accentColor: const Color(0xFF3B82F6),
                                rate: rates['car'],
                              ),
                              const SizedBox(height: 14),
                              _VehicleRateCard(
                                vehicleType: 'bike',
                                label: 'Bike',
                                icon: Icons.pedal_bike,
                                accentColor: const Color(0xFF8B5CF6),
                                rate: rates['bike'],
                              ),
                              const SizedBox(height: 14),
                              _VehicleRateCard(
                                vehicleType: 'threeWheeler',
                                label: 'Three-Wheeler',
                                icon: Icons.electric_rickshaw,
                                accentColor: const Color(0xFFF59E0B),
                                rate: rates['threeWheeler'],
                              ),
                              const SizedBox(height: 20),

                              // Note card
                              _noteCard(),
                            ],
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isConnected) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Parking Rates',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Live dot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFF4ADE80) : Colors.white38,
                        shape: BoxShape.circle,
                        boxShadow:
                            isConnected
                                ? [
                                  BoxShadow(
                                    color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ]
                                : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isConnected ? 'Live' : 'Connecting...',
                      style: TextStyle(
                        color: isConnected ? const Color(0xFF4ADE80) : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 52),
            child: Align(alignment: Alignment.centerLeft),
          ),
        ],
      ),
    );
  }

  // ── INFO BANNER ───────────────────────────────────────────────────────────
  Widget _infoBanner(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.teal),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Rates are in LKR. All prices are set by the administrator and reflect the current active tariff.',
              style: TextStyle(color: AppColors.teal, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── NOTE CARD ─────────────────────────────────────────────────────────────
  Widget _noteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Changes to parking rates apply immediately to new parking sessions. Vehicles already parked will be charged at the rate active at their time of entry.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-vehicle rate card ────────────────────────────────────────────────────

class _VehicleRateCard extends StatelessWidget {
  final String vehicleType;
  final String label;
  final IconData icon;
  final Color accentColor;
  final PricingRateModel? rate;

  const _VehicleRateCard({
    required this.vehicleType,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = rate?.status == 'Active';
    final effectiveStr = rate?.effectiveDate != null ? _formatDate(rate!.effectiveDate!) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      Text(
                        rate?.plan ?? 'Standard Tariff',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    rate?.status ?? 'Not Set',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color(0xFF10B981) : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rate rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child:
                rate == null
                    ? _emptyState()
                    : Column(
                      children: [
                        _rateRow(
                          icon: Icons.access_time_rounded,
                          label: 'First Hour (Base)',
                          value: rate!.firstHour,
                          accentColor: accentColor,
                        ),
                        _divider(),
                        _rateRow(
                          icon: Icons.add_circle_outline,
                          label: 'Subsequent Hours',
                          value: rate!.subsequentHour,
                          unit: '/ hr',
                          accentColor: accentColor,
                        ),
                        _divider(),
                        _rateRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Daily Maximum',
                          value: rate!.dailyMax,
                          accentColor: accentColor,
                        ),
                        _divider(),
                        _rateRow(
                          icon: Icons.warning_amber_rounded,
                          label: 'Lost Ticket Penalty',
                          value: rate!.lostTicket,
                          accentColor: const Color(0xFFEF4444),
                          isWarning: true,
                        ),
                      ],
                    ),
          ),

          // Effective date footer
          if (effectiveStr != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.update, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Last updated: $effectiveStr${rate?.adminEmail != null ? ' · by ${rate!.adminEmail}' : ''}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _rateRow({
    required IconData icon,
    required String label,
    required double value,
    String unit = '',
    required Color accentColor,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isWarning ? const Color(0xFF92400E) : const Color(0xFF334155),
              ),
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'LKR ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: _formatAmount(value),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
                ),
                if (unit.isNotEmpty)
                  TextSpan(text: unit, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.price_change_outlined, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No rates set yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            Text(
              'Admin hasn\'t configured this vehicle type yet',
              style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(2);
  }
}
