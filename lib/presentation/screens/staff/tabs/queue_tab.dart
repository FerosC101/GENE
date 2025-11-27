// lib/presentation/screens/staff/tabs/queue_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/patient_model.dart';
import 'package:pulse/presentation/providers/queue_provider.dart';
import 'package:pulse/presentation/screens/staff/widgets/queue_item_card.dart';
import 'package:pulse/presentation/screens/staff/widgets/add_to_queue_dialog.dart';

class QueueTab extends ConsumerWidget {
  final String hospitalId;

  const QueueTab({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueStreamProvider(hospitalId));

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Patient Queue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                queueAsync.when(
                  data: (queue) => Text(
                    '${queue.length} waiting',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  loading: () => const Text('...'),
                  error: (_, __) => const Text(''),
                ),
              ],
            ),
          ),

          // Queue List
          Expanded(
            child: queueAsync.when(
              data: (queue) {
                if (queue.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No patients in queue',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort by triage level
                final sortedQueue = List.from(queue);
                sortedQueue.sort((a, b) {
                  final priorityOrder = {
                    TriageLevel.critical: 0,
                    TriageLevel.urgent: 1,
                    TriageLevel.semiUrgent: 2,
                    TriageLevel.nonUrgent: 3,
                  };
                  return (priorityOrder[a.triageLevel] ?? 99)
                      .compareTo(priorityOrder[b.triageLevel] ?? 99);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedQueue.length,
                  itemBuilder: (context, index) {
                    return QueueItemCard(
                      queueItem: sortedQueue[index],
                      position: index + 1,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddToQueueDialog(hospitalId: hospitalId),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add to Queue'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}