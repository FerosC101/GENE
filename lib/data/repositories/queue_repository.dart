// lib/data/repositories/queue_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse/data/models/queue_model.dart';

class QueueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'queue';

  // Get queue for hospital
  Stream<List<QueueModel>> getQueueStream(String hospitalId) {
    return _firestore
        .collection(_collection)
        .where('hospitalId', isEqualTo: hospitalId)
        // Avoid server-side orderBy that may require a composite index.
        // We'll sort client-side so the query only uses a single-field equality.
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => QueueModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
          return list;
        });
  }

  // Add to queue
  Future<String> addToQueue(Map<String, dynamic> queueData) async {
    // Get next queue number
    int nextNumber = 1;
    try {
      // Try the efficient query first (may require composite index)
      final snapshot = await _firestore
          .collection(_collection)
          .where('hospitalId', isEqualTo: queueData['hospitalId'])
          .orderBy('queueNumber', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final lastQueue = snapshot.docs.first.data();
        final raw = lastQueue['queueNumber'];
        if (raw is int) {
          nextNumber = raw + 1;
        } else if (raw is String) {
          nextNumber = int.tryParse(raw) != null ? int.parse(raw) + 1 : 1;
        }
      }
    } catch (e) {
      // If the composite index is missing, fall back to an equality-only fetch
      // which doesn't require a composite index and compute the max locally.
      try {
        final fallbackSnap = await _firestore
            .collection(_collection)
            .where('hospitalId', isEqualTo: queueData['hospitalId'])
            .get();

        int maxNumber = 0;
        for (final d in fallbackSnap.docs) {
          final data = d.data();
          final raw = data['queueNumber'];
          int val = 0;
          if (raw is int) {
            val = raw;
          } else if (raw is String) val = int.tryParse(raw) ?? 0;
          if (val > maxNumber) maxNumber = val;
        }
        nextNumber = maxNumber + 1;
      } catch (e) {
        // Last-resort: keep nextNumber as 1
        nextNumber = 1;
      }
    }

    final docRef = await _firestore.collection(_collection).add({
      ...queueData,
      'queueNumber': nextNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  // Remove from queue
  Future<void> removeFromQueue(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Update queue priority
  Future<void> updatePriority(String id, String triageLevel) async {
    await _firestore.collection(_collection).doc(id).update({
      'triageLevel': triageLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}