import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/models/pricing_rate_model.dart';
import 'package:mobile/services/pricing_service.dart';

class PricingProvider extends ChangeNotifier {
  final PricingService _pricingService = PricingService();
  StreamSubscription<Map<String, PricingRateModel?>>? _ratesSubscription;

  Map<String, PricingRateModel?> _rates = {};
  bool _isLoading = true;

  Map<String, PricingRateModel?> get rates => _rates;
  bool get isLoading => _isLoading;

  PricingProvider() {
    _ratesSubscription = _pricingService.watchAllRates().listen((data) {
      _rates = data;
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
