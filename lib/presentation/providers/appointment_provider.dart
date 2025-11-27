// lib/presentation/providers/appointment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/data/models/appointment_model.dart';
import 'package:pulse/data/models/appointment_status.dart' show AppointmentStatus;
import 'package:pulse/data/repositories/appointment_repository.dart';

// Repository provider
final appointmentRepositoryProvider = Provider((ref) => AppointmentRepository());

// Doctor's appointments stream
final doctorAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, doctorId) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getDoctorAppointments(doctorId);
});

// Today's appointments for doctor
final todayDoctorAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, doctorId) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getTodayDoctorAppointments(doctorId);
});

// Upcoming appointments for doctor
final upcomingDoctorAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, doctorId) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getUpcomingDoctorAppointments(doctorId);
});

// Patient's appointments stream
final patientAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, patientId) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getPatientAppointments(patientId);
});

// Appointment controller using modern Riverpod Notifier API
class AppointmentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String> createAppointment(AppointmentModel appointment) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final id = await repository.createAppointment(appointment);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.updateAppointment(id, data);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, AppointmentStatus status) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.updateAppointmentStatus(id, status);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.deleteAppointment(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<bool> checkTimeSlotAvailability({
    required String doctorId,
    required DateTime dateTime,
    String? excludeAppointmentId,
  }) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      return await repository.isTimeSlotAvailable(
        doctorId: doctorId,
        dateTime: dateTime,
        excludeAppointmentId: excludeAppointmentId,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final appointmentControllerProvider = NotifierProvider<AppointmentController, AsyncValue<void>>(() {
  return AppointmentController();
});