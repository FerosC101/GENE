// lib/data/repositories/patient_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse/data/models/patient_model.dart';

class PatientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'patients';

  // Get patients by hospital
  Stream<List<PatientModel>> getPatientsStream(String hospitalId) {
    return _firestore
        .collection(_collection)
        .where('hospitalId', isEqualTo: hospitalId)
        .where('status', whereIn: [PatientStatus.admitted.name])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PatientModel.fromFirestore(doc))
            .toList());
  }

  // Get patients by department
  Stream<List<PatientModel>> getPatientsByDepartment(
    String hospitalId,
    String department,
  ) {
    return _firestore
        .collection(_collection)
        .where('hospitalId', isEqualTo: hospitalId)
        .where('department', isEqualTo: department)
        .where('status', isEqualTo: PatientStatus.admitted.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PatientModel.fromFirestore(doc))
            .toList());
  }

  // Admit patient
  Future<String> admitPatient(Map<String, dynamic> patientData) async {
    final docRef = await _firestore.collection(_collection).add({
      ...patientData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Update patient
  Future<void> updatePatient(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Discharge patient
  Future<void> dischargePatient(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': PatientStatus.discharged.name,
      'dischargeDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Transfer patient
  Future<void> transferPatient(
    String id,
    String newDepartment,
    String? newBedNumber,
  ) async {
    await _firestore.collection(_collection).doc(id).update({
      'department': newDepartment,
      'bedNumber': newBedNumber,
      'status': PatientStatus.transferred.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}