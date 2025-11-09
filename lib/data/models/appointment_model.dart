// lib/data/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_status.dart';
import 'appointment_type.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String? patientEmail;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String hospitalId;
  final String hospitalName;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? chiefComplaint;
  final String? symptoms;
  final String? notes;
  final String? doctorNotes;
  final String? prescription;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    this.patientEmail,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.hospitalId,
    required this.hospitalName,
    required this.dateTime,
    this.durationMinutes = 30,
    required this.type,
    required this.status,
    this.chiefComplaint,
    this.symptoms,
    this.notes,
    this.doctorNotes,
    this.prescription,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientPhone: data['patientPhone'] ?? '',
      patientEmail: data['patientEmail'],
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      hospitalId: data['hospitalId'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 30,
      type: AppointmentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AppointmentType.consultation,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      chiefComplaint: data['chiefComplaint'],
      symptoms: data['symptoms'],
      notes: data['notes'],
      doctorNotes: data['doctorNotes'],
      prescription: data['prescription'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientEmail': patientEmail,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'type': type.name,
      'status': status.name,
      'chiefComplaint': chiefComplaint,
      'symptoms': symptoms,
      'notes': notes,
      'doctorNotes': doctorNotes,
      'prescription': prescription,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    String? patientEmail,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? hospitalId,
    String? hospitalName,
    DateTime? dateTime,
    int? durationMinutes,
    AppointmentType? type,
    AppointmentStatus? status,
    String? chiefComplaint,
    String? symptoms,
    String? notes,
    String? doctorNotes,
    String? prescription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      patientEmail: patientEmail ?? this.patientEmail,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      status: status ?? this.status,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      prescription: prescription ?? this.prescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}