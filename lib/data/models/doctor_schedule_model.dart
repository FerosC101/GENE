// lib/data/models/doctor_schedule_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorScheduleModel {
  final String id;
  final String doctorId;
  final String hospitalId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final int maxAppointments;
  final int appointmentDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DoctorScheduleModel({
    required this.id,
    required this.doctorId,
    required this.hospitalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.maxAppointments = 16,
    this.appointmentDuration = 30,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorScheduleModel(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? 0,
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      isAvailable: data['isAvailable'] ?? true,
      maxAppointments: data['maxAppointments'] ?? 16,
      appointmentDuration: data['appointmentDuration'] ?? 30,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      'maxAppointments': maxAppointments,
      'appointmentDuration': appointmentDuration,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }

  String get timeRange => '$startTime - $endTime';
}
