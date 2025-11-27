// lib/presentation/screens/staff/doctor_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/presentation/providers/hospital_provider.dart';
import 'package:pulse/data/repositories/doctor_repository.dart';
import 'package:pulse/presentation/screens/staff/widgets/doctor_form_dialog.dart';

final doctorRepositoryProvider = Provider((ref) => DoctorRepository());

final doctorsStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, hospitalId) {
  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getDoctorsStream(hospitalId);
});

class DoctorManagementScreen extends ConsumerStatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  ConsumerState<DoctorManagementScreen> createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends ConsumerState<DoctorManagementScreen> {
  String? _selectedHospitalId;

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Management'),
      ),
      floatingActionButton: _selectedHospitalId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DoctorFormDialog(
                    hospitalId: _selectedHospitalId!,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Doctor'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          // Hospital Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: hospitalsAsync.when(
              data: (hospitals) {
                if (hospitals.isEmpty) {
                  return const Text('No hospitals available');
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedHospitalId,
                  decoration: const InputDecoration(
                    labelText: 'Select Hospital',
                    prefixIcon: Icon(Icons.local_hospital),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: hospitals.map((hospital) {
                    return DropdownMenuItem(
                      value: hospital.id,
                      child: Text(hospital.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedHospitalId = value);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ),

          // Doctors List
          Expanded(
            child: _selectedHospitalId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a hospital to view doctors',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (context, ref, child) {
                      final doctorsAsync = ref.watch(
                        doctorsStreamProvider(_selectedHospitalId!),
                      );

                      return doctorsAsync.when(
                        data: (snapshot) {
                          if (snapshot.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 80,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No doctors yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the + button to add a doctor',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: snapshot.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      data['name']?.substring(0, 1).toUpperCase() ?? 'D',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    data['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.medical_services,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(data['specialty'] ?? 'General'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.phone,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(data['phone'] ?? 'No phone'),
                                        ],
                                      ),
                                      if (data['available'] != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: data['available']
                                                ? AppColors.success.withOpacity(0.1)
                                                : AppColors.error.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            data['available'] ? 'Available' : 'Not Available',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: data['available']
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: AppColors.error),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => DoctorFormDialog(
                                            hospitalId: _selectedHospitalId!,
                                            doctorId: doc.id,
                                            doctorData: data,
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Doctor'),
                                            content: Text(
                                              'Are you sure you want to delete ${data['name']}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: AppColors.error,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true && context.mounted) {
                                          try {
                                            await ref
                                                .read(doctorRepositoryProvider)
                                                .deleteDoctor(doc.id);
                                            
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Doctor deleted successfully'),
                                                  backgroundColor: AppColors.success,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: AppColors.error,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(child: Text('Error: $error')),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}