// lib/data/models/appointment_type.dart

enum AppointmentType {
  consultation,
  followUp,
  emergency,
  checkup;

  String get displayName {
    switch (this) {
      case AppointmentType.consultation:
        return 'Consultation';
      case AppointmentType.followUp:
        return 'Follow-up';
      case AppointmentType.emergency:
        return 'Emergency';
      case AppointmentType.checkup:
        return 'Check-up';
    }
  }
}
