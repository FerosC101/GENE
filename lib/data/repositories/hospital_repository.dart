// lib/data/repositories/hospital_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_hospital_app/data/models/hospital_model.dart';

class HospitalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'hospitals';

  // Get all hospitals
  Stream<List<HospitalModel>> getHospitalsStream() {
    return _firestore.collection(_collection).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => HospitalModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get hospital by ID
  Future<HospitalModel?> getHospitalById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return HospitalModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching hospital: $e');
    }
  }

  // Create hospital
  Future<String> createHospital(Map<String, dynamic> hospitalData) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        ...hospitalData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating hospital: $e');
    }
  }

  // Update hospital
  Future<void> updateHospital(String id, Map<String, dynamic> hospitalData) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...hospitalData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating hospital: $e');
    }
  }

  // Delete hospital
  Future<void> deleteHospital(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting hospital: $e');
    }
  }

  // Update bed status
  Future<void> updateBedStatus(String hospitalId, Map<String, dynamic> status) async {
    try {
      await _firestore.collection(_collection).doc(hospitalId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating bed status: $e');
    }
  }

  // Stream for a single hospital (live updates)
  Stream<HospitalModel?> getHospitalStream(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HospitalModel.fromFirestore(doc);
    });
  }

  // Update 3D model metadata and URLs for the hospital
  Future<void> update3DModel({
    required String hospitalId,
    required String model3dUrl,
    String? thumbnailUrl,
    ModelMetadata? metadata,
  }) async {
    try {
      final payload = {
        'model3dUrl': model3dUrl,
        if (thumbnailUrl != null) 'model3dThumbnail': thumbnailUrl,
        if (metadata != null) 'modelMetadata': metadata.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collection).doc(hospitalId).update(payload);
    } catch (e) {
      throw Exception('Error updating 3D model: $e');
    }
  }

  // Get hospitals by staff member
  Stream<List<HospitalModel>> getHospitalsByStaffId(String staffId) {
    return _firestore
        .collection(_collection)
        .where('staffIds', arrayContains: staffId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HospitalModel.fromFirestore(doc))
              .toList(),
        );
  }
}