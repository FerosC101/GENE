// lib/presentation/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/data/models/user_model.dart';
import 'package:smart_hospital_app/data/repositories/user_repository.dart';

// Repository provider
final userRepositoryProvider = Provider((ref) => UserRepository());

// Doctors by hospital stream
final doctorsByHospitalProvider = StreamProvider.family<List<UserModel>, String>((ref, hospitalId) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getDoctorsByHospital(hospitalId);
});
