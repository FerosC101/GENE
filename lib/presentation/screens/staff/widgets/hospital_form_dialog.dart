// lib/presentation/screens/staff/widgets/hospital_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/core/constants/app_colors.dart';
import 'package:pulse/data/models/hospital_model.dart';
import 'package:pulse/presentation/providers/hospital_provider.dart';

class HospitalFormDialog extends ConsumerStatefulWidget {
  final HospitalModel? hospital;

  const HospitalFormDialog({super.key, this.hospital});

  @override
  ConsumerState<HospitalFormDialog> createState() => _HospitalFormDialogState();
}

class _HospitalFormDialogState extends ConsumerState<HospitalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  
  // Bed controllers
  late TextEditingController _icuTotalController;
  late TextEditingController _icuOccupiedController;
  late TextEditingController _erTotalController;
  late TextEditingController _erOccupiedController;
  late TextEditingController _wardTotalController;
  late TextEditingController _wardOccupiedController;
  late TextEditingController _waitTimeController;

  String _selectedType = 'public';
  List<String> _selectedServices = [];
  List<String> _selectedSpecialties = [];
  bool _isOperational = true;
  bool _isLoading = false;

  final List<String> _hospitalTypes = ['public', 'private', 'specialty'];
  final List<String> _availableServices = [
    'Emergency',
    'ICU',
    'Surgery',
    'Maternity',
    'Radiology',
    'Laboratory',
    'Pharmacy',
    'Cardiology',
    'Neurology',
    'Pediatrics',
  ];
  final List<String> _availableSpecialties = [
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Orthopedics',
    'General Medicine',
    'OB-GYN',
    'Psychiatry',
    'Dermatology',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hospital?.name ?? '');
    _addressController = TextEditingController(text: widget.hospital?.address ?? '');
    _latitudeController = TextEditingController(
      text: widget.hospital?.latitude.toString() ?? '14.2115'
    );
    _longitudeController = TextEditingController(
      text: widget.hospital?.longitude.toString() ?? '121.1654'
    );
    _phoneController = TextEditingController(text: widget.hospital?.phone ?? '');
    _emailController = TextEditingController(text: widget.hospital?.email ?? '');

    if (widget.hospital != null) {
      _selectedType = widget.hospital!.type;
      _selectedServices = List.from(widget.hospital!.services);
      _selectedSpecialties = List.from(widget.hospital!.specialties);
      _isOperational = widget.hospital!.status.isOperational;

      _icuTotalController = TextEditingController(
        text: widget.hospital!.status.icuTotal.toString()
      );
      _icuOccupiedController = TextEditingController(
        text: widget.hospital!.status.icuOccupied.toString()
      );
      _erTotalController = TextEditingController(
        text: widget.hospital!.status.erTotal.toString()
      );
      _erOccupiedController = TextEditingController(
        text: widget.hospital!.status.erOccupied.toString()
      );
      _wardTotalController = TextEditingController(
        text: widget.hospital!.status.wardTotal.toString()
      );
      _wardOccupiedController = TextEditingController(
        text: widget.hospital!.status.wardOccupied.toString()
      );
      _waitTimeController = TextEditingController(
        text: widget.hospital!.status.waitTimeMinutes.toString()
      );
    } else {
      _icuTotalController = TextEditingController(text: '20');
      _icuOccupiedController = TextEditingController(text: '0');
      _erTotalController = TextEditingController(text: '15');
      _erOccupiedController = TextEditingController(text: '0');
      _wardTotalController = TextEditingController(text: '50');
      _wardOccupiedController = TextEditingController(text: '0');
      _waitTimeController = TextEditingController(text: '15');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _icuTotalController.dispose();
    _icuOccupiedController.dispose();
    _erTotalController.dispose();
    _erOccupiedController.dispose();
    _wardTotalController.dispose();
    _wardOccupiedController.dispose();
    _waitTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveHospital() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final hospitalData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'type': _selectedType,
        'services': _selectedServices,
        'specialties': _selectedSpecialties,
        'imageUrl': '',
        'status': {
          'icuTotal': int.parse(_icuTotalController.text),
          'icuOccupied': int.parse(_icuOccupiedController.text),
          'erTotal': int.parse(_erTotalController.text),
          'erOccupied': int.parse(_erOccupiedController.text),
          'wardTotal': int.parse(_wardTotalController.text),
          'wardOccupied': int.parse(_wardOccupiedController.text),
          'waitTimeMinutes': int.parse(_waitTimeController.text),
          'isOperational': _isOperational,
        },
      };

      if (widget.hospital != null) {
        // Update existing
        await ref
            .read(hospitalControllerProvider.notifier)
            .updateHospital(widget.hospital!.id, hospitalData);
      } else {
        // Create new
        await ref
            .read(hospitalControllerProvider.notifier)
            .createHospital(hospitalData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.hospital != null
                  ? 'Hospital updated successfully'
                  : 'Hospital created successfully',
            ),
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                  const Icon(Icons.local_hospital, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.hospital != null ? 'Edit Hospital' : 'Add Hospital',
                    style: const TextStyle(
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

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Hospital Name',
                          prefixIcon: Icon(Icons.local_hospital),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter hospital name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                prefixIcon: Icon(Icons.my_location),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                prefixIcon: Icon(Icons.my_location),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Hospital Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _hospitalTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Services
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableServices.map((service) {
                          final isSelected = _selectedServices.contains(service);
                          return FilterChip(
                            label: Text(service),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedServices.add(service);
                                } else {
                                  _selectedServices.remove(service);
                                }
                              });
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Specialties
                      const Text(
                        'Specialties',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSpecialties.map((specialty) {
                          final isSelected = _selectedSpecialties.contains(specialty);
                          return FilterChip(
                            label: Text(specialty),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSpecialties.add(specialty);
                                } else {
                                  _selectedSpecialties.remove(specialty);
                                }
                              });
                            },
                            selectedColor: AppColors.success.withOpacity(0.2),
                            checkmarkColor: AppColors.success,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Bed Status
                      const Text(
                        'Bed Capacity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildBedRow('ICU', _icuTotalController, _icuOccupiedController),
                      const SizedBox(height: 12),
                      _buildBedRow('ER', _erTotalController, _erOccupiedController),
                      const SizedBox(height: 12),
                      _buildBedRow('Ward', _wardTotalController, _wardOccupiedController),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _waitTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Average Wait Time (minutes)',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter wait time';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Operational'),
                        subtitle: const Text('Is the hospital currently operational?'),
                        value: _isOperational,
                        onChanged: (value) {
                          setState(() => _isOperational = value);
                        },
                        activeThumbColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
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
                    onPressed: _isLoading ? null : _saveHospital,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.hospital != null ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedRow(
    String label,
    TextEditingController totalController,
    TextEditingController occupiedController,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: totalController,
            decoration: const InputDecoration(
              labelText: 'Total',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (int.tryParse(value) == null) return 'Invalid';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: occupiedController,
            decoration: const InputDecoration(
              labelText: 'Occupied',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final occupied = int.tryParse(value);
              final total = int.tryParse(totalController.text);
              if (occupied == null) return 'Invalid';
              if (total != null && occupied > total) return 'Too high';
              return null;
            },
          ),
        ),
      ],
    );
  }
}