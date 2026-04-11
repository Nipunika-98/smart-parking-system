import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/models/vehicle_model.dart';
import 'package:mobile/services/vehicle_service.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();
  StreamSubscription<List<VehicleModel>>? _subscription;
  
  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;
  String? _error;

  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateUserId(String? userId) {
    _subscription?.cancel();
    if (userId == null) {
      _vehicles = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _vehicleService.getUserVehicles(userId).listen(
      (data) {
        _vehicles = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
