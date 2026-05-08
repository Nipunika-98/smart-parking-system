import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new vehicle
  Future<void> addVehicle(VehicleModel vehicle) async {
    try {
      if (vehicle.isPrimary) {
        await _clearPrimaryStatus(vehicle.userId);
      }

      await _firestore.collection('vehicles').add(vehicle.toJson());
    } catch (e) {
      throw Exception('Failed to add vehicle: $e');
    }
  }

  // Edit vehicle
  Future<void> updateVehicle(String vehicleId, Map<String, dynamic> data) async {
    try {
      if (data['isPrimary'] == true && data.containsKey('userId')) {
        await _clearPrimaryStatus(data['userId']);
      }
      await _firestore.collection('vehicles').doc(vehicleId).update(data);
    } catch (e) {
      throw Exception('Failed to update vehicle: $e');
    }
  }

  // Delete vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  // Get user's active vehicles
  Stream<List<VehicleModel>> getUserVehicles(String userId) {
    return _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => VehicleModel.fromJson(doc.data(), doc.id)).toList(),
        );
  }

  // Clear primary status of other vehicles
  Future<void> _clearPrimaryStatus(String userId) async {
    QuerySnapshot vehicles =
        await _firestore
            .collection('vehicles')
            .where('userId', isEqualTo: userId)
            .where('isPrimary', isEqualTo: true)
            .get();
    for (var doc in vehicles.docs) {
      await _firestore.collection('vehicles').doc(doc.id).update({'isPrimary': false});
    }
  }
}
