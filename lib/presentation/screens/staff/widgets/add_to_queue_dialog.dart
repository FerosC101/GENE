// lib/presentation/screens/staff/widgets/add_to_queue_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/core/constants/app_colors.dart';
import 'package:smart_hospital_app/data/models/patient_model.dart';
import 'package:smart_hospital_app/presentation/providers/queue_provider.dart';

class AddToQueueDialog extends ConsumerStatefulWidget {
  final String hospitalId;

  const AddToQueueDialog({super.key, required this.hospitalId});

  @override
  ConsumerState<AddToQueueDialog> createState() => _AddToQueueDialogState();
}

class _AddToQueueDialogState extends ConsumerState<AddToQueueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedDepartment = 'Emergency';
  TriageLevel _selectedTriage = TriageLevel.semiUrgent;
  bool _isLoading = false;

  final List<String> _departments = ['ICU', 'Emergency', 'General Ward', 'Pediatrics', 'Neurology'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _addToQueue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final queueData = {
        'patientName': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'condition': _conditionController.text.trim(),
        'department': _selectedDepartment,
        'triageLevel': _selectedTriage.name,
        'hospitalId': widget.hospitalId,
        'arrivalTime': DateTime.now().toIso8601String(),
      };

      await ref.read(queueControllerProvider.notifier).addToQueue(queueData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to queue successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.queue, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Add to Queue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter patient name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                prefixIcon: Icon(Icons.cake),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: Icon(Icons.wc),
                              ),
                              items: ['Male', 'Female', 'Other'].map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedGender = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _conditionController,
                        decoration: const InputDecoration(
                          labelText: 'Condition/Complaint',
                          prefixIcon: Icon(Icons.medical_information),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter condition';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.apartment),
                        ),
                        items: _departments.map((dept) {
                          return DropdownMenuItem(value: dept, child: Text(dept));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDepartment = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Triage Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...TriageLevel.values.map((level) {
                        final color = level == TriageLevel.critical
                            ? AppColors.error
                            : level == TriageLevel.urgent
                                ? Colors.orange
                                : level == TriageLevel.semiUrgent
                                    ? Colors.amber
                                    : AppColors.success;

                        return RadioListTile<TriageLevel>(
                          title: Text(level.displayName),
                          value: level,
                          groupValue: _selectedTriage,
                          activeColor: color,
                          onChanged: (value) {
                            setState(() => _selectedTriage = value!);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addToQueue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add to Queue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}