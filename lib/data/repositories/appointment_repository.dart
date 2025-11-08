// lib/data/repositories/appointment_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_hospital_app/data/models/appointment_model.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';

  // Get appointments for a doctor
  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    return _firestore
        .collection(_collection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  // Get appointments for a patient
  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  // Get today's appointments for a doctor
  Stream<List<AppointmentModel>> getTodayDoctorAppointments(String doctorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  // Get upcoming appointments for a doctor
  Stream<List<AppointmentModel>> getUpcomingDoctorAppointments(String doctorId) {
    final now = DateTime.now();

    return _firestore
        .collection(_collection)
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('dateTime', descending: false)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  // Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return AppointmentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching appointment: $e');
    }
  }

  // Create appointment
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _firestore.collection(_collection).add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating appointment: $e');
    }
  }

  // Update appointment
  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating appointment: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(String id, AppointmentStatus status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating appointment status: $e');
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting appointment: $e');
    }
  }

  // Check if time slot is available
  Future<bool> isTimeSlotAvailable({
    required String doctorId,
    required DateTime dateTime,
    String? excludeAppointmentId,
  }) async {
    try {
      final startTime = dateTime.subtract(const Duration(minutes: 30));
      final endTime = dateTime.add(const Duration(minutes: 30));

      var query = _firestore
          .collection(_collection)
          .where('doctorId', isEqualTo: doctorId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .where('status', whereIn: ['pending', 'confirmed']);

      final snapshot = await query.get();

      if (excludeAppointmentId != null) {
        return snapshot.docs.where((doc) => doc.id != excludeAppointmentId).isEmpty;
      }

      return snapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Error checking time slot: $e');
    }
  }

  // Get appointment count for a specific day
  Future<int> getDailyAppointmentCount(String doctorId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collection)
          .where('doctorId', isEqualTo: doctorId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error getting appointment count: $e');
    }
  }
}