// lib/data/repositories/schedule_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse/data/models/doctor_schedule_model.dart';

class ScheduleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'doctor_schedules';

  // Get doctor's schedule
  Stream<List<DoctorScheduleModel>> getDoctorSchedule(String doctorId) {
    return _firestore
        .collection(_collection)
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          final schedules = snapshot.docs
              .map((doc) => DoctorScheduleModel.fromFirestore(doc))
              .toList();
          // Sort by dayOfWeek in memory
          schedules.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
          return schedules;
        });
  }

  // Get schedule for a specific day
  Future<DoctorScheduleModel?> getScheduleForDay(String doctorId, int dayOfWeek) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('doctorId', isEqualTo: doctorId)
          .where('dayOfWeek', isEqualTo: dayOfWeek)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DoctorScheduleModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching schedule: $e');
    }
  }

  // Create schedule
  Future<String> createSchedule(DoctorScheduleModel schedule) async {
    try {
      final docRef = await _firestore.collection(_collection).add(schedule.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating schedule: $e');
    }
  }

  // Update schedule
  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating schedule: $e');
    }
  }

  // Delete schedule
  Future<void> deleteSchedule(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting schedule: $e');
    }
  }

  // Batch create default schedule (Mon-Fri, 9AM-5PM)
  Future<void> createDefaultSchedule({
    required String doctorId,
    required String hospitalId,
  }) async {
    try {
      final batch = _firestore.batch();

      for (int day = 0; day < 5; day++) { // Monday to Friday
        final schedule = DoctorScheduleModel(
          id: '',
          doctorId: doctorId,
          hospitalId: hospitalId,
          dayOfWeek: day,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: true,
          maxAppointments: 16,
          appointmentDuration: 30,
          createdAt: DateTime.now(),
        );

        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, schedule.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error creating default schedule: $e');
    }
  }
}