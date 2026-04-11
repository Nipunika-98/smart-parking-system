import 'package:flutter/material.dart';
import 'package:mobile/models/parking_session_model.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/parking_service.dart';
import 'package:mobile/services/pricing_service.dart';
import 'package:mobile/screens/active_parking_session_screen.dart';
import 'package:mobile/screens/payment_successful_screen.dart';
import 'package:mobile/utils/ui_utils.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/parking_provider.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final AuthService _authService = AuthService();
  final ParkingService _parkingService = ParkingService();
  final PricingService _pricingService = PricingService();

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Consumer<ParkingProvider>(
        builder: (context, parkingProvider, _) {
          final bool hasActiveSession = parkingProvider.activeSessions.isNotEmpty;
          final activeSession = hasActiveSession ? parkingProvider.activeSessions.first : null;

          return StreamBuilder<Map<String, String>>(
            stream: _parkingService.watchGateTokens(),
            builder: (context, tokenSnapshot) {
              final tokens = tokenSnapshot.data ?? {'entry': '', 'exit': ''};

              return SafeArea(
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0B1220), Color(0xFF000000)],
                        ),
                      ),
                    ),

                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleIcon(
                            icon: Icons.close,
                            onTap: () => Navigator.pop(context),
                          ),
                          _circleIcon(
                            icon: Icons.flashlight_on_outlined,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    // Instruction Text & Camera Frame
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _cameraFrame(),
                          const SizedBox(height: 32),
                          Text(
                            hasActiveSession ? 'Scan Exit Gate QR' : 'Scan Entry Gate QR',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasActiveSession
                                ? 'Finalize your session & see digital receipt'
                                : 'Scan the code displayed at the facility entry',
                            style: const TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),

                    // Action Button (Simulate SCAN)
                    Positioned(
                      bottom: 40,
                      left: 40,
                      right: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleGateScan(
                                    context,
                                    hasActiveSession,
                                    activeSession,
                                    hasActiveSession ? tokens['exit']! : tokens['entry']!,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  hasActiveSession ? 'Simulate Exit Scan' : 'Simulate Entry Scan',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _circleIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
  }

  Widget _cameraFrame() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Stack(
        children: [
          _corner(top: 0, left: 0),
          _corner(top: 0, right: 0),
          _corner(bottom: 0, left: 0),
          _corner(bottom: 0, right: 0),
          const Center(
            child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 60),
          ),
        ],
      ),
    );
  }

  Widget _corner({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: Colors.teal, width: 4) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: Colors.teal, width: 4) : BorderSide.none,
            left: left != null ? const BorderSide(color: Colors.teal, width: 4) : BorderSide.none,
            right: right != null ? const BorderSide(color: Colors.teal, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _handleGateScan(
    BuildContext context,
    bool isExit,
    ParkingSessionModel? activeSession,
    String token,
  ) async {
    if (token.isEmpty) {
      UIUtils.showSnackBar(context, 'Gate is not configured yet.', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = _authService.currentUser!.uid;

      if (isExit) {
        // --- EXIT LOGIC ---
        // 1. Pre-fetch rates and slot mapping for the receipt
        final rates = await _pricingService.getAllRates();
        final slotSnapshot = await _parkingService.getAllSlots().first; 
        final slotMap = {for (var s in slotSnapshot) s.slotId: s.slotNumber};

        // 2. End session - Initial status is PENDING until admin confirms
        await _parkingService.endSession(activeSession!.sessionId, 'gate_exit_qr', 'PENDING');
        
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessfulScreen(
              session: ParkingSessionModel(
                sessionId: activeSession.sessionId,
                userId: activeSession.userId,
                slotId: activeSession.slotId,
                ticketNumber: activeSession.ticketNumber,
                entryTime: activeSession.entryTime,
                exitTime: DateTime.now(),
                entryScannedBy: activeSession.entryScannedBy,
                exitScannedBy: 'gate_exit_qr',
                paymentStatus: 'PENDING',
                qrCodeData: activeSession.qrCodeData,
              ),
              rates: rates,
              slotMap: slotMap,
            ),
          ),
        );
      } else {
        // --- ENTRY LOGIC ---
        final slotId = await _parkingService.getFirstAvailableSlot();
        if (slotId == null) {
          if (!context.mounted) return;
          UIUtils.showSnackBar(context, 'Parking is full!', isError: true);
          return;
        }

        await _parkingService.createSession(userId, slotId, 'gate_entry_qr');
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActiveParkingSessionScreen()),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      UIUtils.showSnackBar(context, UIUtils.getFriendlyErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
