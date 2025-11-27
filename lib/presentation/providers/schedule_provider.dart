// lib/presentation/providers/schedule_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/data/models/doctor_schedule_model.dart';
import 'package:pulse/data/repositories/schedule_repository.dart';

// Repository provider
final scheduleRepositoryProvider = Provider((ref) => ScheduleRepository());

// Doctor's schedule stream
final doctorScheduleProvider = StreamProvider.family<List<DoctorScheduleModel>, String>((ref, doctorId) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.getDoctorSchedule(doctorId);
});

// Schedule controller using modern Riverpod Notifier API
class ScheduleController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String> createSchedule(DoctorScheduleModel schedule) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(scheduleRepositoryProvider);
      final id = await repository.createSchedule(schedule);
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
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.updateSchedule(id, data);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.deleteSchedule(id);
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
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.createDefaultSchedule(
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

final scheduleControllerProvider = NotifierProvider<ScheduleController, AsyncValue<void>>(() {
  return ScheduleController();
});