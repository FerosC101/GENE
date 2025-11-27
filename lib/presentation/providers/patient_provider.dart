// lib/presentation/providers/patient_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pulse/data/models/patient_model.dart';
import 'package:pulse/data/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider((ref) => PatientRepository());

// Patients stream for a hospital
final patientsStreamProvider = StreamProvider.family<List<PatientModel>, String>((ref, hospitalId) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatientsStream(hospitalId);
});

// Patients by department
final patientsByDepartmentProvider = StreamProvider.family<List<PatientModel>, Map<String, String>>((ref, params) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getPatientsByDepartment(params['hospitalId']!, params['department']!);
});

// Patient controller
class PatientController extends StateNotifier<AsyncValue<void>> {
  final PatientRepository _repository;

  PatientController(this._repository) : super(const AsyncValue.data(null));

  Future<void> admitPatient(Map<String, dynamic> patientData) async {
    state = const AsyncValue.loading();
    try {
      await _repository.admitPatient(patientData);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> dischargePatient(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.dischargePatient(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> transferPatient(String id, String department, String? bedNumber) async {
    state = const AsyncValue.loading();
    try {
      await _repository.transferPatient(id, department, bedNumber);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final patientControllerProvider = StateNotifierProvider<PatientController, AsyncValue<void>>((ref) {
  return PatientController(ref.watch(patientRepositoryProvider));
});