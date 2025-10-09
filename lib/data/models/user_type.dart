enum UserType {
  patient,
  doctor,
  hospitalStaff;

  String get displayName {
    switch (this) {
      case UserType.patient:
        return 'Patient';
      case UserType.doctor:
        return 'Doctor';
      case UserType.hospitalStaff:
        return 'Hospital Staff';
    }
  }

  String get description {
    switch (this) {
      case UserType.patient:
        return 'Find hospitals, book appointments, and access healthcare services';
      case UserType.doctor:
        return 'Manage schedules, view patients, and collaborate with hospitals';
      case UserType.hospitalStaff:
        return 'Manage hospital operations, bed capacity, and resources';
    }
  }

  String get icon {
    switch (this) {
      case UserType.patient:
        return '👤';
      case UserType.doctor:
        return '👨‍⚕️';
      case UserType.hospitalStaff:
        return '🏥';
    }
  }
}