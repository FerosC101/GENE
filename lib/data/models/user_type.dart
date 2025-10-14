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

  /// Parse a [String] coming from storage (Firestore, API) into a [UserType].
  ///
  /// This is tolerant of common formats such as:
  /// - enum name: "hospitalStaff"
  /// - snake/case/space variants: "hospital_staff", "Hospital Staff"
  /// - short forms like "staff"
  static UserType fromString(String? value) {
    if (value == null) return UserType.patient;

    final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

    for (final t in UserType.values) {
      final nameNorm = t.name.toLowerCase();
      final displayNorm = t.displayName.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

      if (normalized == nameNorm || normalized == displayNorm) return t;
    }

    // Accept shorter synonyms
    if (normalized.contains('staff')) return UserType.hospitalStaff;
    if (normalized.contains('doctor')) return UserType.doctor;

    // Fallback to patient
    return UserType.patient;
  }
}