import 'package:flutter/material.dart';
import 'package:mobile/constants/app_colors.dart';
import 'package:mobile/models/parking_slot.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/parking_provider.dart';


String _slotType(String slotNumber) {
  final parts = slotNumber.split('-');
  if (parts.length < 2) return 'car';
  final section = parts[0].toUpperCase();
  final num = int.tryParse(parts[1]) ?? 1;
  if (num > 5) {
    return ['A', 'C', 'E'].contains(section) ? '3wheel' : 'bike';
  }
  return 'car';
}

/// Zone name from section letter
String _zoneName(String section) => 'Zone $section';

// ---------------------------------------------------------------------------

class LevelDetailScreen extends StatefulWidget {
  final String levelName;
  const LevelDetailScreen({super.key, required this.levelName});

  @override
  State<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen> {
  /// Selected vehicle-type filter: 'car' | 'bike' | '3wheel' | 'all'
  String _selectedType = 'all';

  // Map levelName → Firestore levelNumber
  int get _levelInt {
    if (widget.levelName.contains('1')) return 1;
    if (widget.levelName.contains('2')) return 2;
    return 3;
  }

  // ── Build zones from raw Firebase slot list ──────────────────────────────
  List<_ZoneData> _buildZones(List<ParkingSlotModel> slots) {
    // Group by section letter
    final Map<String, List<ParkingSlotModel>> grouped = {};
    for (final slot in slots) {
      final section = slot.slotNumber.split('-').first.toUpperCase();
      grouped.putIfAbsent(section, () => []).add(slot);
    }

    final zones = <_ZoneData>[];
    final sortedSections = grouped.keys.toList()..sort();
    for (final section in sortedSections) {
      final sectionSlots = grouped[section]!..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
      zones.add(
        _ZoneData(
          section: section,
          name: _zoneName(section),
          left: sectionSlots.take(5).toList(),
          right: sectionSlots.skip(5).toList(),
        ),
      );
    }
    return zones;
  }

  // ── Count available by type for the whole level ──────────────────────────
  int _countAvailable(List<ParkingSlotModel> slots, String type) =>
      slots.where((s) => _slotType(s.slotNumber) == type && s.status == 'AVAILABLE').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Consumer<ParkingProvider>(
          builder: (context, provider, _) {
            final allSlots = provider.slots;
            final List<String> targetSections = _levelInt == 1
                ? ['A', 'B']
                : _levelInt == 2
                    ? ['C', 'D']
                    : ['E', 'F'];

            final slots = allSlots.where((s) {
              final sec = s.slotNumber.split('-').first.toUpperCase();
              return targetSections.contains(sec);
            }).toList();

            final zones = _buildZones(slots);

            // Filter zones / slots by selected vehicle type
            final displayedZones =
                zones
                    .map((z) {
                      final filteredLeft = _filterSlots(z.left);
                      final filteredRight = _filterSlots(z.right);
                      return _ZoneData(
                        section: z.section,
                        name: z.name,
                        left: filteredLeft,
                        right: filteredRight,
                      );
                    })
                    .where((z) => z.left.isNotEmpty || z.right.isNotEmpty)
                    .toList();

            return Column(
              children: [
                _buildHeader(context, slots),
                Expanded(
                  child:
                      provider.isLoadingSlots
                          ? const Center(child: CircularProgressIndicator())
                          : displayedZones.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: displayedZones.length,
                            itemBuilder: (_, i) => _buildZoneCard(displayedZones[i]),
                          ),
                ),
                _buildLegend(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  List<ParkingSlotModel> _filterSlots(List<ParkingSlotModel> slots) {
    if (_selectedType == 'all') return slots;
    return slots.where((s) => _slotType(s.slotNumber) == _selectedType).toList();
  }

  // ── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, List<ParkingSlotModel> slots) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.levelName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Vehicle-type stat cards
          Row(
            children: [
              _statCard(
                icon: Icons.directions_car,
                label: 'Cars',
                count: _countAvailable(slots, 'car'),
                type: 'car',
              ),
              _statCard(
                icon: Icons.pedal_bike,
                label: 'Bikes',
                count: _countAvailable(slots, 'bike'),
                type: 'bike',
              ),
              _statCard(
                icon: Icons.electric_rickshaw,
                label: '3-Wheel',
                count: _countAvailable(slots, '3wheel'),
                type: '3wheel',
              ),
              _statCard(
                icon: Icons.grid_view_rounded,
                label: 'All',
                count: slots.where((s) => s.status == 'AVAILABLE').length,
                type: 'all',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int count,
    required String type,
  }) {
    final isActive = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? AppColors.primaryColor : Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.primaryColor : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isActive ? AppColors.teal : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ZONE CARD ─────────────────────────────────────────────────────────────
  Widget _buildZoneCard(_ZoneData zone) {
    final availableCount =
        [...zone.left, ...zone.right].where((s) => s.status == 'AVAILABLE').length;
    final totalCount = zone.left.length + zone.right.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        availableCount > 0
                            ? AppColors.teal.withValues(alpha: 0.12)
                            : const Color(0xFFE5E1E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$availableCount / $totalCount available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: availableCount > 0 ? AppColors.teal : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Slot grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _slotColumn(zone.left, isLeft: true)),
                _driveLane(),
                Expanded(child: _slotColumn(zone.right, isLeft: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotColumn(List<ParkingSlotModel> slots, {required bool isLeft}) {
    if (slots.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(children: slots.map((slot) => _slotTile(slot, isLeft: isLeft)).toList());
  }

  Widget _slotTile(ParkingSlotModel slot, {required bool isLeft}) {
    final type = _slotType(slot.slotNumber);
    final status = slot.status; // AVAILABLE | OCCUPIED | MAINTENANCE
    final displayId = slot.slotNumber.replaceAll('-', '');

    IconData icon;
    switch (type) {
      case 'bike':
        icon = Icons.pedal_bike;
        break;
      case '3wheel':
        icon = Icons.electric_rickshaw;
        break;
      default:
        icon = Icons.directions_car;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slotBorderColor(status, type), width: 1.5),
        color: _slotBgColor(status, type),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Maintenance stripe overlay
            if (status == 'MAINTENANCE') Positioned.fill(child: _maintenanceStripes()),

            // Content: icon + label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: _slotFgColor(status, type)),
                const SizedBox(width: 5),
                Text(
                  displayId,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _slotFgColor(status, type),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Color helpers matching the dashboard SCSS ────────────────────────────

  Color _slotBgColor(String status, String type) {
    if (status == 'AVAILABLE') return Colors.white;
    if (status == 'MAINTENANCE') return const Color(0xFFFCD34D); // amber base
    // OCCUPIED
    if (type == 'bike') return const Color(0xFF3B82F6); // blue
    return const Color(0xFF1E293B); // dark navy (car / 3wheel)
  }

  Color _slotBorderColor(String status, String type) {
    if (status == 'AVAILABLE') return const Color(0xFFE2E8F0);
    if (status == 'MAINTENANCE') return const Color(0xFFD97706); // amber border
    if (type == 'bike') return const Color(0xFF2563EB); // darker blue
    return const Color(0xFF0F172A); // darkest navy
  }

  Color _slotFgColor(String status, String type) {
    if (status == 'AVAILABLE') return const Color(0xFF475569); // slate
    if (status == 'MAINTENANCE') return const Color(0xFF92400E); // dark amber
    return Colors.white; // white on dark/blue
  }

  /// Diagonal amber stripe pattern matching the dashboard `.maintenance` CSS
  Widget _maintenanceStripes() {
    return CustomPaint(painter: _StripePainter());
  }

  // Drive lane in the middle with Entry / Exit labels
  Widget _driveLane() {
    return SizedBox(
      width: 36,
      child: Column(
        children: const [
          SizedBox(height: 4),
          Text(
            'IN',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black38),
          ),
          SizedBox(height: 6),
          Icon(Icons.arrow_downward, size: 14, color: Colors.black26),
          SizedBox(height: 60),
          Icon(Icons.arrow_downward, size: 14, color: Colors.black26),
          SizedBox(height: 6),
          Text(
            'OUT',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  // ── LEGEND ────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(
            color: Colors.white,
            label: 'Available',
            borderColor: const Color(0xFFE2E8F0),
          ),
          _legendDivider(),
          _legendItem(
            color: const Color(0xFF1E293B),
            label: 'Occupied',
            swatchTextColor: Colors.white,
          ),
          _legendDivider(),
          _legendMaintenanceItem(),
        ],
      ),
    );
  }

  Widget _legendDivider() => Container(width: 1, height: 24, color: const Color(0xFFE2E8F0));

  Widget _legendItem({
    required Color color,
    required String label,
    Color? borderColor,
    Color? swatchTextColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
          ),
          child:
              swatchTextColor != null
                  ? Center(child: Icon(Icons.directions_car, size: 12, color: swatchTextColor))
                  : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _legendMaintenanceItem() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: const SizedBox(
            width: 14,
            height: 14,
            child: CustomPaint(painter: _StripePainter()),
          ),
        ),
        const SizedBox(width: 5),
        const Text('Maint.', style: TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_parking_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No slots found for ${widget.levelName}',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class _ZoneData {
  final String section;
  final String name;
  final List<ParkingSlotModel> left;
  final List<ParkingSlotModel> right;

  _ZoneData({required this.section, required this.name, required this.left, required this.right});
}

// ── Stripe painter for Maintenance slots ─────────────────────────────────────

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stripeWidth = 8.0;
    final paintA = Paint()..color = const Color(0xFFFCD34D); // light amber
    final paintB = Paint()..color = const Color(0xFFF59E0B); // dark amber
    double x = -size.height;
    while (x < size.width + size.height) {
      final path =
          Path()
            ..moveTo(x, size.height)
            ..lineTo(x + stripeWidth, size.height)
            ..lineTo(x + stripeWidth + size.height, 0)
            ..lineTo(x + size.height, 0)
            ..close();
      canvas.drawPath(path, (x ~/ stripeWidth).isEven ? paintA : paintB);
      x += stripeWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
