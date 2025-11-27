// lib/presentation/providers/hospital_provider.dart
// ignore_for_file: unnecessary_cast

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pulse/data/models/hospital_model.dart';
import 'package:pulse/data/repositories/hospital_repository.dart';
import 'package:pulse/presentation/providers/patient_provider.dart';

import '../../data/models/patient_model.dart';

// Repository provider
final hospitalRepositoryProvider = Provider((ref) => HospitalRepository());

// Hospitals stream provider
final hospitalsStreamProvider = StreamProvider<List<HospitalModel>>((ref) {
  final repository = ref.watch(hospitalRepositoryProvider);
  return repository.getHospitalsStream();
});

// Hospital CRUD controller
class HospitalController extends StateNotifier<AsyncValue<void>> {
  final HospitalRepository _repository;

  HospitalController(this._repository) : super(const AsyncValue.data(null));

  Future<void> createHospital(Map<String, dynamic> hospitalData) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createHospital(hospitalData);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateHospital(String id, Map<String, dynamic> hospitalData) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateHospital(id, hospitalData);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteHospital(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteHospital(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateBedStatus(String hospitalId, Map<String, dynamic> status) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBedStatus(hospitalId, status);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final hospitalControllerProvider =
    StateNotifierProvider<HospitalController, AsyncValue<void>>((ref) {
  return HospitalController(ref.watch(hospitalRepositoryProvider));
});

final hospitalStreamProvider = StreamProvider.family<HospitalModel?, String>((ref, hospitalId) {
  final repository = ref.watch(hospitalRepositoryProvider);
  return repository.getHospitalStream(hospitalId);
});

// Patients for a specific hospital (for Digital Twin stats)
final hospitalPatientsProvider = StreamProvider.family<List<PatientModel>, String>((ref, hospitalId) {
  return ref.watch(patientsStreamProvider(hospitalId)).when(
    data: (patients) => Stream<List<PatientModel>>.value(patients as List<PatientModel>),
    loading: () => Stream<List<PatientModel>>.value(<PatientModel>[]),
    error: (_, __) => Stream<List<PatientModel>>.value(<PatientModel>[]),
  ).first.asStream();
});