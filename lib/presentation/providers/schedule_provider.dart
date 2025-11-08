// lib/presentation/providers/schedule_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smart_hospital_app/data/models/doctor_schedule_model.dart';
import 'package:smart_hospital_app/data/repositories/schedule_repository.dart';

// Repository provider
final scheduleRepositoryProvider = Provider((ref) => ScheduleRepository());

// Doctor's schedule stream
final doctorScheduleProvider = StreamProvider.family<List<DoctorScheduleModel>, String>((ref, doctorId) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getDoctorSchedule(doctorId);
});

// Schedule controller
class ScheduleController extends StateNotifier<AsyncValue<void>> {
  final ScheduleRepository _repository;

  ScheduleController(this._repository) : super(const AsyncValue.data(null));

  Future<String> createSchedule(DoctorScheduleModel schedule) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repository.createSchedule(schedule);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSchedule(id, data);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSchedule(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> createDefaultSchedule({
    required String doctorId,
    required String hospitalId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createDefaultSchedule(
        doctorId: doctorId,
        hospitalId: hospitalId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final scheduleControllerProvider =
    StateNotifierProvider<ScheduleController, AsyncValue<void>>((ref) {
  return ScheduleController(ref.watch(scheduleRepositoryProvider));
});