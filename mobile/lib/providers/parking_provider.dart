import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/models/parking_slot.dart';
import 'package:mobile/models/parking_session_model.dart';
import 'package:mobile/services/parking_service.dart';

class ParkingProvider extends ChangeNotifier {
  final ParkingService _parkingService = ParkingService();

  StreamSubscription<List<ParkingSlotModel>>? _slotsSubscription;
  StreamSubscription<List<ParkingSessionModel>>? _sessionsSubscription;

  List<ParkingSlotModel> _slots = [];
  List<ParkingSessionModel> _activeSessions = [];
  bool _isLoadingSlots = false;
  bool _isAuthenticated = false;

  List<ParkingSlotModel> get slots => _slots;
  List<ParkingSessionModel> get activeSessions => _activeSessions;
  bool get isLoadingSlots => _isLoadingSlots;

  void updateUserId(String? userId) {
    final isAuthenticated = userId != null;

    // Cancel both subscriptions on any auth change
    _slotsSubscription?.cancel();
    _slotsSubscription = null;
    _sessionsSubscription?.cancel();
    _sessionsSubscription = null;

    if (!isAuthenticated) {
      _slots = [];
      _activeSessions = [];
      _isLoadingSlots = false;
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    _isAuthenticated = true;
    _isLoadingSlots = true;
    notifyListeners();

    // Start slots stream (requires auth)
    _slotsSubscription = _parkingService.getAllSlots().listen(
      (data) {
        _slots = data;
        _isLoadingSlots = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoadingSlots = false;
        notifyListeners();
      },
    );

    // Start user-sessions stream
    _sessionsSubscription = _parkingService.getUserActiveSessions(userId).listen(
      (data) {
        _activeSessions = data;
        notifyListeners();
      },
      onError: (_) {
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _slotsSubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.dispose();
  }
}
