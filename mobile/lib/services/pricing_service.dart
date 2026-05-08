import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pricing_rate_model.dart';

class PricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _collection = 'pricing_rates';

  Stream<PricingRateModel?> watchLatestRate(String vehicleType) {
    return _firestore
        .collection(_collection)
        .where('vehicleType', isEqualTo: vehicleType)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final docs =
              snapshot.docs.map((d) => PricingRateModel.fromJson(d.data(), d.id)).toList()
                ..sort((a, b) {
                  final ta = a.effectiveDate?.millisecondsSinceEpoch ?? 0;
                  final tb = b.effectiveDate?.millisecondsSinceEpoch ?? 0;
                  return tb.compareTo(ta);
                });
          return docs.first;
        });
  }

  // Real-time stream of ALL three vehicle-type rates at once 
  Stream<Map<String, PricingRateModel?>> watchAllRates() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final Map<String, List<PricingRateModel>> byType = {
        'car': [],
        'bike': [],
        'threeWheeler': [],
      };
      for (final doc in snapshot.docs) {
        final model = PricingRateModel.fromJson(doc.data(), doc.id);
        if (byType.containsKey(model.vehicleType)) {
          byType[model.vehicleType]!.add(model);
        }
      }
      final Map<String, PricingRateModel?> result = {};
      for (final entry in byType.entries) {
        final sorted =
            entry.value..sort((a, b) {
              final ta = a.effectiveDate?.millisecondsSinceEpoch ?? 0;
              final tb = b.effectiveDate?.millisecondsSinceEpoch ?? 0;
              return tb.compareTo(ta);
            });
        result[entry.key] = sorted.isEmpty ? null : sorted.first;
      }
      return result;
    });
  }

  Future<List<PricingRateModel>> getAllRates() async {
    final snapshot = await _firestore.collection(_collection).get();
    final Map<String, List<PricingRateModel>> byType = {'car': [], 'bike': [], 'threeWheeler': []};
    for (final doc in snapshot.docs) {
      final model = PricingRateModel.fromJson(doc.data(), doc.id);
      if (byType.containsKey(model.vehicleType)) {
        byType[model.vehicleType]!.add(model);
      }
    }
    final List<PricingRateModel> result = [];
    for (final entry in byType.entries) {
      if (entry.value.isNotEmpty) {
        entry.value.sort((a, b) {
          final ta = a.effectiveDate?.millisecondsSinceEpoch ?? 0;
          final tb = b.effectiveDate?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });
        result.add(entry.value.first);
      }
    }
    return result;
  }

  Future<PricingRateModel?> getCurrentPricingRate() async {
    try {
      final snapshot =
          await _firestore.collection(_collection).where('vehicleType', isEqualTo: 'car').get();
      if (snapshot.docs.isEmpty) return null;
      final docs =
          snapshot.docs.map((d) => PricingRateModel.fromJson(d.data(), d.id)).toList()
            ..sort((a, b) {
              final ta = a.effectiveDate?.millisecondsSinceEpoch ?? 0;
              final tb = b.effectiveDate?.millisecondsSinceEpoch ?? 0;
              return tb.compareTo(ta);
            });
      return docs.first;
    } catch (e) {
      throw Exception('Failed to fetch pricing rate: $e');
    }
  }

  // Admin: save a new pricing rate document
  Future<void> addPricingRate(PricingRateModel rate) async {
    try {
      await _firestore.collection(_collection).add(rate.toJson());
    } catch (e) {
      throw Exception('Failed to add pricing rate: $e');
    }
  }
}
