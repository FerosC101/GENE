// lib/presentation/screens/admin/hospital_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/data/models/hospital_model.dart';
import 'package:smart_hospital_app/presentation/providers/hospital_provider.dart';
import 'package:smart_hospital_app/presentation/screens/admin/widgets/hospital_form_dialog.dart';
import 'package:smart_hospital_app/services/model_3d_service.dart';
import 'package:file_picker/file_picker.dart';

class HospitalManagementScreen extends ConsumerWidget {
  const HospitalManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.watch(hospitalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showHospitalDialog(context, ref, null),
            tooltip: 'Add Hospital',
          ),
        ],
      ),
      body: hospitalsAsync.when(
        data: (hospitals) {
          if (hospitals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hospitals yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showHospitalDialog(context, ref, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Hospital'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final hospital = hospitals[index];
              return _HospitalCard(
                hospital: hospital,
                onEdit: () => _showHospitalDialog(context, ref, hospital),
                onDelete: () => _confirmDelete(context, ref, hospital),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(hospitalsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHospitalDialog(BuildContext context, WidgetRef ref, HospitalModel? hospital) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => HospitalFormDialog(hospital: hospital),
    );

    if (result != null && context.mounted) {
      await _saveHospitalWithModel(
        context,
        ref,
        result['hospitalData'] as Map<String, dynamic>,
        hospital?.id,
        result['model3DFile'] as PlatformFile?,
        result['floors'] as int,
        result['existingModelUrl'] as String?,
      );
    }
  }

  Future<void> _saveHospitalWithModel(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> hospitalData,
    String? existingId,
    PlatformFile? modelFile,
    int floors,
    String? existingModelUrl,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final hospitalController = ref.read(hospitalControllerProvider.notifier);
      
      if (existingId != null) {
        // UPDATE EXISTING HOSPITAL
        
        // Check if we need to upload a new 3D model
        if (modelFile != null) {
          final model3DService = Model3DService();

          // Delete old model if exists
          if (existingModelUrl != null) {
            try {
              await model3DService.deleteModel(existingModelUrl);
            } catch (e) {
              // ignore delete errors
            }
          }

          // Upload new model
          final modelUrl = await model3DService.uploadModel(
            platformFile: modelFile,
            hospitalId: existingId,
          );

          // Add metadata
          hospitalData['model3dUrl'] = modelUrl;
          hospitalData['modelMetadata'] = {
            'floors': floors,
            'modelSizeBytes': modelFile.size,
            'modelFormat': _getModelFormatFromName(modelFile.name),
            'uploadedAt': FieldValue.serverTimestamp(),
            'departments': _generateDepartmentList(hospitalData, floors),
          };
        }
        
        await hospitalController.updateHospital(existingId, hospitalData);
        
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hospital updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // ADD NEW HOSPITAL
        
        final hospitalId = await ref.read(hospitalRepositoryProvider).createHospital(hospitalData);

        // Upload 3D model if provided
        if (modelFile != null) {
          final model3DService = Model3DService();
          final modelUrl = await model3DService.uploadModel(
            platformFile: modelFile,
            hospitalId: hospitalId,
          );

          // Update hospital with 3D model data
          await hospitalController.updateHospital(hospitalId, {
            ...hospitalData,
            'model3dUrl': modelUrl,
            'modelMetadata': {
              'floors': floors,
              'modelSizeBytes': modelFile.size,
              'modelFormat': _getModelFormatFromName(modelFile.name),
              'uploadedAt': FieldValue.serverTimestamp(),
              'departments': _generateDepartmentList(hospitalData, floors),
            },
          });
        }
        
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hospital added successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _generateDepartmentList(Map<String, dynamic> hospitalData, int floors) {
    final departments = <Map<String, dynamic>>[];
    final status = hospitalData['status'] as Map<String, dynamic>;
    
    // ICU typically on higher floors
    if (status['icuTotal'] > 0) {
      departments.add({
        'name': 'Intensive Care Unit',
        'type': 'ICU',
        'floor': floors > 1 ? floors - 1 : 1,
        'bedCount': status['icuTotal'],
      });
    }
    
    // ER on ground floor
    if (status['erTotal'] > 0) {
      departments.add({
        'name': 'Emergency Room',
        'type': 'ER',
        'floor': 0,
        'bedCount': status['erTotal'],
      });
    }
    
    // Wards distributed across middle floors
    if (status['wardTotal'] > 0) {
      departments.add({
        'name': 'General Ward',
        'type': 'Ward',
        'floor': floors > 2 ? 1 : 0,
        'bedCount': status['wardTotal'],
      });
    }
    
    return departments;
  }

  String _getModelFormatFromName(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, HospitalModel hospital) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hospital'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${hospital.name}"?'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. All hospital data will be permanently deleted.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                // Delete 3D model if exists
                if (hospital.model3dUrl != null) {
                  final model3DService = Model3DService();
                  try {
                    await model3DService.deleteModel(hospital.model3dUrl!);
                  } catch (e) {
                    print('Error deleting 3D model: $e');
                  }
                }
                
                await ref.read(hospitalControllerProvider.notifier).deleteHospital(hospital.id);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hospital deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Hospital Card Widget
class _HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HospitalCard({
    required this.hospital,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            title: Text(
              hospital.name,
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
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hospital.address,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _InfoChip(
                      icon: Icons.bed,
                      label: '${hospital.status.totalBeds} beds',
                      color: AppColors.info,
                    ),
                    _InfoChip(
                      icon: Icons.show_chart,
                      label: '${(hospital.status.totalOccupied / hospital.status.totalBeds * 100).toInt()}% occupied',
                      color: AppColors.warning,
                    ),
                    if (hospital.has3dModel)
                      _InfoChip(
                        icon: Icons.view_in_ar,
                        label: '3D Model',
                        color: AppColors.success,
                      ),
                  ],
                ),
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
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ),
          
          // Department breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DepartmentStat(
                    label: 'ICU',
                    occupied: hospital.status.icuOccupied,
                    total: hospital.status.icuTotal,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DepartmentStat(
                    label: 'ER',
                    occupied: hospital.status.erOccupied,
                    total: hospital.status.erTotal,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DepartmentStat(
                    label: 'Ward',
                    occupied: hospital.status.wardOccupied,
                    total: hospital.status.wardTotal,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentStat extends StatelessWidget {
  final String label;
  final int occupied;
  final int total;
  final Color color;

  const _DepartmentStat({
    required this.label,
    required this.occupied,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (occupied / total * 100).toInt() : 0;
    
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$occupied/$total',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage / 100,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}