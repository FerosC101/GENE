// lib/presentation/providers/queue_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pulse/data/models/queue_model.dart';
import 'package:pulse/data/repositories/queue_repository.dart';

final queueRepositoryProvider = Provider((ref) => QueueRepository());

final queueStreamProvider = StreamProvider.family<List<QueueModel>, String>((ref, hospitalId) {
  final repository = ref.watch(queueRepositoryProvider);
  return repository.getQueueStream(hospitalId);
});

class QueueController extends StateNotifier<AsyncValue<void>> {
  final QueueRepository _repository;

  QueueController(this._repository) : super(const AsyncValue.data(null));

  Future<void> addToQueue(Map<String, dynamic> queueData) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addToQueue(queueData);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> removeFromQueue(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeFromQueue(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updatePriority(String id, String triageLevel) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePriority(id, triageLevel);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final queueControllerProvider = StateNotifierProvider<QueueController, AsyncValue<void>>((ref) {
  return QueueController(ref.watch(queueRepositoryProvider));
});