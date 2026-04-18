import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/models/pricing_rate_model.dart';
import 'package:mobile/services/pricing_service.dart';

class PricingProvider extends ChangeNotifier {
  final PricingService _pricingService = PricingService();
  StreamSubscription<Map<String, PricingRateModel?>>? _ratesSubscription;

  Map<String, PricingRateModel?> _rates = {};
  bool _isLoading = false;
  bool _isAuthenticated = false;

  Map<String, PricingRateModel?> get rates => _rates;
  bool get isLoading => _isLoading;

  /// Called by [ChangeNotifierProxyProvider] whenever [AuthProvider] changes.
  void updateAuth(bool isAuthenticated) {
    if (_isAuthenticated == isAuthenticated) return; // no change
    _isAuthenticated = isAuthenticated;

    _ratesSubscription?.cancel();
    _ratesSubscription = null;

    if (!isAuthenticated) {
      _rates = {};
      _isLoading = false;
      notifyListeners();
      return;
    }

    // User just signed in — start the Firestore subscription.
    _isLoading = true;
    notifyListeners();

    _ratesSubscription = _pricingService.watchAllRates().listen((data) {
      _rates = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ratesSubscription?.cancel();
    super.dispose();
  }
}
