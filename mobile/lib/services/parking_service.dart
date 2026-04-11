import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_slot.dart';
import '../models/parking_session_model.dart';
import 'dart:math';

class ParkingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all slots
  Stream<List<ParkingSlotModel>> getAllSlots() {
    return _firestore
        .collection('parking_slots')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParkingSlotModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Stream of available slots in a level (by levelNumber field)
  Stream<List<ParkingSlotModel>> getSlotsByLevel(int levelNumber) {
    return _firestore
        .collection('parking_slots')
        .where('levelNumber', isEqualTo: levelNumber)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParkingSlotModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Stream of slots for a level derived from section letters in slotNumber
  // Matches the dashboard logic: A/B → Level 1, C/D → Level 2, E/F → Level 3
  Stream<List<ParkingSlotModel>> getSlotsByLevelSections(int levelNumber) {
    final sections = {
      1: ['A', 'B'],
      2: ['C', 'D'],
      3: ['E', 'F'],
    }[levelNumber] ?? ['A', 'B'];

    return getAllSlots().map(
      (slots) => slots
          .where((s) {
            final section = s.slotNumber.split('-').first.toUpperCase();
            return sections.contains(section);
          })
          .toList(),
    );
  }

  // Admin: update slot availability or maintenance status
  Future<void> updateSlotStatus(String slotId, String status) async {
    try {
      await _firestore.collection('parking_slots').doc(slotId).update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update slot status: $e');
    }
  }

  // Gateway: watch current entry/exit tokens
  Stream<Map<String, String>> watchGateTokens() {
    return _firestore
        .collection('system_config')
        .doc('current_gate_qrs')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {'entry': '', 'exit': ''};
      final data = doc.data() as Map<String, dynamic>;
      return {
        'entry': data['entryToken'] ?? '',
        'exit': data['exitToken'] ?? '',
      };
    });
  }

  // Gateway: find first available slot to auto-assign
  Future<String?> getFirstAvailableSlot() async {
    final snapshot = await _firestore
        .collection('parking_slots')
        .where('status', isEqualTo: 'AVAILABLE')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  // Create a Parking Session (User scans Entry QR)
  Future<ParkingSessionModel> createSession(String userId, String slotId, String entryScannedBy) async {
    try {
      // Create random ticket number
      final ticketNumber = 'TICKET-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';
      
      ParkingSessionModel newSession = ParkingSessionModel(
        sessionId: '', // Will be updated by Firestore
        userId: userId,
        slotId: slotId,
        ticketNumber: ticketNumber,
        entryTime: DateTime.now(),
        entryScannedBy: entryScannedBy,
        paymentStatus: 'PENDING',
        qrCodeData: '${userId}_$slotId',
      );

      DocumentReference docRef = await _firestore.collection('parking_sessions').add(newSession.toJson());

      return ParkingSessionModel.fromJson(newSession.toJson(), docRef.id);
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // End Parking Session (User scans Exit QR and pays)
  Future<void> endSession(String sessionId, String exitScannedBy, String paymentStatus) async {
    try {
      // Get the session to find the slotId
      DocumentSnapshot sessionDoc = await _firestore.collection('parking_sessions').doc(sessionId).get();
      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      
      await _firestore.collection('parking_sessions').doc(sessionId).update({
        'exitTime': FieldValue.serverTimestamp(),
        'exitScannedBy': exitScannedBy,
        'paymentStatus': paymentStatus,
        'paymentTime': paymentStatus == 'PAID' ? FieldValue.serverTimestamp() : null,
      });
      
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  // Get User's Active Sessions
  Stream<List<ParkingSessionModel>> getUserActiveSessions(String userId) {
    return _firestore
        .collection('parking_sessions')
        .where('userId', isEqualTo: userId)
        .where('exitTime', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParkingSessionModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Get User's Session History (completed sessions, ordered by most recent)
  Stream<List<ParkingSessionModel>> getUserSessionHistory(String userId) {
    return _firestore
        .collection('parking_sessions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs
          .map((doc) => ParkingSessionModel.fromJson(doc.data(), doc.id))
          .where((s) => s.exitTime != null) // Only completed sessions
          .toList();

      // Sort by entryTime descending
      sessions.sort((a, b) => b.entryTime.compareTo(a.entryTime));
      return sessions;
    });
  }

  // Get a single session by its ID for real-time monitoring
  Stream<ParkingSessionModel?> getSessionStream(String sessionId) {
    return _firestore
        .collection('parking_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists
            ? ParkingSessionModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)
            : null);
  }
}
