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
  bool _isLoadingSlots = true;
  
  List<ParkingSlotModel> get slots => _slots;
  List<ParkingSessionModel> get activeSessions => _activeSessions;
  bool get isLoadingSlots => _isLoadingSlots;

  ParkingProvider() {
    _slotsSubscription = _parkingService.getAllSlots().listen((data) {
      _slots = data;
      _isLoadingSlots = false;
      notifyListeners();
    });
  }

  void updateUserId(String? userId) {
    _sessionsSubscription?.cancel();
    if (userId == null) {
      _activeSessions = [];
      notifyListeners();
      return;
    }

    _sessionsSubscription = _parkingService.getUserActiveSessions(userId).listen((data) {
      _activeSessions = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _slotsSubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.dispose();
  }
}
